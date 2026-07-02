#!/usr/bin/env python3
"""Apply the Large Address Aware (LAA) flag to a 32-bit PE executable.

WHAT THIS DOES
--------------
A 32-bit Windows process is limited to 2 GB of virtual address space unless the
`IMAGE_FILE_LARGE_ADDRESS_AWARE` flag is set in its PE header, in which case it
can address up to 4 GB (on 64-bit Windows; 3 GB on 32-bit Windows with /3GB).

Dead State's `ZRPG.exe` ships WITHOUT this flag. With the 4K UI mod's larger
fonts and higher-resolution textures, the process can exceed 2 GB and crash.
Setting LAA lets it use the full 4 GB.

THE PATCH (2 fields in the PE header)
-------------------------------------
1. Characteristics (2-byte field in IMAGE_FILE_HEADER): OR in bit 0x20
   (IMAGE_FILE_LARGE_ADDRESS_AWARE). Other bits are preserved.
2. CheckSum (4-byte field in the Optional Header): recomputed to match the
   patched file. (The loader ignores the checksum for normal exes, but a correct
   checksum is what the reference patch produces, so we match it for an exact,
   reproducible result.)

Both field offsets are derived from `e_lfanew` (the PE header offset stored at
file offset 0x3C in the DOS header), so this works on any PE regardless of where
its header lives. No hardcoded magic offsets.

The checksum is computed with the Windows `imagehlp.CheckSumMappedFile` API --
the same algorithm the OS loader uses -- so the output is byte-for-byte identical
to patching with NTCore's 4GB patcher or `editbin /LARGEADDRESSAWARE`.

USAGE
-----
    python patch_laa.py "C:\\Path\\To\\ZRPG.exe"
    python patch_laa.py ZRPG.exe --verify   # report flag state without patching
    python patch_laa.py ZRPG.exe --backup   # write ZRPG.exe.bak first

Idempotent: running it on an already-patched file is a no-op.
"""
import argparse
import ctypes
import os
import shutil
import struct
import sys
from ctypes import wintypes

IMAGE_FILE_LARGE_ADDRESS_AWARE = 0x0020
E_LFANEW_OFFSET = 0x3C              # DOS header field: offset to PE signature
PE_SIG_SIZE = 4                     # "PE\0\0"
FILE_HEADER_SIZE = 20               # IMAGE_FILE_HEADER
CHARACTERISTICS_OFFSET_IN_FILE_HEADER = 0x12   # 18: Characteristics (2 bytes)
CHECKSUM_OFFSET_IN_OPT_HEADER = 0x40           # 64: CheckSum (4 bytes)


def read_e_lfanew(data):
    if len(data) < E_LFANEW_OFFSET + 4:
        raise ValueError("File too small to contain a DOS header e_lfanew field.")
    e_lfanew = struct.unpack_from("<I", data, E_LFANEW_OFFSET)[0]
    if e_lfanew + PE_SIG_SIZE + 4 > len(data):
        raise ValueError(f"e_lfanew (0x{e_lfanew:X}) points past end of file.")
    sig = data[e_lfanew:e_lfanew + PE_SIG_SIZE]
    if sig != b"PE\x00\x00":
        raise ValueError(f"Not a PE file: expected 'PE\\0\\0' at 0x{e_lfanew:X}, got {sig!r}.")
    return e_lfanew


def field_offsets(e_lfanew):
    """Return (characteristics_offset, checksum_offset), both file-absolute."""
    file_header = e_lfanew + PE_SIG_SIZE
    optional_header = file_header + FILE_HEADER_SIZE
    characteristics = file_header + CHARACTERISTICS_OFFSET_IN_FILE_HEADER
    checksum = optional_header + CHECKSUM_OFFSET_IN_OPT_HEADER
    return characteristics, checksum


def compute_pe_checksum(data, checksum_offset):
    """Compute the PE checksum via Windows imagehlp (the loader's algorithm).

    The CheckSum field is treated as 0 during the computation, so we pass the
    buffer unchanged -- the API reads the on-disk value but the algorithm's
    self-subtraction cancels it out. Falls back to a pure-Python implementation
    if imagehlp is unavailable (non-Windows / stripped systems).
    """
    try:
        imagehlp = ctypes.WinDLL("imagehlp")
        imagehlp.CheckSumMappedFile.restype = wintypes.LPVOID
        imagehlp.CheckSumMappedFile.argtypes = [
            wintypes.LPVOID, wintypes.DWORD,
            ctypes.POINTER(wintypes.DWORD), ctypes.POINTER(wintypes.DWORD),
        ]
        buf = ctypes.create_string_buffer(bytes(data), len(data))
        hdr = wintypes.DWORD(); chk = wintypes.DWORD()
        ret = imagehlp.CheckSumMappedFile(buf, len(data), ctypes.byref(hdr), ctypes.byref(chk))
        if not ret:
            raise OSError("CheckSumMappedFile returned NULL")
        return chk.value
    except (OSError, AttributeError):
        return _compute_pe_checksum_python(data, checksum_offset)


def _compute_pe_checksum_python(data, checksum_offset):
    """Pure-Python PE checksum (the 16-bit additive + carry-fold algorithm used
    by the Windows loader). Sufficient as a fallback; matches imagehlp on PE32."""
    # Zero the CheckSum field in a working copy, then sum 16-bit words.
    work = bytearray(data)
    struct.pack_into("<I", work, checksum_offset, 0)
    length = len(work)
    # Sum as 16-bit words.
    s = 0
    # Process complete 16-bit words.
    words = length // 2
    for i in range(words):
        s += work[2 * i] | (work[2 * i + 1] << 8)
        s = (s & 0xFFFF) + (s >> 16)
    # Trailing odd byte.
    if length & 1:
        s += work[2 * words]
        s = (s & 0xFFFF) + (s >> 16)
    s = (s & 0xFFFF) + (s >> 16)
    s &= 0xFFFF
    return s + length


def check_laa(data):
    """Return (is_laa_set, characteristics_value)."""
    e_lfanew = read_e_lfanew(data)
    chars_off, _ = field_offsets(e_lfanew)
    chars = struct.unpack_from("<H", data, chars_off)[0]
    return bool(chars & IMAGE_FILE_LARGE_ADDRESS_AWARE), chars


def main():
    ap = argparse.ArgumentParser(description="Apply the Large Address Aware flag to a PE exe.")
    ap.add_argument("exe", help="Path to the executable to patch (e.g. ZRPG.exe).")
    ap.add_argument("--verify", action="store_true",
                    help="Only report the current flag state; do not modify the file.")
    ap.add_argument("--backup", action="store_true",
                    help="Write <exe>.bak before patching (skipped if it already exists).")
    args = ap.parse_args()

    if not os.path.isfile(args.exe):
        sys.exit(f"ERROR: file not found: {args.exe}")

    with open(args.exe, "rb") as f:
        data = bytearray(f.read())

    try:
        already_set, chars = check_laa(data)
        e_lfanew = read_e_lfanew(data)
        chars_off, checksum_off = field_offsets(e_lfanew)
    except ValueError as e:
        sys.exit(f"ERROR: {e}")

    stored_checksum = struct.unpack_from("<I", data, checksum_off)[0]
    print(f"File:              {args.exe}")
    print(f"e_lfanew:          0x{e_lfanew:X}")
    print(f"Characteristics:   0x{chars:04X} at offset 0x{chars_off:X}")
    print(f"  LAA flag (0x20): {'SET' if already_set else 'NOT SET'}")
    print(f"CheckSum:          0x{stored_checksum:08X} at offset 0x{checksum_off:X}")

    if args.verify:
        sys.exit(0 if already_set else 1)

    # Compute the new checksum up front (before we mutate `data`).
    new_chars = chars | IMAGE_FILE_LARGE_ADDRESS_AWARE

    # Idempotency: LAA already set AND checksum already correct -> nothing to do.
    new_checksum = compute_pe_checksum(bytes(data), checksum_off)
    # Recompute against the would-be patched buffer so the checksum reflects the
    # new Characteristics value. Temporarily apply the bit flip for the calc.
    probe = bytearray(data)
    struct.pack_into("<H", probe, chars_off, new_chars)
    new_checksum = compute_pe_checksum(bytes(probe), checksum_off)

    if already_set and stored_checksum == new_checksum:
        print("\nAlready patched (LAA set, checksum current). Nothing to do.")
        return

    if args.backup:
        bak = args.exe + ".bak"
        if not os.path.exists(bak):
            shutil.copy2(args.exe, bak)
            print(f"\nBackup written: {bak}")
        else:
            print(f"\nBackup exists, left unchanged: {bak}")

    # 1. Set the LAA bit (preserve all other characteristic bits).
    struct.pack_into("<H", data, chars_off, new_chars)
    # 2. Recompute the checksum so it matches the patched file.
    struct.pack_into("<I", data, checksum_off, new_checksum)

    with open(args.exe, "wb") as f:
        f.write(data)

    print(f"\nPatched: Characteristics 0x{chars:04X} -> 0x{new_chars:04X}, "
          f"CheckSum 0x{stored_checksum:08X} -> 0x{new_checksum:08X}.")
    print("The process can now address up to 4 GB of virtual memory on 64-bit Windows.")


if __name__ == "__main__":
    main()

/*
 * d3d9 proxy DLL for Dead State — CPU-core crash fix.
 * See header comments in prior version. This variant names the exported
 * functions EXACTLY as the game imports them, so tcc emits correct names.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define CORE_AFFINITY_MASK 0xF   /* bits 0-3 = first 4 logical CPUs */

typedef void* IDirect3D9;
static HMODULE g_realD3D9 = NULL;

static HMODULE getRealD3D9(void)
{
    if (!g_realD3D9) {
        g_realD3D9 = LoadLibraryA("C:\\Windows\\System32\\d3d9.dll");
    }
    return g_realD3D9;
}

/* __declspec(dllexport) makes tcc emit the export with this exact name.
 * We use the canonical d3d9 API names so the game's import table resolves. */
__declspec(dllexport) IDirect3D9 __stdcall Direct3DCreate9(unsigned int SDKVersion)
{
    typedef IDirect3D9 (__stdcall *PFN)(unsigned int);
    HMODULE m = getRealD3D9();
    if (!m) return NULL;
    PFN pfn = (PFN)GetProcAddress(m, "Direct3DCreate9");
    if (!pfn) return NULL;
    return pfn(SDKVersion);
}

__declspec(dllexport) int __stdcall D3DPERF_BeginEvent(unsigned int col, const wchar_t *wszName)
{
    (void)col; (void)wszName;
    return 0;
}

__declspec(dllexport) int __stdcall D3DPERF_EndEvent(void)
{
    return 0;
}

__declspec(dllexport) void __stdcall D3DPERF_SetMarker(unsigned int col, const wchar_t *wszName)
{
    (void)col; (void)wszName;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    if (fdwReason == DLL_PROCESS_ATTACH) {
        SetProcessAffinityMask(GetCurrentProcess(), CORE_AFFINITY_MASK);
    }
    else if (fdwReason == DLL_PROCESS_DETACH) {
        if (g_realD3D9) { FreeLibrary(g_realD3D9); g_realD3D9 = NULL; }
    }
    return TRUE;
}

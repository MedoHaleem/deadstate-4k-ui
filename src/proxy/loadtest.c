#include <windows.h>
#include <stdio.h>
int main(){
    HMODULE h = LoadLibraryA("d3d9.dll");
    if(!h){ printf("LOAD FAILED, err=%lu\n", GetLastError()); return 1; }
    printf("LOADED d3d9.dll handle=%p\n", h);
    void* p = GetProcAddress(h, "Direct3DCreate9");
    printf("Direct3DCreate9 -> %p\n", p);
    // After load, DllMain should have run -> process affinity should be 0xF
    DWORD_PTR proc, sys;
    GetProcessAffinityMask(GetCurrentProcess(), &proc, &sys);
    printf("ProcessAffinityMask = 0x%llX (expect 0xF)\n", (unsigned long long)proc);
    FreeLibrary(h);
    return 0;
}

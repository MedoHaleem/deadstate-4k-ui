/*
 * d3d9 proxy DLL for Dead State — affinity fix + always-on borderless windowed.
 *
 * DllMain: SetProcessAffinityMask(0xF) so the engine's >4-core crash never fires.
 * Direct3DCreate9: forward to real System32 d3d9, then vtable-hook CreateDevice
 *   (slot 16) and device Reset (slot 16) to force Windowed=TRUE + rr=0 while
 *   leaving the engine's requested backbuffer (3840x2160). Keeps mode string
 *   "... true ..." so the engine never hits its windowed->=desktop guard.
 * Watcher + makeBorderless: restyle TorqueJuggernaughtWindow to WS_POPUP at
 *   primary-monitor bounds (engine leaves the window tiny when Windowed is
 *   forced under the exclusive-FS path).
 *
 * Exports (undecorated after undecorate_exports.ps1): Direct3DCreate9,
 * D3DPERF_BeginEvent, D3DPERF_EndEvent, D3DPERF_SetMarker.
 * See context.md "CPU Core Count Crash" + "Borderless Fullscreen Windowed".
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define CORE_AFFINITY_MASK 0xF

#ifndef SWP_FRAMECHANGE
#define SWP_FRAMECHANGE 0x0020
#endif

typedef enum { D3DDEVTYPE_HAL = 1 } D3DDEVTYPE;
typedef unsigned int D3DFORMAT;
typedef unsigned int D3DMULTISAMPLE_TYPE;
typedef unsigned int D3DSWAPEFFECT;
typedef long HRESULT;
#ifndef SUCCEEDED
#define SUCCEEDED(hr) (((HRESULT)(hr)) >= 0)
#endif

typedef struct {
    UINT                BackBufferWidth;
    UINT                BackBufferHeight;
    D3DFORMAT           BackBufferFormat;
    UINT                BackBufferCount;
    D3DMULTISAMPLE_TYPE MultiSampleType;
    DWORD               MultiSampleQuality;
    D3DSWAPEFFECT       SwapEffect;
    HWND                hDeviceWindow;
    BOOL                Windowed;
    BOOL                EnableAutoDepthStencil;
    D3DFORMAT           AutoDepthStencilFormat;
    DWORD               Flags;
    UINT                FullScreen_RefreshRateInHz;
    UINT                PresentationInterval;
} D3DPRESENT_PARAMETERS;

typedef void* IDirect3D9;
static HMODULE g_realD3D9 = NULL;
static HWND g_gameHwnd = NULL;

static HMODULE getRealD3D9(void)
{
    if (!g_realD3D9) {
        g_realD3D9 = LoadLibraryA("C:\\Windows\\System32\\d3d9.dll");
    }
    return g_realD3D9;
}

static BOOL makeBorderless(HWND hwnd)
{
    if (!hwnd || !IsWindow(hwnd)) return FALSE;
    LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
    LONG_PTR exStyle = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    style  &= ~(WS_OVERLAPPEDWINDOW | WS_CAPTION | WS_THICKFRAME | WS_DLGFRAME
                | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
    style  |=  (WS_POPUP | WS_VISIBLE);
    exStyle &= ~(WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE | WS_EX_DLGMODALFRAME);
    SetWindowLongPtrW(hwnd, GWL_STYLE, style);
    SetWindowLongPtrW(hwnd, GWL_EXSTYLE, exStyle);
    return SetWindowPos(hwnd, HWND_TOP, 0, 0,
                        GetSystemMetrics(SM_CXSCREEN),
                        GetSystemMetrics(SM_CYSCREEN),
                        SWP_FRAMECHANGE | SWP_SHOWWINDOW | SWP_NOOWNERZORDER);
}

static void noteGameHwnd(HWND hwnd)
{
    if (!hwnd || !IsWindow(hwnd)) return;
    g_gameHwnd = hwnd;
    makeBorderless(hwnd);
}

static void forceWindowedPP(D3DPRESENT_PARAMETERS *pp)
{
    if (!pp) return;
    pp->Windowed = TRUE;
    pp->FullScreen_RefreshRateInHz = 0;
    if (pp->hDeviceWindow) noteGameHwnd(pp->hDeviceWindow);
}

typedef HRESULT (__stdcall *CreateDevice_fn)(
    void *thisc, UINT Adapter, D3DDEVTYPE DeviceType, HWND hFocusWindow,
    DWORD BehaviorFlags, D3DPRESENT_PARAMETERS *pp, void **ppDevice);

typedef HRESULT (__stdcall *Reset_fn)(
    void *thisc, D3DPRESENT_PARAMETERS *pp);

static CreateDevice_fn g_origCreateDevice = NULL;
static Reset_fn        g_origReset = NULL;
static int             g_d3d9Hooked = 0;
static int             g_devHooked  = 0;

static int patchVtableSlot(void **vtbl, int index, void *hook, void **outOrig)
{
    DWORD oldProt = 0;
    if (!VirtualProtect(&vtbl[index], sizeof(void*), PAGE_READWRITE, &oldProt))
        return 0;
    if (outOrig && !*outOrig) *outOrig = vtbl[index];
    vtbl[index] = hook;
    VirtualProtect(&vtbl[index], sizeof(void*), oldProt, &oldProt);
    return 1;
}

static HRESULT __stdcall hook_Reset(void *thisc, D3DPRESENT_PARAMETERS *pp)
{
    forceWindowedPP(pp);
    HRESULT hr = g_origReset(thisc, pp);
    if (SUCCEEDED(hr) && pp && pp->hDeviceWindow)
        noteGameHwnd(pp->hDeviceWindow);
    else if (SUCCEEDED(hr) && g_gameHwnd)
        noteGameHwnd(g_gameHwnd);
    return hr;
}

static void hookDevice(void *device)
{
    if (!device || g_devHooked) return;
    void **vtbl = *(void***)device;
    if (!patchVtableSlot(vtbl, 16, (void*)hook_Reset, (void**)&g_origReset))
        return;
    g_devHooked = 1;
}

static HRESULT __stdcall hook_CreateDevice(
    void *thisc, UINT Adapter, D3DDEVTYPE DeviceType, HWND hFocusWindow,
    DWORD BehaviorFlags, D3DPRESENT_PARAMETERS *pp, void **ppDevice)
{
    if (hFocusWindow) noteGameHwnd(hFocusWindow);
    forceWindowedPP(pp);
    HRESULT hr = g_origCreateDevice(thisc, Adapter, DeviceType, hFocusWindow,
                                    BehaviorFlags, pp, ppDevice);
    if (SUCCEEDED(hr) && ppDevice && *ppDevice) {
        hookDevice(*ppDevice);
        if (pp && pp->hDeviceWindow) noteGameHwnd(pp->hDeviceWindow);
        else if (hFocusWindow) noteGameHwnd(hFocusWindow);
    }
    return hr;
}

static void hookIDirect3D9(void *d3d9)
{
    if (!d3d9 || g_d3d9Hooked) return;
    void **vtbl = *(void***)d3d9;
    if (!patchVtableSlot(vtbl, 16, (void*)hook_CreateDevice,
                         (void**)&g_origCreateDevice))
        return;
    g_d3d9Hooked = 1;
}

typedef struct { DWORD pid; } WatcherCtx;
static BOOL g_found = FALSE;
static HWND  g_foundHwnd = NULL;

static BOOL CALLBACK enumFindGameWnd(HWND hwnd, LPARAM lparam)
{
    DWORD pid = 0;
    WatcherCtx *ctx = (WatcherCtx *)lparam;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid != ctx->pid) return TRUE;
    if (GetWindow(hwnd, GW_OWNER) != NULL) return TRUE;
    wchar_t cls[64];
    GetClassNameW(hwnd, cls, 64);
    if (lstrcmpW(cls, L"TorqueJuggernaughtWindow") != 0) return TRUE;
    g_foundHwnd = hwnd;
    g_found = TRUE;
    return FALSE;
}

static DWORD WINAPI borderlessWatcherThread(LPVOID lpParam)
{
    (void)lpParam;
    WatcherCtx ctx;
    ctx.pid = GetCurrentProcessId();

    HWND hwnd = NULL;
    for (int i = 0; i < 1200; i++) {
        if (g_gameHwnd && IsWindow(g_gameHwnd)) {
            hwnd = g_gameHwnd;
            break;
        }
        g_found = FALSE;
        g_foundHwnd = NULL;
        EnumWindows(enumFindGameWnd, (LPARAM)&ctx);
        if (g_found) { hwnd = g_foundHwnd; break; }
        Sleep(50);
    }
    if (!hwnd) return 0;

    makeBorderless(hwnd);
    for (int k = 0; k < 12; k++) {
        Sleep(500);
        if (!IsWindow(hwnd)) return 0;
        makeBorderless(hwnd);
    }
    return 0;
}

__declspec(dllexport) IDirect3D9 __stdcall Direct3DCreate9(unsigned int SDKVersion)
{
    typedef IDirect3D9 (__stdcall *PFN)(unsigned int);
    HMODULE m = getRealD3D9();
    if (!m) return NULL;
    PFN pfn = (PFN)GetProcAddress(m, "Direct3DCreate9");
    if (!pfn) return NULL;
    IDirect3D9 d3d = pfn(SDKVersion);
    if (d3d) hookIDirect3D9(d3d);
    return d3d;
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
    (void)lpvReserved;
    if (fdwReason == DLL_PROCESS_ATTACH) {
        SetProcessAffinityMask(GetCurrentProcess(), CORE_AFFINITY_MASK);
        DisableThreadLibraryCalls(hinstDLL);
        HANDLE h = CreateThread(NULL, 0, borderlessWatcherThread, NULL, 0, NULL);
        if (h) CloseHandle(h);
    }
    else if (fdwReason == DLL_PROCESS_DETACH) {
        if (g_realD3D9) { FreeLibrary(g_realD3D9); g_realD3D9 = NULL; }
    }
    return TRUE;
}

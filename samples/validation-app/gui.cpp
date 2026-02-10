#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <process.h>
#include <errno.h>
#include <string.h>
#include "core.h"

#define IDC_EDIT 101
#define IDC_BTN  102

char g_message[1024] = "Hello World (GUI Default)";
char g_output[1024] = "C:/validation_gui_output.txt";
int g_timeout_secs = 0;
HWND g_hwnd = NULL;

void Log(const char* msg) {
    printf("%s\n", msg);
    fflush(stdout);
}

void LogFmt(const char* fmt, const char* arg) {
    printf(fmt, arg);
    printf("\n");
    fflush(stdout);
}

void ParseArgs() {
    for(int i = 1; i < __argc; i++) {
        if(strcmp(__argv[i], "--message") == 0 && i+1 < __argc) {
            strncpy(g_message, __argv[++i], 1023);
        }
        else if(strcmp(__argv[i], "--output") == 0 && i+1 < __argc) {
            strncpy(g_output, __argv[++i], 1023);
        }
        else if(strcmp(__argv[i], "--timeout") == 0 && i+1 < __argc) {
            g_timeout_secs = atoi(__argv[++i]);
        }
    }
}

void DoWriteAndExit() {
    char buf[1024];
    if (g_hwnd) {
        GetDlgItemTextA(g_hwnd, IDC_EDIT, buf, 1024);
    } else {
        strncpy(buf, g_message, 1024);
    }
    
    LogFmt("INFO: Attempting to write message to %s", g_output);
    if (WriteMessage(g_output, buf)) {
        LogFmt("GUI SUCCESS: Wrote '%s'", buf);
    } else {
        LogFmt("GUI FAILURE: Could not write to %s", g_output);
        LogFmt("DEBUG: errno=%s", strerror(errno));
    }
    
    Log("INFO: Terminating process.");
    _exit(0);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch(msg) {
    case WM_CREATE:
        Log("INFO: WM_CREATE received.");
        CreateWindowA("EDIT", g_message, WS_CHILD|WS_VISIBLE|WS_BORDER|ES_AUTOHSCROLL, 
            10, 10, 300, 25, hwnd, (HMENU)IDC_EDIT, NULL, NULL);
        CreateWindowA("BUTTON", "Write & Exit", WS_CHILD|WS_VISIBLE, 
            10, 50, 120, 25, hwnd, (HMENU)IDC_BTN, NULL, NULL);
        break;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_BTN) {
            Log("INFO: Button clicked.");
            DoWriteAndExit();
        }
        break;
    case WM_DESTROY:
        _exit(0);
        break;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    ParseArgs();
    printf("INFO: App started. Timeout=%d\n", g_timeout_secs);
    fflush(stdout);

    if (g_timeout_secs > 0) {
        Log("INFO: Non-interactive mode detected due to timeout.");
        DoWriteAndExit();
    }

    const char CLASS_NAME[] = "ValidationGUIClass";
    WNDCLASSA wc = {0};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    RegisterClassA(&wc);

    g_hwnd = CreateWindowExA(0, CLASS_NAME, "Validation GUI", 
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 400, 150, 
        NULL, NULL, hInstance, NULL);

    if (!g_hwnd) {
        return 1;
    }

    ShowWindow(g_hwnd, nCmdShow);
    Log("INFO: Window shown.");

    Log("INFO: Entering standard message loop.");
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

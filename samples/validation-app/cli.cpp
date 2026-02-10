#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "core.h"

void Log(const char* msg) {
    printf("%s\n", msg);
    fflush(stdout);
}

void LogFmt(const char* fmt, const char* arg) {
    printf(fmt, arg);
    printf("\n");
    fflush(stdout);
}

int main(int argc, char* argv[]) {
    const char* msg = "Hello World (CLI Default)";
    const char* out = "validation_output.txt";

    for(int i=1; i<argc; i++) {
        if(strcmp(argv[i], "--message")==0 && i+1 < argc) {
            msg = argv[++i];
        }
        else if(strcmp(argv[i], "--output")==0 && i+1 < argc) {
            out = argv[++i];
        }
    }

    LogFmt("INFO: CLI attempting to write to %s", out);
    if(WriteMessage(out, msg)) {
        LogFmt("SUCCESS: Wrote '%s'", msg);
        return 0;
    } else {
        LogFmt("FAILURE: Could not write to %s", out);
        return 1;
    }
}

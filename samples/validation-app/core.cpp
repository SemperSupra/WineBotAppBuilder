#define COMPILING_DLL
#include "core.h"
#include <stdio.h>

int WriteMessage(const char* filepath, const char* message) {
    FILE* f = fopen(filepath, "w");
    if (!f) return 0;
    fprintf(f, "%s\n", message);
    fclose(f);
    return 1;
}

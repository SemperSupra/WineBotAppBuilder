#ifndef VALIDATION_CORE_H
#define VALIDATION_CORE_H

#ifdef COMPILING_DLL
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT __declspec(dllimport)
#endif

extern "C" {
    /* 
     * Idempotent write: overwrites the file with the message.
     * Returns 1 on success, 0 on failure.
     */
    DLLEXPORT int WriteMessage(const char* filepath, const char* message);
}

#endif

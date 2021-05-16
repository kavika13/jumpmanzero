#include "logging.h"

#include <stdarg.h>
#include <stdio.h>
#include <stb_sprintf.h>

#if defined(_WIN32)
    #include <malloc.h>
    #include <win32/dbghelp.h>
#endif

static int vdebug_log(char const* const format_string, va_list argp) {
#if defined(_WIN32)
    int len = stbsp_vsnprintf(NULL, 0, format_string, argp) + 1;
    char* error_message_buffer = malloc(len);

    if(error_message_buffer) {
        int outlen = stbsp_vsnprintf(error_message_buffer, len, format_string, argp) + 1;

        if(outlen == len) {
            OutputDebugStringA(error_message_buffer);
        }

        free(error_message_buffer);
    }
#endif

    return vfprintf(stderr, format_string, argp);
}

int debug_log(char const* const format_string, ...) {
    va_list argp;
    va_start(argp, format_string);
    int result = vdebug_log(format_string, argp);
    va_end(argp);
    return result;
}

/*
 * log.c
 * Brandon Azad
 */
#include "log.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <Foundation/Foundation.h>

NSString *LOGGED = @"";
bool SHOULD_LOG = true;

void
log_internal(char type, const char *format, ...) {
	if (log_implementation != NULL) {
		va_list ap;
		va_start(ap, format);
		log_implementation(type, format, ap);
		va_end(ap);
	}
}

// The default logging implementation prints to stderr with a nice hacker prefix.
static void
log_stderr(char type, const char *format, va_list ap) {
	char *message = NULL;
	vasprintf(&message, format, ap);
	assert(message != NULL);
    char *prefix = "";
    char *suffix = "\n";
	switch (type) {
		case 'D': prefix = "[D] "; break;
		case 'I': prefix = "[+] "; break;
		case 'W': prefix = "[!] "; break;
		case 'E': prefix = "[-] "; break;
        case 'L': suffix = ""; break;
	}
	fprintf(stderr, "%s%s%s", prefix, message, suffix);
    if (SHOULD_LOG) LOGGED = [LOGGED stringByAppendingString:[NSString stringWithFormat:@"%s%s%s", prefix, message, suffix]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoggedToString" object:nil];
	free(message);
}

void (*log_implementation)(char type, const char *format, va_list ap) = log_stderr;

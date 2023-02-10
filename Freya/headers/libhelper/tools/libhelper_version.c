#include <stdio.h>
#include <libhelper/libhelper.h>

#ifdef __APPLE__
#   define BUILD_TARGET         "darwin"
#   define BUILD_TARGET_CAP     "Darwin"
#else
#   define BUILD_TARGET         "linux"
#   define BUILD_TARGET_CAP     "Linux"
#endif

#ifdef __x86_64__
#   define BUILD_ARCH           "x86_64"
#elif __arm64__
#	define BUILD_ARCH			"arm64"
#elif __arm__
#   define BUILD_ARCH           "arm"
#endif

int main ()
{
    printf ("%s Libhelper Version %s~%s (%s)\n", BUILD_TARGET_CAP, LIBHELPER_VERSION_SHORT, LIBHELPER_VERSION_TAG,
							LIBHELPER_VERSION_LONG);
    
    printf ("  Build Time:\t\t" __TIMESTAMP__ "\n");
    printf ("  Default Target:\t%s-%s\n", BUILD_TARGET, BUILD_ARCH);
    printf ("  Libhelper:\t\t%s\n", LIBHELPER_VERSION_LONG);

    return 0;
}

#ifndef BASECOMPAT_H
#define BASECOMPAT_H

#include <epicsVersion.h>

#ifndef VERSION_INT
#define VERSION_INT(V,R,M,P) ( ((V)<<24) | ((R)<<16) | ((M)<<8) | (P))
#define EPICS_VERSION_INT VERSION_INT(EPICS_VERSION, EPICS_REVISION, EPICS_MODIFICATION, EPICS_PATCH_LEVEL)
#endif

#if EPICS_VERSION_INT>=VERSION_INT(3,15,0,1)
#include <epicsStdlib.h>
#else
#include <errno.h>

#define M_stdlib        (527 <<16) /*EPICS Standard library*/

#define S_stdlib_noConversion (M_stdlib | 1) /* No digits to convert */
#define S_stdlib_extraneous   (M_stdlib | 2) /* Extraneous characters */
#define S_stdlib_underflow    (M_stdlib | 3) /* Too small to represent */
#define S_stdlib_overflow     (M_stdlib | 4) /* Too large to represent */
#define S_stdlib_badBase      (M_stdlib | 5) /* Number base not supported */

static inline
int
epicsParseULong(const char *str, unsigned long *to, int base, char **units)
{
    int c;
    char *endp;
    unsigned long value;

    while ((c = *str) && isspace(c))
        ++str;

    errno = 0;
    value = strtoul(str, &endp, base);

    if (endp == str)
        return S_stdlib_noConversion;
    if (errno == EINVAL)    /* Not universally supported */
        return S_stdlib_badBase;
    if (errno == ERANGE)
        return S_stdlib_overflow;

    while ((c = *endp) && isspace(c))
        ++endp;
    if (c && !units)
        return S_stdlib_extraneous;

    *to = value;
    if (units)
        *units = endp;
    return 0;
}
#endif

#endif /* BASECOMPAT_H */

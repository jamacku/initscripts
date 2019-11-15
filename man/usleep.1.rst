.. |_| unicode:: U+0009 .. CHARACTER TABULATION

======
usleep
======

---------------------------------
sleep some number of microseconds
---------------------------------

:Author: Donald Barnes <djb@redhat.com>
:Author: Erik Troan <ewt@redhat.com>         
:organization: Red Hat, Inc

:Manual section: 1
:Manual group: General Commands Manual

SYNOPSIS
--------

**usleep** \[\ *number*]

DESCRIPTION
-----------

**usleep** sleeps some number of microseconds. The default is 1.

WARNING
-------

**usleep** has been deprecated, and will be removed in near future. Use sleep(1) instead.

OPTIONS
-------

*--usage*         Show short usage message.

*--help*, *-?*      Print help information.

*-v*, *--version*   Print version information.

BUGS
----

Probably not accurate on many machines down to the microsecond. Count on precision only to -4 or maybe -5.

SEE ALSO
--------

sleep(1)

# User stories

## Portable application maintainer

As a maintainer, I can encode and decode UTF-8, enforce a bounded Lisp
operation, and use a small TCP lifecycle API without referring to SBCL or CCL
packages.

## Unix application maintainer

As a maintainer of a Unix application, I can create a lock directory
atomically, set and inspect mode bits, and check a process ID through one
portable POSIX facade.

## Threaded application maintainer

As a maintainer, I use Bordeaux Threads directly for threads, locks, and
condition variables, rather than receiving an incomplete second threading API
from `ls-compat`.

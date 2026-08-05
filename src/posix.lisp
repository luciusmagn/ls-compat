(in-package #:ls-compat.posix)

;;;; -- Types --

(deftype pathname-designator ()
  "A pathname or namestring accepted by ls-compat POSIX operations."
  '(or pathname string))


;;;; -- Pathnames --

(serapeum:-> posix--native-namestring (pathname-designator) string)
(defun posix--native-namestring (pathname)
  "Return PATHNAME as a native namestring for OSICAT."
  (uiop:native-namestring (pathname pathname)))


;;;; -- Processes --

(serapeum:-> current-process-id () (integer 1 *))
(defun current-process-id ()
  "Return the current process ID."
  (osicat-posix:getpid))

(serapeum:-> process-alive-p ((integer 1 *)) boolean)
(defun process-alive-p (process-id)
  "Return whether PROCESS-ID currently exists or cannot be signaled.

This is a POSIX kill-with-signal-zero snapshot. An EPERM response means that a
process appears to exist but cannot be signaled by the current user. PID reuse
means the predicate cannot prove process identity."
  (handler-case
      (progn
        (osicat-posix:kill process-id 0)
        t)
    (osicat-posix:eperm ()
      t)
    (osicat-posix:posix-error ()
      nil)))


;;;; -- Filesystem modes --

(serapeum:-> make-directory-exclusively
  (pathname-designator &key (:mode (integer 0 #o777)))
  pathname)
(defun make-directory-exclusively (pathname &key (mode #o700))
  "Create PATHNAME atomically with MODE and return its pathname.

Signals OSICAT's POSIX condition when PATHNAME already exists or creation
fails. The operating system umask can further restrict MODE."
  (check-type mode (integer 0 #o777))
  (osicat-posix:mkdir (posix--native-namestring pathname) mode)
  (pathname pathname))

(serapeum:-> file-mode (pathname-designator) (integer 0 *))
(defun file-mode (pathname)
  "Return PATHNAME's raw POSIX mode bits."
  (osicat-posix:stat-mode
   (osicat-posix:stat (posix--native-namestring pathname))))

(serapeum:-> (setf file-mode) ((integer 0 #o777) pathname-designator) (integer 0 #o777))
(defun (setf file-mode) (mode pathname)
  "Set PATHNAME's permission MODE and return MODE."
  (check-type mode (integer 0 #o777))
  (osicat-posix:chmod (posix--native-namestring pathname) mode)
  mode)

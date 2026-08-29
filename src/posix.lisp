(in-package #:ls-compat.posix)

;;;; -- Types --

(deftype pathname-designator ()
  "A pathname or namestring accepted by ls-compat POSIX operations."
  '(or pathname string))


;;;; -- Implementation boundary --

(ls-compat::-> posix--native-namestring (pathname-designator) string)
(defun posix--native-namestring (pathname)
  "Return PATHNAME as a native namestring for the POSIX backend."
  (uiop:native-namestring (pathname pathname)))

#-sbcl
(defun posix--unsupported (operation)
  "Signal that OPERATION has no POSIX backend on this implementation."
  (error 'ls-compat:unsupported-operation :name operation))


;;;; -- Processes --

(ls-compat::-> current-process-id () (integer 1 *))
(defun current-process-id ()
  "Return the current process ID.

The POSIX system currently supports SBCL. Other implementations signal
LS-COMPAT:UNSUPPORTED-OPERATION."
  #+sbcl
  (sb-posix:getpid)
  #-sbcl
  (posix--unsupported 'current-process-id))

#+sbcl
(defun posix--process-target-alive-p (target)
  "Return whether POSIX kill target TARGET exists or cannot be signaled."
  (handler-case
      (progn
        (sb-posix:kill target 0)
        t)
    (sb-posix:syscall-error (condition)
      (= (sb-posix:syscall-errno condition) sb-posix:eperm))))

(ls-compat::-> process-alive-p ((integer 1 *)) boolean)
(defun process-alive-p (process-id)
  "Return whether PROCESS-ID currently exists or cannot be signaled.

This is a POSIX kill-with-signal-zero snapshot. An EPERM response means that a
process appears to exist but cannot be signaled by the current user. PID reuse
means the predicate cannot prove process identity. The POSIX system currently
supports SBCL."
  (declare (ignorable process-id))
  #+sbcl
  (posix--process-target-alive-p process-id)
  #-sbcl
  (posix--unsupported 'process-alive-p))

(ls-compat::-> process-group-id ((integer 1 *)) (integer 1 *))
(defun process-group-id (process-id)
  "Return the POSIX process group identifier of PROCESS-ID.

The POSIX system currently supports SBCL."
  (declare (ignorable process-id))
  #+sbcl
  (sb-posix:getpgid process-id)
  #-sbcl
  (posix--unsupported 'process-group-id))

(ls-compat::-> process-group-alive-p ((integer 1 *)) boolean)
(defun process-group-alive-p (process-group-id)
  "Return whether PROCESS-GROUP-ID currently has members.

This is a POSIX kill-with-signal-zero snapshot. An EPERM response means that a
process group appears to exist but cannot be signaled by the current user. The
POSIX system currently supports SBCL."
  (declare (ignorable process-group-id))
  #+sbcl
  (posix--process-target-alive-p (- process-group-id))
  #-sbcl
  (posix--unsupported 'process-group-alive-p))

(ls-compat::-> signal-process-group
  ((integer 1 *) (member :terminate :kill))
  (integer 1 *))
(defun signal-process-group (process-group-id signal)
  "Send SIGNAL to every member of PROCESS-GROUP-ID and return its identifier.

SIGNAL is either :TERMINATE or :KILL. POSIX errors, including a missing process
group, propagate as backend conditions. The POSIX system currently supports
SBCL."
  (declare (ignorable process-group-id signal))
  #+sbcl
  (progn
    (sb-posix:kill
     (- process-group-id)
     (ecase signal
       (:terminate sb-posix:sigterm)
       (:kill sb-posix:sigkill)))
    process-group-id)
  #-sbcl
  (posix--unsupported 'signal-process-group))


;;;; -- Filesystem modes --

(ls-compat::-> make-directory-exclusively
  (pathname-designator &key (:mode (integer 0 #o777)))
  pathname)
(defun make-directory-exclusively (pathname &key (mode #o700))
  "Create PATHNAME atomically with MODE and return its pathname.

Signals the backend's POSIX condition when PATHNAME already exists or creation
fails. The operating system umask can further restrict MODE. The POSIX system
currently supports SBCL."
  (declare (ignorable pathname))
  (check-type mode (integer 0 #o777))
  #+sbcl
  (progn
    (sb-posix:mkdir (posix--native-namestring pathname) mode)
    (pathname pathname))
  #-sbcl
  (posix--unsupported 'make-directory-exclusively))

(ls-compat::-> file-mode (pathname-designator) (integer 0 *))
(defun file-mode (pathname)
  "Return PATHNAME's raw POSIX mode bits.

The POSIX system currently supports SBCL."
  (declare (ignorable pathname))
  #+sbcl
  (sb-posix:stat-mode
   (sb-posix:stat (posix--native-namestring pathname)))
  #-sbcl
  (posix--unsupported 'file-mode))

(ls-compat::-> (setf file-mode) ((integer 0 #o777) pathname-designator) (integer 0 #o777))
(defun (setf file-mode) (mode pathname)
  "Set PATHNAME's permission MODE and return MODE.

The POSIX system currently supports SBCL."
  (declare (ignorable pathname))
  (check-type mode (integer 0 #o777))
  #+sbcl
  (progn
    (sb-posix:chmod (posix--native-namestring pathname) mode)
    mode)
  #-sbcl
  (posix--unsupported 'file-mode))

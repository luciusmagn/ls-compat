(in-package #:ls-compat/tests)

(defvar *test-failures* nil
  "Descriptions of failed ls-compat regression checks.")


;;;; -- Test helpers --

(defun tests--check (value description)
  "Record DESCRIPTION unless VALUE is true, then return VALUE."
  (unless value
    (push description *test-failures*))
  value)

(defun tests--temporary-directory ()
  "Return a unique temporary directory pathname."
  (merge-pathnames
   (format nil "ls-compat-~D-~D/"
           (current-process-id)
           (random most-positive-fixnum))
   (uiop:temporary-directory)))


;;;; -- Core --

(defun tests--utf8-round-trip ()
  "Check portable UTF-8 encoding and decoding."
  (let* ((text "Příliš žluťoučký kůň")
         (octets (utf8-string-to-octets text)))
    (tests--check
     (equalp octets
             #(80 197 153 195 173 108 105 197 161 32 197 190 108 117 197 165 111 117 196 141 107 195 189 32 107 197 175 197 136))
     "UTF-8 encoding produced unexpected octets.")
    (tests--check (string= text (utf8-octets-to-string octets))
                  "UTF-8 decoding did not recover the original string.")))

(defun tests--finite-floats ()
  "Check that ordinary and extreme finite floats are accepted."
  (tests--check (finite-float-p 1.0d0)
                "An ordinary double float was not finite.")
  (tests--check (finite-float-p (- most-positive-double-float))
                "The largest negative double float was not finite."))

(defun tests--timeout-signals-condition ()
  "Check that a deadline expires or declares the capability unsupported."
  (handler-case
      (progn
        (with-timeout 0.01
          (sleep 1))
        (tests--check nil "A timeout did not signal a public condition."))
    (timeout-expired ()
      t)
    (unsupported-operation (condition)
      (tests--check (eq 'ls-compat:call-with-timeout
                        (unsupported-operation-name condition))
                    "Unsupported timeout named the wrong operation."))))


;;;; -- POSIX --

(defun tests--current-process-group ()
  "Check current process group lookup and liveness."
  (let* ((process-id (current-process-id))
         (process-group-id (process-group-id process-id)))
    (tests--check (plusp process-group-id)
                  "Current process group identifier is not positive.")
    (tests--check (process-group-alive-p process-group-id)
                  "Current process group is not alive.")))

(defun tests--exclusive-directory-and-mode ()
  "Check atomic directory creation and permission mode access."
  (let ((directory (tests--temporary-directory)))
    (unwind-protect
         (progn
           (tests--check
            (pathnamep (make-directory-exclusively directory :mode #o700))
            "Exclusive directory creation did not return a pathname.")
           (tests--check (= #o700 (logand #o777 (file-mode directory)))
                          "New directory mode is not 0700.")
           (setf (file-mode directory) #o755)
           (tests--check (= #o755 (logand #o777 (file-mode directory)))
                          "Updated directory mode is not 0755."))
      (ignore-errors
        (uiop:delete-directory-tree directory :validate t)))))


;;;; -- TCP --

(defun tests--tcp-lifecycle ()
  "Check listener creation, client connection, acceptance, and streams."
  (let ((listener (tcp-listen "127.0.0.1" 0))
        (client nil)
        (server nil))
    (unwind-protect
         (let ((port (tcp-local-port listener)))
           (setf client (tcp-connect "127.0.0.1" port)
                 server (tcp-accept listener))
           (tests--check (streamp (tcp-stream client))
                          "TCP client has no stream.")
           (tests--check (streamp (tcp-stream server))
                          "Accepted TCP connection has no stream.")
           (let ((payload #(0 1 2 253 254 255))
                 (received (make-array 6 :element-type '(unsigned-byte 8))))
             (write-sequence payload (tcp-stream client))
             (finish-output (tcp-stream client))
             (tests--check (= (length payload)
                              (read-sequence received (tcp-stream server)))
                            "Accepted TCP connection did not receive every octet.")
             (tests--check (equalp payload received)
                            "TCP octets changed during transfer.")))
      (dolist (socket (list server client listener))
        (when socket
          (ignore-errors
            (close-tcp socket)))))))


;;;; -- Runner --

(defun run-tests ()
  "Run ls-compat regression tests and signal an error on any failure."
  (let ((*test-failures* nil))
    (dolist (test '(tests--utf8-round-trip
                    tests--finite-floats
                    tests--timeout-signals-condition
                    tests--current-process-group
                    tests--exclusive-directory-and-mode
                    tests--tcp-lifecycle))
      (funcall test))
    (when *test-failures*
      (error "ls-compat test failures:~%~{~A~%~}"
             (nreverse *test-failures*)))
    t))

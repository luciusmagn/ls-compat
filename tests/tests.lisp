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

(defun tests--timeout-signals-condition ()
  "Check that a deadline signals the public timeout condition."
  (handler-case
      (progn
        (with-timeout 0.01
          (sleep 1))
        (tests--check nil "A timeout did not signal TIMEOUT-EXPIRED."))
    (timeout-expired ()
      t)))


;;;; -- POSIX --

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
                          "Accepted TCP connection has no stream."))
      (dolist (socket (list server client listener))
        (when socket
          (ignore-errors
            (close-tcp socket)))))))


;;;; -- Runner --

(defun run-tests ()
  "Run ls-compat regression tests and signal an error on any failure."
  (let ((*test-failures* nil))
    (dolist (test '(tests--utf8-round-trip
                    tests--timeout-signals-condition
                    tests--exclusive-directory-and-mode
                    tests--tcp-lifecycle))
      (funcall test))
    (when *test-failures*
      (error "ls-compat test failures:~%~{~A~%~}"
             (nreverse *test-failures*)))
    t))

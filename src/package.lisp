(defpackage #:ls-compat
  (:use #:cl)
  (:export #:utf8-string-to-octets
           #:utf8-octets-to-string
           #:finite-float-p
           #:call-with-timeout
           #:with-timeout
           #:timeout-expired
           #:timeout-expired-seconds
           #:unsupported-operation
           #:unsupported-operation-name))

(defpackage #:ls-compat.posix
  (:use #:cl)
  (:export #:current-process-id
           #:process-alive-p
           #:process-group-id
           #:process-group-alive-p
           #:signal-process-group
           #:make-directory-exclusively
           #:file-mode))

(defpackage #:ls-compat.tcp
  (:use #:cl)
  (:export #:tcp-connect
           #:tcp-listen
           #:tcp-accept
           #:tcp-stream
           #:tcp-local-port
           #:close-tcp))

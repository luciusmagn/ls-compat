(defpackage #:ls-compat/tests
  (:use #:cl)
  (:import-from #:ls-compat
                #:utf8-string-to-octets
                #:utf8-octets-to-string
                #:with-timeout
                #:timeout-expired)
  (:import-from #:ls-compat.posix
                #:current-process-id
                #:make-directory-exclusively
                #:file-mode)
  (:import-from #:ls-compat.tcp
                #:tcp-connect
                #:tcp-listen
                #:tcp-accept
                #:tcp-stream
                #:tcp-local-port
                #:close-tcp))

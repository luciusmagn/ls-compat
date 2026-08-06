(asdf:defsystem #:ls-compat
  :description "Focused Common Lisp portability utilities for LS projects."
  :author "Lukáš Hozda"
  :license "COLL-Attribution"
  :version "0.1.0"
  :depends-on (#:babel #:serapeum)
  :serial t
  :components ((:file "src/package")
               (:file "src/core"))
  :in-order-to ((asdf:test-op (asdf:test-op #:ls-compat/tests))))

(asdf:defsystem #:ls-compat/posix
  :description "Unix-specific ls-compat operations backed by OSICAT."
  :depends-on (#:ls-compat #:osicat)
  :serial t
  :components ((:file "src/posix")))

(asdf:defsystem #:ls-compat/tcp
  :description "TCP lifecycle operations backed by USOCKET."
  :depends-on (#:ls-compat #:usocket)
  :serial t
  :components ((:file "src/tcp")))

(asdf:defsystem #:ls-compat/tests
  :description "Regression tests for ls-compat."
  :depends-on (#:ls-compat/posix #:ls-compat/tcp)
  :serial t
  :components ((:file "tests/package")
               (:file "tests/tests"))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call '#:ls-compat/tests '#:run-tests)))

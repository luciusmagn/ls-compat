(in-package #:ls-compat)

;;;; -- Types --

(deftype octet-vector ()
  "A vector whose elements are octets."
  '(vector (unsigned-byte 8)))

(deftype timeout-seconds ()
  "A timeout duration in seconds, or NIL when no deadline is requested."
  '(or null (real 0 *)))


;;;; -- Function types --

(defmacro -> (name argument-types result-type)
  "Declare NAME's function type using the compact signature syntax used here.

ECL retains the checked definitions without a declaration because its function
type syntax cannot represent these named keyword parameters. Other
implementations use Serapeum's portable declaration macro."
  #+ecl
  (declare (ignore name argument-types result-type))
  #+ecl
  nil
  #-ecl
  `(serapeum:-> ,name ,argument-types ,result-type))


;;;; -- Conditions --

(define-condition timeout-expired (error)
  ((seconds :initarg :seconds
            :reader timeout-expired-seconds
            :type (real 0 *)
            :documentation "The requested timeout duration in seconds."))
  (:documentation "Signaled when a ls-compat timeout reaches its deadline.")
  (:report (lambda (condition stream)
             (format stream "Operation timed out after ~,3F seconds."
                     (timeout-expired-seconds condition)))))

(define-condition unsupported-operation (error)
  ((name :initarg :name
         :reader unsupported-operation-name
         :type symbol
         :documentation "The unavailable ls-compat operation."))
  (:documentation "Signaled when an implementation cannot safely provide an operation.")
  (:report (lambda (condition stream)
             (format stream "~S is not supported by this Common Lisp implementation."
                     (unsupported-operation-name condition)))))


;;;; -- UTF-8 --

(-> utf8-string-to-octets
  (string &key (:start (or null (integer 0 *))) (:end (or null (integer 0 *))))
  octet-vector)
(defun utf8-string-to-octets (string &key start end)
  "Encode STRING as UTF-8 octets.

START and END delimit the portion of STRING to encode."
  (babel:string-to-octets string
                          :encoding ':utf-8
                          :start (or start 0)
                          :end (or end (length string))))

(-> utf8-octets-to-string
  (octet-vector &key (:start (or null (integer 0 *))) (:end (or null (integer 0 *))))
  string)
(defun utf8-octets-to-string (octets &key start end)
  "Decode UTF-8 OCTETS into a string.

START and END delimit the portion of OCTETS to decode."
  (babel:octets-to-string octets
                          :encoding ':utf-8
                          :start (or start 0)
                          :end (or end (length octets))))


;;;; -- Floating point --

(-> finite-float-p (float) boolean)
(defun finite-float-p (number)
  "Return whether NUMBER is neither a NaN nor an infinity.

The comparison uses the standardized finite LONG-FLOAT bounds, so it does not
expose implementation-specific floating-point predicates. Arithmetic failures
while inspecting a non-finite value count as false."
  (handler-case
      (and (= number number)
           (<= (- most-positive-long-float) number)
           (<= number most-positive-long-float))
    (arithmetic-error ()
      nil)))


;;;; -- Timeouts --

(-> call-with-timeout (timeout-seconds function) t)
(defun call-with-timeout (seconds thunk)
  "Call THUNK with a deadline of SECONDS.

NIL disables the deadline. SBCL interrupts the current thread. CCL runs THUNK
in a worker process and terminates that process when the deadline expires.
Other implementations signal UNSUPPORTED-OPERATION rather than ignoring the
deadline."
  (check-type seconds timeout-seconds)
  (if (null seconds)
      (funcall thunk)
      #+sbcl
      (handler-case
          (sb-ext:with-timeout seconds
            (funcall thunk))
        (sb-ext:timeout ()
          (error 'timeout-expired :seconds seconds)))
      #+ccl
      (let ((semaphore (ccl:make-semaphore))
            (values nil)
            (failure nil))
        (let ((process
                (ccl:process-run-function
                 "ls-compat timeout worker"
                 (lambda ()
                   (handler-case
                       (setf values (multiple-value-list (funcall thunk)))
                     (error (condition)
                       (setf failure condition)))
                   (ccl:signal-semaphore semaphore)))))
          (if (ccl:timed-wait-on-semaphore semaphore seconds)
              (if failure
                  (error failure)
                  (values-list values))
              (progn
                (ccl:process-kill process)
                (error 'timeout-expired :seconds seconds)))))
      #-(or sbcl ccl)
      (error 'unsupported-operation :name 'call-with-timeout)))

(defmacro with-timeout (seconds &body body)
  "Evaluate BODY with a deadline of SECONDS.

Signals TIMEOUT-EXPIRED when the deadline is reached."
  `(call-with-timeout ,seconds (lambda () ,@body)))

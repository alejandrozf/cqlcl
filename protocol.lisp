(in-package :cqlcl)


;; TODO: Maybe implement it as a re-entrant parser?
;; (defclass parser ()
;;   ((buf :accessor buf :initform
;;         (make-array 512 :fill-pointer 0 :adjustable t))))

;; (defun make-parser ()
;;   (make-instance 'parser))

(defmacro as-flags (&rest values)
  `(logior
    ,@(mapcar (lambda (value)
                `(ldb (byte 8 0) ,value)) values)))

(defun encode-values (values)
  ;; TODO: Implement this.  It should take a sequence of values which
  ;; then should be MAPCAR'd over to `encode-value' into a stream and
  ;; returned either as a BYTE-VECTOR or a STREAM.
  (declare (ignore values))
  (make-in-memory-output-stream))

(defgeneric encode-value (value stream)
  (:documentation "Encodes a value into the CQL wire format."))

(defmethod encode-value ((value header) stream)
  ;; TODO: Implement `define-binary-type' which would:
  ;; (define-binary-type header
  ;;  ((version/request-type (flags (0 version)
  ;;                                (1 request-type))
  ;;   (request-flags        (flags (0 compression)
  ;;                                (1 tracing))
  ;;   (stream-id            octet)
  ;;   (length               octet))
  ;;
  ;; And that would generate a `DEFCLASS' to hold the values as well
  ;; as the requisite parsing code (as below).
  (write-octet (as-flags (ptype value) (vsn value)) stream)
  (write-octet (as-flags (if (compression value) 1 0)
                         (if (tracing value) 1 0)) stream)
  (write-octet (id value) stream)
  (write-octet (gethash (op value) +op-code-name-to-digit+) stream)
  (if (body value)
      (let* ((os (flexi-streams:make-in-memory-output-stream))
             (ims (flexi-streams:make-flexi-stream os)))
        (if (member (op value) (list :prepare :query))
            (progn
              (write-int (length (body value)) ims)
              (write-sequence (as-bytes (body value)) ims))
            (encode-value (body value) ims))
        (when (eq (op value) :query)
          (write-short 0 ims))
        (let ((bv (flexi-streams:get-output-stream-sequence os)))
          (write-int (length bv) stream)
          (write-sequence bv stream)))
      (write-int 0 stream)))

(defun write-length (thing stream)
  (let ((len (length thing)))
    (if (> len 65535)
        (write-int len stream)
        (write-short len stream))
    len))

(defmethod encode-value ((value string) stream)
  (encode-value (as-bytes value) stream))

(defmethod encode-value ((value hash-table) stream)
  (let ((num-entries (hash-table-count value)))
    (write-short num-entries stream)
    (maphash (lambda (k v)
               (encode-value k stream)
               (encode-value v stream)) value)))

(defmethod encode-value ((value null) stream)
  (write-octet 0 stream))

(defmethod encode-value ((value vector) stream)
  (write-length value stream)
  (write-sequence value stream))

(defmethod encode-value ((value symbol) stream)
  (let ((consistency (gethash value +consistency-name-to-digit+)))
    (cond
      ((eq t value)
       (write-octet 1 stream))
      (consistency
       (write-short consistency stream))
      (t
       (error (format nil "Unknown symbol or keyword attempted to be encoded: ~A"
                      value))))))

(defmethod encode-value ((value uuid) stream)
  (write-sequence (uuid-to-byte-array value) stream))

(defmethod encode-value ((value ipv4) stream)
  (let ((encoded-ip (ip-to-integer value)))
    (write-octet 4 stream)
    (write-int encoded-ip stream)))

(defmethod encode-value ((value ipv6) stream)
  (let ((encoded-ip (ip-to-integer value)))
    (write-octet 16 stream)
    (write-ipv6 encoded-ip stream)))

(defun as-string (bv)
  (flexi-streams:octets-to-string bv :external-format :utf-8))

(defun as-bytes (s)
  (flexi-streams:string-to-octets s))

(defun parse-bytes* (stream size-fn &optional (post-process #'identity))
  (let* ((size (max (funcall size-fn stream) 0))
         (buf  (make-array size :element-type '(unsigned-byte 8))))
    (assert (= (read-sequence buf stream :end size) size))
    (funcall post-process buf)))

(defun parse-boolean (stream)
  (let ((b (read-byte stream)))
    (not (zerop b))))

(defun parse-uuid (stream)
  (parse-bytes* stream (lambda (stream) (declare (ignore stream)) 16)))

(defun parse-ip (stream)
  (let ((size (read-octet stream)))
    (assert (or (= size 4)
                (= size 16)))
    (let ((ip-bytes (parse-bytes* stream (lambda (stream)
                                           (declare (ignore stream))
                                           size))))
      (byte-array-to-ip ip-bytes))))

(defun parse-int (stream)
  (read-int stream :signed? t))

(defun parse-short (stream)
  (read-short stream))

(defun parse-bytes (stream)
  (parse-bytes* stream #'read-int))

(defun parse-short-bytes (stream)
  (parse-bytes* stream #'read-short))

(defun parse-consistency (stream)
  (gethash (read-short stream) +consistency-digit-to-name+))

(defun parse-string (stream)
  (parse-bytes* stream #'read-short #'as-string))

(defun parse-string-list (stream)
  (let* ((size (read-short stream)))
    (loop for i from 1 upto size
       collect
         (parse-string stream))))

(defun parse-map (stream value-fn)
  (let ((map (make-hash-table :test #'equalp))
        (num-entries (read-short stream)))
    (dotimes (i num-entries)
      (let* ((key (parse-string stream))
             (entry (funcall value-fn stream)))
        (setf (gethash key map) entry)))
    map))

(defun parse-string-multimap (stream)
  (parse-map stream #'parse-string-list))

(defun parse-string-map (stream)
  (parse-map stream #'parse-string))

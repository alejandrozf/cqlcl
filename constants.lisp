(in-package :cqlcl)


(defvar +option-id+
  (alexandria:alist-hash-table
   '((#x0000 . :custom)
     (#x0001 . :ascii)
     (#x0002 . :bigint)
     (#x0003 . :blob)
     (#x0004 . :boolean)
     (#x0005 . :counter)
     (#x0006 . :decimal)
     (#x0007 . :double)
     (#x0008 . :float)
     (#x0009 . :int)
     (#x000a . :text)
     (#x000b . :timestamp)
     (#x000c . :uuid)
     (#x000d . :varchar)
     (#x000e . :varint)
     (#x000f . :timeuuid)
     (#x0010 . :inet)
     (#x0020 . :list)
     (#x0021 . :map)
     (#x0022 . :set))
   :test #'equal))
(defvar +default-version+ #x01)
(defvar +header-length+ 8)
(defvar +packet-type-index+ 3)
(defvar +request+  #x00)
(defvar +response+ #x01)
(defvar +global-tables-spec+ (ldb (byte 16 0) #x0001))
(defvar +has-more-pages+ (ldb (byte 16 0) #x0002))
(defvar +no-meta-data+ (ldb (byte 16 0) #x0004))
(defvar +message-types+ (list +request+ +response+))
(defvar +result-type+
  (alexandria:alist-hash-table
   '((#x01 . :void)
     (#x02 . :rows)
     (#x03 . :set-keyspace)
     (#x04 . :prepared)
     (#x05 . :schema-change))
   :test #'equal))
(defvar +op-code-name-to-digit+
  (alexandria:alist-hash-table
   '((:error        . #x00)
     (:startup      . #x01)
     (:ready        . #x02)
     (:authenticate . #x03)
     (:credentials  . #x04)
     (:options      . #x05)
     (:supported    . #x06)
     (:query        . #x07)
     (:result       . #x08)
     (:prepare      . #x09)
     (:execute      . #x0a)
     (:register     . #x0b)
     (:event        . #x0c))))
(defvar +op-code-digit-to-name+
  (rev-hash +op-code-name-to-digit+))
(defvar +consistency-name-to-digit+
  (alexandria:alist-hash-table
   '((:any          . #x00)
     (:one          . #x01)
     (:two          . #x02)
     (:three        . #x03)
     (:quorum       . #x04)
     (:all          . #x05)
     (:local-quorum . #x06)
     (:each-quorum  . #x07))))
(defvar +consistency-digit-to-name+
  (rev-hash +consistency-name-to-digit+))
(defvar +error-codes+
  (alexandria:alist-hash-table
   '((0x0000 . :server-error)
     (0x000A . :protocol-error)
     (0x0100 . :bad-credentials)
     (0x1000 . :unavailable-exception)
     (0x1001 . :overloaded)
     (0x1002 . :is-bootstrapping)
     (0x1003 . :truncate-error)
     (0x1100 . :write-timeout)
     (0x1200 . :read-timeout)
     (0x2000 . :syntax-error)
     (0x2100 . :unauthorized)
     (0x2200 . :invalid)
     (0x2300 . :config-error)
     (0x2400 . :already-exists)
     (0x2500 . :unprepared))
   :test #'equal))

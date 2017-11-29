(defpackage :lispcord.util
  (:use :cl)
  (:export #:mapvec
	   #:str-concat
	   #:jparse
	   #:jmake
	   #:alist
	   #:aget
	   #:doit
	   #:str-case
	   #:split-string
	   #:curry
	   #:sethash
	   #:make-nonce
	   #:mapf
	   #:with-table
	   #:instance-from-table
	   #:since-unix-epoch
	   #:*unix-epoch*
	   #:vec-extend
	   #:new-hash-table
	   #:vecrem
	   #:xor

	   #:snowflake
	   #:parse-snowflake
	   #:to-string
	   #:optimal-id-compare

	   #:set-debug-level
	   #:dprint))

(in-package :lispcord.util)



;; this type allows us to later potentially convert the IDs to numbers
;; without needing to rewrite all the type declerations!
(deftype snowflake () 'string)

(defun parse-snowflake (snowflake-string)
  snowflake-string)

(defun to-string (obj)
  (format nil "~a" obj))

(defvar optimal-id-compare #'equal)

(defun str-concat (&rest strings)
  (apply #'concatenate 'string strings))

(defun jparse (payload)
  (jonathan:parse payload :as :hash-table))

(defun jmake (alist)
  (jonathan:to-json alist :from :alist))



(defun aget (key table)
  (gethash key table))

(defmacro doit (&rest forms)
  (let ((it (intern (symbol-name 'it))))
    `(let (,it)
       ,@(mapcar (lambda (f)
		   (if (eq :! (car f))
		       (cdr f)
		       `(setf ,it ,f)))
		 forms))))

(defmacro str-case (key-form &body clauses &aux (key (gensym)))
  `(let ((,key ,key-form))
     (cond ,@(mapcar (lambda (c)
		       (if (string= (string (car c)) "ELSE")
			   `(T ,@(cdr c))
			   `((string= ,key ,(car c)) ,@(cdr c))))
		     clauses))))


;;; Set up a logging framework so bot authors can
;;;  gather various levels of information
(defparameter *debug-level* :debug
  "The debug level can be one of: :error, :warn, :info, :debug")

(defvar *debug-levels*
  `((:error . ,(lambda (l) (case l (:error t))))
    (:warn . ,(lambda (l) (case l ((:error :warn) t))))
    (:info . ,(lambda (l) (case l ((:error :warn :info) t))))
    (:debug . ,(lambda (l) (case l ((:error :warn :info :debug) t))))))

(defun set-log-level (level)
  (declare (type keyword level))
  (ecase level
    ((:info :error :warn :debug) (setf *debug-level* level))))


;;unfortunately "log" is package locked
(defun dprint (level message &rest arguments)
  (when (funcall (cdr (assoc *debug-level* *debug-levels*)) level)
    (apply #'format *error-output* message arguments)))

(defparameter *unix-epoch* (encode-universal-time 0 0 0 1 1 1970 0)
  "Seconds since until 1970")

(defun since-unix-epoch ()
  (- (get-universal-time)
     *unix-epoch*))



(defun time-passed (since &optional (unit :minute))
  (let ((now (get-universal-time)))
    (case unit
      ((:second :seconds) (<= (1+ since) now))
      ((:minute :minutes) (<= (+ since 60) now))
      ((:hour :hours)     (<= (+ since 3600) now)))))


(defun curry (f &rest args)
  (lambda (arg) (apply f (append args (list arg)))))

(defun split-string (string &optional (delimiter #\space))
  (declare (type string string)
	   (type character delimiter)
	   (optimize speed))
  (let ((pos (position delimiter string)))
    (if pos
	(cons (subseq string 0 pos)
	      (split-string (subseq string (1+ pos)) delimiter))
	(list string))))


(defun sethash (key hash val)
  (setf (gethash key hash) val))


(let ((cnt 0))
  (defun make-nonce ()
    (format nil "~d" (+ (* (get-universal-time) 1000000)
			(incf cnt)))))

(defmacro mapf (list args &body body)
  `(mapcar (lambda ,args ,@body) ,list))


(defmacro with-table ((table &rest pairs) &body body)
  (labels ((partition (list)
	     (unless (evenp (length list)) (error "Uneven pair list!"))
	     (values (loop :for i :in list :counting i :into c
			:if (oddp c) :collect i)
		     (loop :for i :in list :counting i :into c
			:if (evenp c) :collect i)))
	   (key-vals (list)
	     (loop :for i :in list :collect `(gethash ,i ,table))))
    (multiple-value-bind (vars keys) (partition pairs)
      `(multiple-value-bind ,vars (values ,@(key-vals keys))
	 ,@body))))


(defmacro instance-from-table ((table class) &body pairs)
  `(make-instance ,class
		  ,@(loop :for e :in pairs :counting e :into c
		       :when (evenp c)
		       :collect (if (listp e)
				    e
				    `(gethash ,e ,table))
		       :else :collect e)))

(defun vec-extend (obj vec)
  (declare (type array vec))
  (let ((buf (make-array (1+ (length vec))
			 :element-type (array-element-type vec))))
    (dotimes (i (length vec)) (setf (aref buf i) (aref vec i)))
    (setf (aref buf (length vec)) obj)
    buf))

(defun mapvec (conversion-fun seq)
  (if seq
      (map 'vector conversion-fun seq)
      #()))

(defun vecrem (predicate seq)
  (delete-if predicate seq :from-end t))

(defun new-hash-table (&rest pairs)
  (let ((table (make-hash-table :test #'equal)))
    (loop :for (key val) :in pairs :do (setf (gethash key table) val))
    table))


(defun xor (one &rest args)
  (if (null args)
      one
      (if one
	  (if (car args)
	      nil
	      (apply #'xor one (cdr args)))
	  (if (car args)
	      (apply #'xor (car args) (cdr args))
	      (apply #'xor one (cdr args))))))

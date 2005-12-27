(in-package #:montezuma)

(defclass term-buffer ()
  ((text-buf)
   (text-length :reader text-length)
   (field :reader field)
   (term :initform nil)))

(defmethod text ((self term-buffer))
  (with-slots (text-buf text-length) self
    (subseq text-buf 0 text-length)))

(defmethod read-term-buffer ((self term-buffer) input field-infos)
  (with-slots (term text-buf text-length field) self
    (setf term nil)
    (let* ((start (read-vint input))
	   (length (read-vint input))
	   (total-length (+ start length)))
      (setf text-length total-length)
      (read-chars input text-buf start length)
      (setf field (field-name (elt field-infos (read-vint input)))))))

(defmethod reset ((self term-buffer))
  (with-slots (field text-buf text-length term) self
    (setf field nil
	  text-buf ""
	  text-length 0
	  term nil)))

(defmethod (setf term) (term (self term-buffer))
  (if (null term)
      (progn (reset self) nil)
      (with-slots (text-buf text-length field) self
	(setf text-buf (copy-seq (term-text term)))
	(setf text-length (length text-buf))
	(setf field (term-field term))
	(setf (slot-value self 'term) term))))
      

(defmethod to-term ((self term-buffer))
  (with-slots (field term text-buf text-length) self
    (if (null field)
	nil
	(if (not (null term))
	    term
	    (setf term (make-term field (subseq text-buf 0 text-length)))))))

(defmethod term ((self term-buffer))
  (to-term self))

(defun term-buffer-compare (tb1 tb2)
  (let ((fc (string-compare (field tb1) (field tb2))))
    (if (= fc 0)
	(string-compare (text tb1) (text tb2))
	fc)))

(defun term-buffer> (tb1 &rest more)
  (if (null more)
      T
      (do ((tbs more (cdr tbs))
	   (previous-tb tb1 (car tbs)))
	  ((endp tbs) T)
	(when (not (> (term-buffer-compare previous-tb (car tbs)) 0))
	  (return NIL)))))

(defun term-buffer< (tb1 &rest more)
  (if (null more)
      T
      (do ((tbs more (cdr tbs))
	   (previous-tb tb1 (car tbs)))
	  ((endp tbs) T)
	(when (not (< (term-buffer-compare previous-tb (car tbs)) 0))
	  (return NIL)))))

(defun term-buffer= (tb1 &rest more)
  (if (null more)
      T
      (do ((tbs more (cdr tbs)))
	  ((endp tbs) T)
	(when (not (= (term-buffer-compare tb1 (car tbs)) 0))
	  (return NIL)))))
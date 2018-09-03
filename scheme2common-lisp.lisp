(defpackage #:scheme2common-lisp
  (:use :cl :utility))

(in-package :scheme2common-lisp)
(setf *print-case* :downcase)

(mapc
 (lambda (x)
   (export (cdr x)))
 '((:export
    alias0
    alias2)
   (:export
    atom?
    symbol?
    pair?
    null?
    eq?
    equal?
    integer?
    for-each
    assq
    reverse!
    remainder
    modulo
    quotient
    assv
    display
    eqv?
    list-ref
    list-tail
    memq
    memv
    newline
    set-car!
    set-cdr!
    vector-ref
    vector-set!
    string-ref
    string-set!
    vector-length
    
    number?
    string?

    list?
    string-append
    number->string
    symbol->string
    
    char->integer
    integer->char
    list->string
    string-length)
   (:export
    pp)
   (:export
    set!
    begin)
   (:export
    named-let
    make-vector
    +true+
    +false+
    letrec
    call/cc
    open-input-file
    close-input-port)))

(defun number->string (number &optional radix)
  ;;radix default to 10, but for some result explicitly
  ;;providing 10 causes a decimal point to appear.
  (write-to-string number :radix radix))

(defun string-append (&rest args)
  (let ((length (reduce #'+ (mapcar #'length args))))
    (let ((new 
	   (make-array length :element-type 'character))
	  (count 0))
      (dolist (item args)
	(dotimes (index (length item))
	  (setf (aref new count)
		(aref item index))
	  (incf count)))
      new)))

(defmacro alias0 (scheme-name cl-name)
  `(eval-always
     (setf (symbol-function ',scheme-name)
	   (function ,cl-name))))

(alias0 pp pprint)

(etouq
  (cons
   'progn
   (mapcar
    (lambda (x) (cons 'alias0 x))
    '((atom? atom)
      (symbol? symbolp)
      (pair? consp)   
      (null? null)
      (eq? eq)
      (equal? equal)
      (integer? integerp)
      (for-each mapc)
      (assq (lambda (item alist) (assoc item alist :test 'eq)))
      (reverse! nreverse)
      (remainder rem)
      (modulo mod)
      (quotient truncate)
      
      ;;(assoc (lambda (item alist) (assoc item alist :test equal)))
      (assv assoc)
      (display princ)
      (eqv? eql)
      (list-ref nth)
      (list-tail nthcdr)
      
      ;;(map mapcar)
      ;;(member (lambda (item list) (member item list :test equal)))
      (memq (lambda (item list) (member item list :test 'eq)))
      (memv member)
      (newline terpri)
      (set-car! rplaca)
      (set-cdr! rplacd)
      (vector-ref aref)
      (vector-set! (lambda (array index value) (setf (aref array index) value)))
      (string-ref aref)
      (string-set! vector-set!)
      (vector-length array-total-size)
      
      ;;(write prin1)

      (number? numberp)
      (string? stringp)

      (list? alexandria:proper-list-p)

      ;;(string-append string-append)
      ;;(number->string number->string)
      (symbol->string (lambda (x)
			(copy-seq (string x))))
      (char->integer char-code)
      (integer->char code-char)

      (list->string (lambda (x)
		     (coerce x 'string)))
      (string-length (lambda (x)
		       (array-total-size x)))))))


(defmacro alias2 (scheme-name cl-name)
  `(defmacro ,scheme-name (&rest rest)
     `(,',cl-name ,@rest)))

(alias2 set! setq)
(alias2 begin progn)

(defun param-names (params)
  (mapcar (lambda (x)
	    (if (symbolp x)
		x
		(first x)))
	  params))

(defmacro named-let (name params &body body)
  (let* ((param-names (param-names params))
	 (rec-param-names (mapcar (lambda (x) (gensym (string x)))
				  param-names)))
    (with-gensyms (start)
      `(let ,params
	 (block exit
	   (tagbody
	      ,start
	      (return-from exit
		(flet ((,name ,rec-param-names
			 (setf (values ,@param-names)
			       (values ,@rec-param-names))
			 (go ,start)))
		  ,@body))))))))

(defun make-vector (length &optional (obj nil))
  (make-array length :initial-element obj))

(defconstant +true+ t)
(defconstant +false+ nil)

(defmacro letrec (bindings &body body)
  (let ((vars (param-names bindings))
	(acc (list (quote progn))))
    (mapc (lambda (binding var)
	    (when (consp binding)
	      (let ((initial-form (cdr binding)))
		(when initial-form
		  (push `(setf ,var ,@initial-form) acc)))))
	  bindings
	  vars)
    `(let ,vars
       ,(nreverse acc)
       ,@body)))

#+nil
(letrec ((a 7)
	 (b (* a a))
	 (c (lambda () (print (list a b)))))
  (funcall c))

(defun call/cc (function)
  (block nil
    (funcall function (lambda (&rest values)
			(return-from nil
			  (apply (function values)
				 values))))))

(defun close-input-port (stream)
  (close stream))

(defun open-input-file (file)
  (open file :direction :input))

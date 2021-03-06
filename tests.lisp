(defpackage :trivial-coerce/tests
  (:use :cl :fiveam :trivial-coerce)
  (:shadowing-import-from :trivial-coerce :coerce))

(in-package :trivial-coerce/tests)

(def-suite :trivial-coerce)
(in-suite :trivial-coerce)

(def-test sequences ()
  (is (equalp '(1 2 3) (coerce #(1 2 3) 'list)))
  (is (equalp #(1 2 3) (coerce '(1 2 3) 'vector)))
  (is (equalp (make-array 3 :initial-contents '(1.0 2.0 3.0)
                            :element-type 'single-float)
              (coerce '(1.0 2.0 3.0) '(vector single-float)))))

(def-test to-character ()
  (is (char= #\A (coerce 'a 'character)))
  (is (char= #\a (coerce "a" 'character)))
  (is (char= #\a (coerce #\a 'character))))

(macrolet ((def-stub (name type)
             (setq type `(complex ,type))
             `(def-test ,name ()
                (is (eql ,(cl:coerce 1 type) (coerce 1 ',type)))
                (is (eql ,(cl:coerce 1.5 type) (coerce 1.5 ',type)))
                (is (eql ,(cl:coerce 3/2 type) (coerce 3/2 ',type))))))
  (def-stub to-complex-single-float single-float)
  (def-stub to-complex-double-float double-float)
  (def-stub to-complex-short-float short-float)
  (def-stub to-complex-long-float long-float))

(macrolet ((def-stub (name type)
             `(def-test ,name ()
                (is (eql ,(cl:coerce 1 type) (coerce 1 ',type)))
                (is (eql ,(cl:coerce 1.5 type) (coerce 1.5 ',type)))
                (is (eql ,(cl:coerce 3/2 type) (coerce 3/2 ',type))))))
  (def-stub to-single-float single-float)
  (def-stub to-double-float double-float)
  (def-stub to-short-float short-float)
  (def-stub to-long-float long-float))

(def-test to-function ()
  (is (eq (fdefinition 'coerce) (coerce 'coerce 'function)))
  (is (functionp (coerce '(lambda ()) 'function)))
  (signals type-error (coerce '(progn (lambda ())) 'function)))

(def-test to-string ()
  (is (string= "A" (coerce 'a 'string)))
  (is (string= "a" (coerce #\a 'string)))
  (is (string= "55" (coerce 55 'string)))
  (is (string= "hello" (coerce "hello" 'string))))

(def-test define-and-undefine ()
  (with-output-to-string (*error-output*)

    (mapcar #'fmakunbound '(b1-p b2-p))

    (eval `(progn
             (defstruct (a1))
             (defstruct (a2 (:include a1)))
             (defstruct (b1))
             (defstruct (b2 (:include b1)))))

    (eval `(define-coercion (obj :from a2 :to b2) (make-b2)))
    (is (b2-p (coerce (make-a2) 'b2)))
    (signals type-error (coerce (make-a1) 'b2))
    (eval `(undefine-coercion 'a2 'b2))

    (eval `(define-coercion (obj :from a1 :to b2) (make-b2)))
    (is (b2-p (coerce (make-a1) 'b2)))
    (is (b2-p (coerce (make-a2) 'b2)))
    (is (b2-p (coerce (make-a2) 'b1)))
    (is (b2-p (coerce (make-a1) 'b1)))
    (eval `(undefine-coercion 'a1 'b2))

    (eval `(define-coercion (obj :from a1 :to b1) (make-b1)))
    ;; No guarantees will be provided for conflicting cases; after all, both do return B2
    ;; (eval `(define-coercion (obj :from a2 :to b1) (make-b2)))
    (is (b1-p (coerce (make-a1) 'b1)))
    (is (b1-p (coerce (make-a2) 'b1)))
    (signals type-error (coerce (make-a1) 'b2))
    (signals type-error (coerce (make-a2) 'b2))
    (eval `(undefine-coercion 'a1 'b1))

    (mapcar #'unintern '(a1 a2 b1 b2))
    (mapcar #'fmakunbound '(b1-p b2-p))))


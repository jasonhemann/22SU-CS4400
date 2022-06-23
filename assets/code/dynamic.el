;; e-lisp example
(let ((a 5))
  (let ((whats-a? (lambda (b) (+ a b))))
    (let ((a 120))
      (funcall whats-a? 3))))
      
;; funcall just means call
;; the function


















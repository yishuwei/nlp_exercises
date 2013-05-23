#lang mzscheme
(provide (all-defined))


(define (identity x) x)

(define (curry f . xs)
  (lambda ys
    (apply f (append xs ys))))

(define is? (curry curry eqv?))

(define (compose f . gs)
  (if (null? gs)
      f
      (lambda xs 
        (f (apply (apply compose gs) xs)))))

(define (f-not f)
  (compose not f))

(define (fold-right f s lst)
  (if (null? lst)
      s
      (f (car lst) (fold-right f s (cdr lst)))))

(define (fold-left f t lst)
  (if (null? lst)
      t
      (fold-left f (f t (car lst)) (cdr lst))))

(define (fold-left-stop f stop? t lst)
  (if (or (null? lst) (stop? t))
      t
      (fold-left-stop f  stop? (f t (car lst)) (cdr lst))))

(define (find pred lst)
  (fold-left-stop (lambda (x y) 
                    (if (pred y) y #f))
                  identity #f lst))

(define (filter pred lst)
  (fold-right (lambda (x m)
                (if (pred x)
                    (cons x m)
                    m))
              '() lst))

(define (intersperse obj lst)
  (if (null? (cdr lst))
      lst
      (cons (car lst) (cons obj (intersperse obj (cdr lst))))))
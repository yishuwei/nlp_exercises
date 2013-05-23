#lang mzscheme
(require "generator.scm")

;; a simple grammar
;; try (simp-print-fun (expand 'exp simpgram 10))
(define simpexp (make-simp-rule 'exp '("(" exp + exp ")" ) '("(" exp * exp ")") '(variable) '(number)))
(define simpvar (make-simp-rule 'variable  '(x) '(y) '(z) '(a) '(b) '(c)))
(define simpnum (make-simp-rule 'number '(posnumber) '("(" "-" posnumber ")")))
(define simpposnum (make-simp-rule 'posnumber '(digit) '( "(" 10 * posnumber + digit ")")))
(define simpdig (make-simp-rule 'digit '(0) '(1) '(2) '(3) '(4) '(5) '(6) '(7) '(8) '(9)))
(define simpgram (list simpexp simpposnum simpvar simpnum simpdig))
(define simp-print-fun (make-master-print-fun simpgram))

;; unweighted version
;; (unweighted-print-fun (expand 'exp unweightedgram 0)) will print a string with potentially unbounded length
(define unweightedexp (make-unweighted-rule 'exp '("(" exp + exp ")" ) '("(" exp * exp ")") '(variable) '(number)))
(define unweightedvar (make-unweighted-rule 'variable  '(x) '(y) '(z) '(a) '(b) '(c)))
(define unweightednum (make-unweighted-rule 'number '(posnumber) '("(" "-" posnumber ")")))
(define unweightedposnum (make-unweighted-rule 'posnumber '(digit) '( "(" 10 * posnumber + digit ")")))
(define unweighteddig (make-unweighted-rule 'digit '(0) '(1) '(2) '(3) '(4) '(5) '(6) '(7) '(8) '(9)))
(define unweightedgram (list unweightedexp unweightedposnum unweightedvar unweightednum unweighteddig))
(define unweighted-print-fun (make-master-print-fun unweightedgram))



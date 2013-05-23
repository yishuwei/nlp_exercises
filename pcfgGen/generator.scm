#lang mzscheme
(require "util.scm")
(provide (all-defined))

;; useful functions
(define (cumulative-sum lst)
  (if (null? lst)
      '()
      (cons (car lst) (map (curry + (car lst)) (cumulative-sum (cdr lst))))))

(define (pair-up lst1 lst2)
  (if (or (null? lst1) (null? lst2))
      '()
      (cons (cons (car lst1) (car lst2)) (pair-up (cdr lst1) (cdr lst2)))))


;; an expansion represents a way to expand a node in the derivation tree
;; expansions are of the form ('expansion prob weight exp)
;; prob is a probability factor, which is proportional to the probability that this expansion would appear
;; weight is a number, indicating how 'big' the node is
;; exp is a list of symbols, corresponding to the children of the node in this particular expansion
(define (make-expansion prob weight exp)
  (list 'expansion prob weight exp))
(define expansion-prob cadr)
(define expansion-weight caddr)
(define expansion-exp cadddr)
(define expansion? (compose (curry eq? 'expansion) car))
(define (expansion-update-prob exp prob) (make-expansion prob (expansion-weight exp) (expansion-exp exp)))
(define (expansion-update-weight exp weight) (make-expansion (expansion-prob exp) weight (expansion-exp exp)))
(define (expansion-update-exp exp newexp) (make-expansion (expansion-prob exp) (expansion-weight exp) newexp))


;; a rule specifies all ways a symbol can be expanded
;; rules are of the form ('rule symbol print-fun expansions)
;; print-fun takes two arguments, a master-print-fun that works on all expansions and a expanded tree, and returns a string
(define (make-rule symbol print-fun . expansions)
  (list 'rule symbol print-fun expansions))
(define rule-symbol cadr)
(define rule-printfun caddr)
(define rule-expansions cadddr)


;; below are the steps leading to the expand function
;; the usage of the expand function is (expand symbol grammar weight)
;; grammar is a list of rules, weight is a number
;; it will expand the symbol according to the given grammar
;; and the total weight of the expansion shall not exceed the given weight
(define (find-rule symbol grammar)
  (find (compose (is? symbol) rule-symbol) grammar))

(define (expand-candidates symbol grammar)
  (rule-expansions (find-rule symbol grammar)))

(define (filtered-expansion-candidates symbol grammar weight)
  (filter (compose (curry >= weight) expansion-weight) (expand-candidates symbol grammar)))

(define (select-proportional-to-prob expansions)
  (let ((u (* (random) (fold-left + 0 (map expansion-prob expansions))))
        (expansion-pairs (pair-up expansions (cumulative-sum (map expansion-prob expansions)))))
    (caar (filter (compose (curry < u) cdr) expansion-pairs))))

(define (expand symbol grammar weight)
  (if ((f-not find-rule) symbol grammar)
      symbol
      (let ((selected-expansion (select-proportional-to-prob (filtered-expansion-candidates symbol grammar weight))))
        (cons symbol (map (lambda (sym)
                                  (expand sym grammar (- weight (expansion-weight selected-expansion))))
                          (expansion-exp selected-expansion))))))


;; this is the master print function builder
;; the usage is (make-master-print-fun grammar)
;; this will build the master print function for the given grammar, which shall be applied to any fully expanded tree
(define (make-master-print-fun grammar)
  (define master-print-fun
    (lambda (expanded-lst)
      (let ((print-fun (rule-printfun (find-rule (car expanded-lst) grammar))))
        (print-fun master-print-fun (cdr expanded-lst)))))
  master-print-fun)


;; here are two shortcuts to build rules

;; simple grammar builder
;; every expansion has probability factor 1, and weight equal to the number of children minus 1
;; every rule uses the default print function
(define (make-simp-expansion exp) (make-expansion 1 (- (length exp) 1) exp))
(define (make-simp-rule symbol . exp-lists) 
  (apply (curry make-rule symbol default-print-fun) (map make-simp-expansion exp-lists)))
;; unweighted grammar builder
;; every expansion has probability factor 1 and weight 0
;; every rule uses the default print function
(define (make-unweighted-expansion exp) (make-expansion 1 0 exp))
(define (make-unweighted-rule symbol . exp-lists)
  (apply (curry make-rule symbol default-print-fun) (map make-unweighted-expansion exp-lists)))
;; the default print function is defined as follows
(define (default-print-fun master-print-fun term)
  (apply string-append (intersperse " " 
                                    (map (lambda (t)
                                           (cond ((list? t) (master-print-fun t))
                                                 ((symbol? t) (symbol->string t))
                                                 ((number? t) (number->string t))
                                                 ((string? t) t))) term))))

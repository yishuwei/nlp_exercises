#lang mzscheme
(require "generator.scm")
(require "util.scm")

;;first we need the grammar for formula
;;try (prop-print-fun (expand 'formula propgram 10)) to see how formulas are built
(define (formula-print master-print-fun term)
  (apply string-append (map (lambda (t)
                              (cond ((list? t) (master-print-fun t))
                                    ((symbol? t) (symbol->string t))
                                    ((string? t) t))) term)))
(define propform (make-rule 'formula formula-print 
                            (make-simp-expansion '(atom)) (make-simp-expansion '("(" formula "->" formula ")"))
                            (make-simp-expansion '("(" formula "&" formula ")"))
                            (make-simp-expansion '("(" formula "|" formula ")"))))
(define propatom (make-simp-rule 'atom '(p) '(q) '(r)))

(define propgram (list propform propatom))
(define prop-print-fun (make-master-print-fun propgram))


;;here are two auxiliary functions
(define (makeconj formula1 formula2)
  (append '(formula "(") (cdr formula1) '("&") (cdr formula2) '(")")))
(define (makedisj formula1 formula2)
  (append '(formula "(") (cdr formula1) '("|") (cdr formula2) '(")")))
(define (makeimpl formula1 formula2)
  (append '(formula "(") (cdr formula1) '("->") (cdr formula2) '(")")))


;;now the full proof system
(define proofpf (make-rule 'proof default-print-fun
                           (make-simp-expansion '(axiom))
                           (make-expansion 1 1 '(mp))
                           (make-expansion 1 1 '(conj))
                           (make-expansion 1 1 '(disj))))

;;often it is useful to know what is proved
;;this takes a fully expanded proof and returns a formula
(define (get-what-is-proved proof)
  (let ((pfbody (cadr proof)))
    (cond (((is? 'axiom) (car pfbody)) (cadr pfbody))
          (((is? 'mp) (car pfbody)) (cadr pfbody))
          (((is? 'conj) (car pfbody)) (makeconj (get-what-is-proved (cadr pfbody)) (get-what-is-proved (caddr pfbody))))
          (((is? 'disj) (car pfbody)) (makedisj (get-what-is-proved (cadr pfbody)) (caddr pfbody))))))

;;we need to define the print functions for the inference rules
(define (axiom-print master-print-fun lst)
  (let ((axiombody (car lst)))
    (string-append "[" (master-print-fun axiombody) "]")))
(define (mp-print master-print-fun lst)
  (let ((consequence (car lst))
        (proof-of-antecedent (cadr lst)))
    (string-append "[" (master-print-fun (makeimpl (get-what-is-proved proof-of-antecedent) consequence)) "] "
                   (master-print-fun proof-of-antecedent) " " (master-print-fun consequence))))
(define (conj-print master-print-fun lst)
  (let ((subproof1 (car lst))
        (subproof2 (cadr lst)))
    (string-append (master-print-fun subproof1) " " (master-print-fun subproof2) " "
                   (master-print-fun (makeconj (get-what-is-proved subproof1) (get-what-is-proved subproof2))))))
(define (disj-print master-print-fun lst)
  (let ((subproof (car lst))
        (append (cadr lst)))
    (string-append (master-print-fun subproof) " " (master-print-fun (makedisj (get-what-is-proved subproof) append)))))

;;time to put everything together
(define proofax (make-rule 'axiom axiom-print (make-simp-expansion '(formula))))
(define proofmp (make-rule 'mp mp-print (make-simp-expansion '(formula proof))))
(define proofconj (make-rule 'conj conj-print (make-simp-expansion '(proof proof))))
(define proofdisj (make-rule 'disj disj-print (make-simp-expansion '(proof formula))))
(define proofgram (list propform propatom proofpf proofax proofmp proofconj proofdisj))
(define proof-print-fun (make-master-print-fun proofgram))

;;try (proof-print-fun (expand 'proof proofgram 10)) and you will see a proof!!
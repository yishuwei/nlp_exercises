#lang mzscheme
(require "generator.scm")

;; a very very simple (and slightly incorrect) English example
;; try (Eng-print-fun (expand 'sentence Enggram 10))
(define Eng-proper-noun (make-simp-rule 'proper-noun '(Sarah) '(Joseph) '(Ke$ha) '(Lil Jon) '(Stewart Macgreggor Dennis) '(Alix) '(Steven Michael Crane) '(Julie Zelenski) 
                                            '(D Pitty) '(Peter) '(Fransexgo aka DJ Buttsex) '(Synergy) '(Chewey) '(Hobart) '(Frank-LOOONG)))
(define Eng-noun (make-simp-rule 'noun '(animal) '(tree) '(dog) '(coboundry) '(frog) '(leaf) '(dove) '(region) '(television) '(pylon) '(explosion) '(love) '(guitar) '(panda) '(butt-rat) '(knife) '(elephant) '(enigma) '(sentance-generator)))
(define Eng-noun-clause (make-simp-rule 'noun-clause '(a adjective-list noun) '(the adjective-list noun) '(proper-noun) '(possessive-noun-clause adjective-list noun)))
(define Eng-possessive-noun-clause (make-simp-rule 'possessive-noun-clause '(noun-clause "'s")))
(define Eng-adjective (make-simp-rule 'adjective '(cool) '(sexy) '(explosive) '(electric) '(smart) '(sad) '(meaty) '(big)))
(define Eng-adjective-list (make-simp-rule 'adjective-list '("") '(adjective) '(adjective-list1)))
(define Eng-adjective-list1 (make-simp-rule 'adjective-list1 '(adjective "," adjective-list1) '(adjective and adjective)))
(define Eng-transverb (make-simp-rule 'transverb '(eats) '(growls) '(shows) '(smashes) '(licks) '(destroys) '(annoys)))
(define Eng-preposition (make-simp-rule 'preposition '(on) '(above) '(below)))
(define Eng-transverb-clause (make-simp-rule 'transverb-clause '(transverb) '(transverb preposition)))
(define Eng-sentence (make-simp-rule 'sentence '(noun-clause transverb-clause noun-clause)))
(define Enggram (list Eng-sentence Eng-transverb-clause Eng-transverb Eng-preposition Eng-adjective-list1 Eng-adjective-list Eng-noun-clause Eng-noun Eng-proper-noun Eng-adjective Eng-possessive-noun-clause))
(define Eng-print-fun (make-master-print-fun Enggram))
import NatLog

s1 = SENT (SUBJ2 Most (NP1 Man)) (PRED1 (VP2 Didn't Move))
s2 = SENT (SUBJ2 Some (NP1 Mammal)) (PRED1 (VP2 Didn't Dance))

s3 = SENT (SUBJ1 Mary) (PRED2 IsA (NP2 Old Woman))
s4 = SENT (SUBJ1 Mary) (PRED2 IsA (NP1 Person))

s3' = SENT (SUBJ1 Buffy) (PRED2 IsA (NP2 Old Dog))
s4' = SENT (SUBJ1 Buffy) (PRED2 IsA (NP1 Person))

s5 = SENT (SUBJ2 Some (NP3 Person That (VP3 Slept And Danced))) 
          (PRED3 Is (ADJP1 Bald))
s6 = SENT (SUBJ2 Some (NP3 Person That (VP1 Moved))) (PRED3 Is (ADJP1 Bald))

s7 = SENT (SUBJ2 (AtLeast 2) (NP2 Married Woman)) (PRED1 (VP5 Danced Slowly))
s8 = SENT (SUBJ2 Some (NP2 Married Person)) (PRED1 (VP1 Moved))

s9 = SENT (SUBJ2 Most (NP2 Old Man)) (PRED3 Is (ADJP3 Bald And Married))
s10 = SENT (SUBJ2 Some (NP1 Person)) (PRED3 Is (ADJP4 Married Or Blind))

s11 = SENT (SUBJ2 Every (NP1 Person)) (PRED1 (VP3 Danced And Smoked))
s12 = SENT (SUBJ2 Every (NP3 Woman That (VP2 Didn't Sleep))) (PRED1 (VP1 Moved))

s13 = SENT (SUBJ1 Mary) (PRED1 (VP6 Slept (PP2 With Some Man)))
s14 = SENT (SUBJ1 Mary) (PRED1 (VP6 Slept (PP2 With Some Mammal)))

s15 = SENT (SUBJ1 Daniel) (PRED1 (VP6 Danced (PP1 Without Pants)))
s16 = SENT (SUBJ1 Daniel) (PRED1 (VP6 Danced (PP1 Without Jeans)))

s17 = SENT (SUBJ2 No (NP3 Mammal That (VP4 Moved Or Slept))) (PRED3 Is (ADJP2 Not Blind))
s18 = SENT (SUBJ2 (AtMost 3) (NP3 Person That (VP3 Smoked And Danced))) 
           (PRED3 Is (ADJP2 Not Handicapped))
s19 = SENT (SUBJ2 (AtMost 3) (NP3 Person That (VP4 Smoked Or Danced))) (PRED3 Is (ADJP2 Not Blind))


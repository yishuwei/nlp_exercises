-- This Haskell program comes from Jan van Eijck's 2005 paper
-- "Natural Logic for Natural Language" with modifications and extensions

module NatLog where
import Data.List

data Entity = J | M | D | E | P | B
     deriving (Show, Eq,Bounded,Enum)

entities :: [Entity]
entities = [minBound..maxBound]


setOf ::  (Entity -> Bool) -> [Entity]
setOf p = (filter p entities)

showEntityList :: [Entity] -> String
showEntityList [] = "{}"
showEntityList (x:xs) = "{" ++ show x ++ showEntityListTail xs

showEntityListTail :: [Entity] -> String
showEntityListTail [] = "}"
showEntityListTail (x:xs) = "," ++ show x ++ showEntityListTail xs

showSet :: (Entity -> Bool) -> String
showSet p = showEntityList (setOf p)

infix 1 ==>, <==

class Eq a => Pord a where
   (==>) :: a -> a -> Bool
   (<==) :: a -> a -> Bool
   -- minimal complete definition: (==>)
   (<==) = flip (==>)

instance Pord Entity where
   (==>) = (==)

instance Pord Bool where
   x ==> y = x <= y

instance (Show a, Bounded a, Enum a, Show b) => Show (a -> b) where
  show f = show [(x,f x) | x <- [minBound..maxBound] ]

instance Bounded b => Bounded (a -> b) where
  minBound = \ x -> minBound
  maxBound = \ x -> maxBound

instance (Bounded a, Enum a, Eq b) => Eq (a -> b) where
  f == g = all (\ (x,y) -> x == y) (zip fvalues gvalues)
    where fvalues = map f [minBound..maxBound]
          gvalues = map g [minBound..maxBound]

graph :: (Eq a, Bounded a, Enum a, Eq b, Bounded b, Enum b) =>
          a -> b -> Int -> [(a,b)]
graph z dummy n =
  if z == minBound then [(z,toEnum n)]
  else ((z,toEnum q)) : graph (pred z) dummy r
   where
     cod = if dummy == maxBound then [minBound ..dummy]
           else [minBound..dummy]++[succ dummy..maxBound]
     b   = length cod
     p   = fromEnum z
     q   = quot n (b^p)
     r   = rem n (b^p)

instance (Eq a, Bounded a, Enum a, Eq b, Bounded b, Enum b) => Enum (a -> b)
  where
    toEnum n x = case lookup x (graph maxBound minBound n) of
      Just y -> y
      Nothing -> error "lookup failure"

    fromEnum f  = encBase b ns
      where xs  = [ f x | x <- [minBound..maxBound] ]
            ns  = map fromEnum xs
            y   = f minBound -- dummy value to compute the codomain
            cod = if y == maxBound then [minBound..y]
                  else [minBound..y]++[succ y..maxBound]
            b   = length cod
            encBase :: Int -> [Int] -> Int
            encBase b [] = 0
            encBase b (x:xs) = (x * b^m) + (encBase b xs)
               where m = length xs

instance (Eq a, Bounded a, Enum a, Pord a, Eq b, Pord b) => Pord (a -> b)
  where
    f ==> g = all (\ (x,y) -> x ==> y) (zip fvalues gvalues)
       where fvalues = map f [minBound..maxBound]
             gvalues = map g [minBound..maxBound]

data Direction = Up | Down | None deriving (Eq,Show)

mon :: (Enum a, Bounded a, Pord a, Pord b) => (a -> b) -> Direction
mon f | all (uncurry (==>)) fxs = Up
      | all (uncurry (<==)) fxs = Down
      | otherwise               = None
   where pairs = [(u,v) | u <- [minBound..maxBound],
                          v <- [minBound..maxBound] ]
         leqxs = filter (uncurry (==>)) pairs
         fxs   = map (\ (u,v) -> (f u, f v)) leqxs

conj, disj :: (a -> Bool) -> (a -> Bool) -> (a -> Bool)   -- Set intersection, union
conj p q = \ x -> p x && q x
disj p q = \ x -> p x || q x


every :: (Entity -> Bool) -> (Entity -> Bool) -> Bool
every p q = all q (filter p entities)

some :: (Entity -> Bool) -> (Entity -> Bool) -> Bool
some p q = any q (filter p entities)

no :: (Entity -> Bool) -> (Entity -> Bool) -> Bool
no p = not . some p

most :: (Entity -> Bool) -> (Entity -> Bool) -> Bool
most p q = psqs > psnqs
  where psqs  = length (filter (conj p q) entities)
        psnqs = length (filter (conj p (not . q))  entities)

atleast :: Int -> (Entity -> Bool) -> (Entity -> Bool) -> Bool
atleast n p q = psqs >= n
  where psqs  = length (filter (conj p q) entities)

atmost :: Int -> (Entity -> Bool) -> (Entity -> Bool) -> Bool
atmost n p q = psqs <= n
  where psqs  = length (filter (conj p q) entities)


john, mary, daniel, emily, peter, buffy ::  (Entity -> Bool) -> Bool  -- Sets of sets
john =  \p -> p J
mary =  \p -> p M
daniel = \p -> p D
emily = \p -> p E
peter = \p -> p P
buffy = \p -> p B

blind, handicapped, man, bald, dog, woman, old, person, married, female, dance, move, sleep, smoke, mammal :: (Entity -> Bool) -- Sets
blind   = \x -> elem x []
handicapped  = \x -> elem x [P]
man     = \x -> elem x [J,D,P]
bald    = \x -> elem x [J,P]
dog     = \x -> elem x [B]
woman   = \x -> elem x [E,M]
old     = \x -> elem x [J,B]
person  = \x -> elem x [J,M,D,E,P]
married = \x -> elem x [J,M]
female  = \x -> elem x [B,M,E]
dance = \x -> elem x [D,E]
move = \x -> elem x [D,E,B]
sleep = \x -> elem x [P]
smoke = \x -> elem x [J,D]
mammal  = \x -> elem x [J,M,D,E,P,B]



data SENT = SENT SUBJ PRED
     deriving (Eq,Show)
data SUBJ = SUBJ1 N | SUBJ2 DET NP
     deriving (Eq,Show)
data PRED = PRED1 VP | PRED2 ISA NP | PRED3 IS ADJP
     deriving (Eq,Show)
data VP = VP1 V | VP2 DIDNT INF | VP3 V CONJ V | VP4 V DISJ V | VP5 V ADV | VP6 V PP
     deriving (Eq,Show)
data ADJP = ADJP1 ADJ | ADJP2 NOT ADJ | ADJP3 ADJ CONJ ADJ | ADJP4 ADJ DISJ ADJ
     deriving (Eq,Show)
data NP = NP1 CN | NP2 ADJ CN | NP3 CN REL VP
     deriving (Eq,Show)
data PP = PP1 PREP CNS | PP2 PREP DET CN
     deriving (Eq,Show)
data DET = Every | Some | Most | No | The | AtLeast Int | AtMost Int
     deriving (Eq,Show)
data CN = Man | Woman | Dog | Person | Mammal
     deriving (Eq,Show)
data CNS = Pants | Jeans
     deriving (Eq,Show)
data V = Danced | Moved | Slept | Smoked
     deriving (Eq,Show)
data INF = Dance | Move | Sleep | Smoke
     deriving (Eq,Show)
data ADJ = Blind | Handicapped | Bald | Old | Married | Female
     deriving (Eq,Show)
data N = John | Mary | Daniel | Emily | Peter | Buffy
     deriving (Eq,Show)
data PREP = With | Without
     deriving (Eq,Show)
data ADV = Slowly
     deriving (Eq,Show)
data NOT = Not
     deriving (Eq,Show)
data DIDNT = Didn't
     deriving (Eq,Show)
data CONJ = And
     deriving (Eq,Show)
data DISJ = Or
     deriving (Eq,Show)
data ISA = IsA
     deriving (Eq,Show)
data IS = Is
     deriving (Eq,Show)
data REL = That
     deriving (Eq,Show)
     
class PredType a where
   denot :: a -> (Entity -> Bool)

instance PredType CN where
   denot Man = man
   denot Woman = woman
   denot Dog = dog
   denot Person = person
   denot Mammal = mammal

instance PredType V where
   denot Danced = dance
   denot Moved = move
   denot Slept = sleep
   denot Smoked = smoke

instance PredType INF where
   denot Dance = dance
   denot Move = move
   denot Sleep = sleep
   denot Smoke = smoke

instance PredType ADJ where
   denot Blind = blind
   denot Handicapped = handicapped
   denot Bald = bald
   denot Old = old
   denot Married = married
   denot Female = female

instance PredType VP where
   denot (VP1 v) = denot v
   denot (VP2 didnt v) = not . (denot v)
   denot (VP3 v1 cnj v2) = conj (denot v1) (denot v2)
   denot (VP4 v1 dsj v2) = disj (denot v1) (denot v2)
   denot _ = minBound

instance PredType ADJP where
   denot (ADJP1 adj) = denot adj
   denot (ADJP2 nt adj) = not . (denot adj)
   denot (ADJP3 adj1 cnj adj2) = conj (denot adj1) (denot adj2)
   denot (ADJP4 adj1 dsj adj2) = disj (denot adj1) (denot adj2)

instance PredType NP where
   denot (NP1 cn) = denot cn
   denot (NP2 adj cn) = conj (denot adj) (denot cn)
   denot (NP3 cn _ vp) = conj (denot cn) (denot vp)

denotN :: N -> (Entity -> Bool) -> Bool
denotN John = john
denotN Mary = mary
denotN Daniel = daniel
denotN Emily = emily
denotN Peter = peter
denotN Buffy = buffy

denotDET :: DET -> (Entity -> Bool) -> (Entity -> Bool) -> Bool
denotDET Every = every
denotDET Some = some
denotDET Most = most
denotDET No = no
denotDET The = minBound
denotDET (AtLeast i) = atleast i
denotDET (AtMost i) = atmost i

data Marking = Plus | Minus | Npol deriving Eq
instance Show Marking where
  show Plus  = "+"
  show Minus = "-"
  show Npol  = "0"

rv, br :: Marking -> Marking
rv Plus  = Minus
rv Minus = Plus
rv Npol  = Npol
br _ = Npol

monDET :: DET -> [Marking -> Marking]
monDET Every = [rv, id]
monDET Some  = [id, id]
monDET Most  = [br, id]
monDET No    = [rv, rv]
monDET The   = [br, id]
monDET (AtLeast _) =  [id, id]
monDET (AtMost _) =  [rv, rv]

monSUBJ :: SUBJ -> [Marking -> Marking]
monSUBJ (SUBJ1 n) = [id]
monSUBJ (SUBJ2 det np) = tail (monDET det)

monPREP :: PREP -> [Marking -> Marking]
monPREP With = [id]
monPREP Without = [rv]

data Tree a = Leaf a | Node1 a (Tree a) | Node2 a (Tree a) (Tree a) | Node3 a (Tree a) (Tree a) (Tree a)
     deriving (Eq,Ord,Show)

infix 1 -->, <--

class Eq a => SynStruct a where
   mark :: a -> Marking -> Tree Marking
   impl :: a -> a -> Marking -> Bool
   (-->) :: a -> a -> Bool
   (<--) :: a -> a -> Bool
   -- minimal complete definition
   mark _ m = Leaf m
   x --> y = x == y
   (<--) = flip (-->)
   impl x y Plus = x --> y
   impl x y Minus = x <-- y
   impl x y Npol = x == y

instance SynStruct SENT where
   mark (SENT subj pred) m = Node2 m (mark subj m) (mark pred m')
     where m' = head (monSUBJ subj) m
   impl (SENT subj1 pred1) (SENT subj2 pred2) m = (impl subj1 subj2 m) && (impl pred1 pred2 m')
     where m' = head (monSUBJ subj2) m
   x --> y = impl x y Plus

instance SynStruct SUBJ where
   mark (SUBJ1 n) m = (Leaf m)
   mark (SUBJ2 det np) m = Node2 m (mark det m) (mark np m')
     where m' = head (monDET det) m
   impl (SUBJ2 det1 np1) (SUBJ2 det2 np2) m = (impl det1 det2 m) && (impl np1 np2 m')
     where m' = head (monDET det2) m
   impl x y _ = x == y
   x --> y = impl x y Plus

instance SynStruct PRED where
   mark (PRED1 vp) m = Node1 m (mark vp m)
   mark (PRED2 _ np) m = Node1 m (mark np m)
   mark (PRED3 _ adjp) m = Node1 m (mark adjp m)
   (PRED1 vp1) --> (PRED1 vp2) = vp1 --> vp2
   (PRED2 _ np1) --> (PRED2 _ np2) = np1 --> np2
   (PRED3 _ adjp1) --> (PRED3 _ adjp2) = adjp1 --> adjp2
   x --> y = False

instance SynStruct VP where
   mark (VP1 v) m = Node1 m (mark v m)
   mark (VP2 didnt v) m = Node2 m (mark didnt m) (mark v (rv m))
   mark (VP3 v1 cnj v2) m = Node3 m (mark v1 m) (mark cnj m) (mark v2 m)
   mark (VP4 v1 dsj v2) m = Node3 m (mark v1 m) (mark dsj m) (mark v2 m)
   mark (VP5 v adv) m = Node2 m (mark v m) (mark adv m)
   mark (VP6 v pp) m = Node2 m (mark v m) (mark pp m)
   (VP1 v1) --> (VP1 v2) = v1 --> v2
   (VP2 didnt1 v1) --> (VP2 didnt2 v2) = v1 <-- v2
   (VP3 v1 cnj1 v2) --> (VP3 v3 cnj2 v4) = ((v1 --> v3) && (v2 --> v4)) || ((v1 --> v4) && (v2 --> v3))
   (VP4 v1 dsj1 v2) --> (VP4 v3 dsj2 v4) = ((v1 --> v3) && (v2 --> v4)) || ((v1 --> v4) && (v2 --> v3))
   (VP5 v1 adv1) --> (VP5 v2 adv2) = (v1 --> v2) && (adv1 --> adv2)
   (VP6 v1 pp1) --> (VP6 v2 pp2) = (v1 --> v2) && (pp1 --> pp2)
   (VP3 v1 cnj v2) --> (VP1 v3) = (v1 --> v3) || (v2 --> v3)
   (VP5 v1 adv) --> (VP1 v2) = v1 --> v2
   (VP6 v1 pp) --> (VP1 v2) = v1 --> v2
   (VP1 v1) --> (VP4 v2 dsj v3) = (v1 --> v2) || (v1 --> v3)
   (VP3 v1 cnj v2) --> (VP4 v3 dsj v4) = (v1 --> v3) || (v1 --> v4) || (v2 --> v3) || (v2 --> v4)
   (VP5 v1 adv) --> (VP4 v2 dsj v3) = (v1 --> v2) || (v1 --> v3)
   (VP6 v1 pp) --> (VP4 v2 dsj v3) = (v1 --> v2) || (v1 --> v3)
   x --> y = False

instance SynStruct ADJP where
   mark (ADJP1 adj) m = Node1 m (mark adj m)
   mark (ADJP2 nt adj) m = Node2 m (mark nt m) (mark adj (rv m))
   mark (ADJP3 adj1 cnj adj2) m = Node3 m (mark adj1 m) (mark cnj m) (mark adj2 m)
   mark (ADJP4 adj1 dsj adj2) m = Node3 m (mark adj1 m) (mark dsj m) (mark adj2 m)
   (ADJP1 adj1) --> (ADJP1 adj2) = adj1 --> adj2
   (ADJP2 nt1 adj1) --> (ADJP2 nt2 adj2) = adj1 <-- adj2
   (ADJP3 adj1 cnj1 adj2) --> (ADJP3 adj3 cnj2 adj4) = ((adj1 --> adj3) && (adj2 --> adj4)) || ((adj1 --> adj4) && (adj2 --> adj3))
   (ADJP4 adj1 dsj1 adj2) --> (ADJP4 adj3 dsj2 adj4) = ((adj1 --> adj3) && (adj2 --> adj4)) || ((adj1 --> adj4) && (adj2 --> adj3))
   (ADJP3 adj1 cnj adj2) --> (ADJP1 adj3) = (adj1 --> adj3) || (adj2 --> adj3)
   (ADJP1 adj1) --> (ADJP4 adj2 dsj adj3) = (adj1 --> adj2) || (adj1 --> adj3)
   (ADJP3 adj1 cnj adj2) --> (ADJP4 adj3 dsj adj4) = (adj1 --> adj3) || (adj1 --> adj4) || (adj2 --> adj3) || (adj2 --> adj4)
   x --> y = False

instance SynStruct NP where
   mark (NP1 cn) m = Node1 m (mark cn m)
   mark (NP2 adj cn) m = Node2 m (mark adj m) (mark cn m)
   mark (NP3 cn _ vp) m = Node2 m (mark cn m) (mark vp m)
   (NP1 cn1) --> (NP1 cn2) = cn1 --> cn2
   (NP2 adj1 cn1) --> (NP2 adj2 cn2) = (adj1 --> adj2) && (cn1 --> cn2)
   (NP3 cn1 _ vp1) --> (NP3 cn2 _ vp2) = (cn1 --> cn2) && (vp1 --> vp2)
   (NP2 adj cn1) --> (NP1 cn2) = cn1 --> cn2
   (NP3 cn1 _ vp) --> (NP1 cn2) = cn1 --> cn2
   x --> y = False

instance SynStruct PP where
   mark (PP1 prep cns) m = Node2 m (mark prep m) (mark cns m')
     where m' = head (monPREP prep) m
   mark (PP2 prep det cn) m = Node3 m (mark prep m) (mark det m') (mark cn m'')
     where m' = head (monPREP prep) m
           m'' = head (monDET det) m'
   impl (PP1 prep1 cns1) (PP1 prep2 cns2) m = (impl prep1 prep2 m) && (impl cns1 cns2 m')
     where m' = head (monPREP prep2) m
   impl (PP2 prep1 det1 cn1) (PP2 prep2 det2 cn2) m = (impl prep1 prep2 m) && (impl det1 det2 m') && (impl cn1 cn2 m'')
     where m' = head (monPREP prep2) m
           m'' = head (monDET det2) m'
   impl x y _ = x == y
   x --> y = impl x y Plus

instance SynStruct DET where -- do not assume existential import
   Most --> Some = True
   Most --> (AtLeast 1) = True
   Some --> (AtLeast 1) = True
   (AtLeast i) --> Some = True
   No --> (AtMost i) = True
   The --> Some = True
   The --> (AtLeast 1) = True
   (AtLeast i) --> (AtLeast j) = i > j
   (AtMost i) --> (AtMost j) = i < j
   x --> y = x == y
instance SynStruct V where
   Danced --> Moved = True
   x --> y = x == y
instance SynStruct INF where
   Dance --> Move = True
   x --> y = x == y
instance SynStruct CN where
   Man --> Person = True
   Woman --> Person = True
   Man --> Mammal = True
   Woman --> Mammal = True
   Dog --> Mammal = True
   Person --> Mammal = True
   x --> y = x == y
instance SynStruct CNS where
   Jeans --> Pants= True
   x --> y = x == y
instance SynStruct ADJ where
   Blind --> Handicapped = True
   x --> y = x == y
instance SynStruct N
instance SynStruct PREP
instance SynStruct ADV
instance SynStruct NOT
instance SynStruct DIDNT
instance SynStruct CONJ
instance SynStruct DISJ

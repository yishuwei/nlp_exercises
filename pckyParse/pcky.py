# Read in grammar in Chomsky Normal Form and sentences, output parses

import sys
from math import log10
from collections import Counter
from tree import Tree

# method to generate parse trees, given a backtracing parse table
def build_trees(back, begin, end, tag):
  if end - begin == 1:
    new_tree = Tree(tag)
    new_tree.add_daughter(Tree(back[(begin, end, tag)][1:-1]))
    return new_tree
  
  split, left_tag, right_tag = back[(begin, end, tag)]
  ltree = build_trees(back, begin, split, left_tag)
  rtree = build_trees(back, split, end, right_tag)
  new_tree = Tree(tag)
  new_tree.add_daughter(ltree)
  new_tree.add_daughter(rtree)
  return new_tree

# load probababilistic grammar (must be in Chomsky Normal Form)
getUnaryRulesByDaughter = {}
getBinaryRulesByLeftDaughter = {}
start_symbol = None
with open(sys.argv[1]) as grammar:
  rule_count = 0
  for line in grammar:
    line = line.split('->', 1)
    if len(line) == 2:
      lhs = line[0].strip()
      line = line[1].rsplit(' ', 1)
      rhs = tuple(line[0].split())
      logprob = log10(float(line[1].strip()[1:-1]))
      if len(rhs) == 1:
        if rhs[0] not in getUnaryRulesByDaughter:
          getUnaryRulesByDaughter[rhs[0]] = set()
        getUnaryRulesByDaughter[rhs[0]].add((lhs, rhs, logprob))
      elif len(rhs) == 2:
        if rhs[0] not in getBinaryRulesByLeftDaughter:
          getBinaryRulesByLeftDaughter[rhs[0]] = set()
        getBinaryRulesByLeftDaughter[rhs[0]].add((lhs, rhs, logprob))
      
      if rule_count == 0:
        start_symbol = lhs
      rule_count += 1

#print getUnaryRulesByDaughter
#print getBinaryRulesByLeftDaughter

# parse sentences (CKY algorithm)
with open(sys.argv[2]) as sentences_file:
  for sent in sentences_file:
    sent = sent.strip()
    cell_tags = {}
    back = {}
    tokens = sent.split()
    
    # generate possible preterminals (span = 1)
    for j in range(len(tokens)):
      terminal = "'" + tokens[j] + "'"
      scores = Counter()
      for rule in getUnaryRulesByDaughter.get(terminal, []):
        scores[rule[0]] = rule[2]
        back[(j, j+1, rule[0])] = terminal
      cell_tags[(j, j+1)] = scores
    
    # generate possible phrase constituents (span >= 2)
    ceil = len(tokens) + 1
    for span in range(2, ceil):
      for begin in range(0, ceil - span):
        end = begin + span
        scores = Counter()
        for split in range(begin + 1, end):
          left_tags = cell_tags[(begin, split)]
          right_tags = cell_tags[(split, end)]
          for left_tag in left_tags:
            for rule in getBinaryRulesByLeftDaughter.get(left_tag, []):
              right_tag = rule[1][1]
              if right_tag in right_tags:
                score = left_tags[left_tag] + right_tags[right_tag] + rule[2]
                if score >= scores.get(rule[0], float('-inf')):
                  scores[rule[0]] = score
                  back[(begin, end, rule[0])] = (split, left_tag, right_tag)
        cell_tags[(begin, end)] = scores
    #print back
    
    # construct parse trees
    parse = build_trees(back, 0, len(tokens), start_symbol) if (0, len(tokens), start_symbol) in back else Tree('')
    
    print parse.bracket_format()

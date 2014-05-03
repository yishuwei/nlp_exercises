# Train a probabilistic grammar from treebank (a set of parsed sentences)

import sys
from collections import Counter
from tree import Tree

# parse trees, collect counts
label_count = Counter()
production_counts = {}
start_symbol = None
with open(sys.argv[1]) as train_file:
  for tree_string in train_file:
    productions = Tree.parse_bracket(tree_string).get_productions()
    if start_symbol == None:
      start_symbol = productions[0][0]
    for lhs, rhs in productions:
      label_count[lhs] += 1
      if lhs not in production_counts:
        production_counts[lhs] = Counter()
      production_counts[lhs][rhs] += 1

# sanity check!!
for lhs, count in label_count.iteritems():
  if sum(production_counts[lhs].itervalues()) != count:
    print >> sys.stderr, 'oops!'

# produce probabilistic grammar based on collected statistics
with open(sys.argv[2], 'w') as output_file:
  denominator = float(label_count[start_symbol])
  for rhs, count in production_counts[start_symbol].iteritems():
    print >> output_file, start_symbol, '->', ' '.join(rhs), '[' + str(count/denominator) + ']'
  for lhs in production_counts:
    if lhs != start_symbol:
      denominator = float(label_count[lhs])
      for rhs, count in production_counts[lhs].iteritems():
        print >> output_file, lhs, '->', ' '.join(rhs), '[' + str(count/denominator) + ']'

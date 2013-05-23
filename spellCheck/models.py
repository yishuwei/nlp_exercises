import sys
import os
import marshal
from glob import iglob
from collections import Counter
import itertools
from edit import get_edits

def scan_corpus(training_corpus_loc):
  """
  scans through the training corpus and builds language model
  """
  unigrams = Counter()
  bigrams = Counter()
  for block_fname in iglob( os.path.join( training_corpus_loc, '*.txt' ) ):
    print >> sys.stderr, 'processing block: ' + block_fname
    with open( block_fname ) as f:
      for line in f:
        tokens = line.split()
        unigrams.update(tokens)
        bigrams.update(itertools.izip(tokens[:-1], tokens[1:]))
  
  print >> sys.stderr, 'calculating probabilities'
  for gram in bigrams:
    bigrams[gram] = float(bigrams[gram]) / unigrams[gram[0]]
  
  total_unigrams = float(sum(unigrams.itervalues()))
  for word in unigrams:
    unigrams[word] = unigrams[word] / total_unigrams
  
  with open('unigrams', 'wb') as ufile:
    marshal.dump(dict(unigrams), ufile)
  with open('bigrams', 'wb') as bfile:
    marshal.dump(dict(bigrams), bfile)

def read_edit1s(edit1s_filename):
  """
  reads the edit1s data and builds the noisy channel model
  """
  alphabet = "abcdefghijklmnopqrstuvwxyz0123546789&$+_'. "
  char_unigrams = Counter()
  char_bigrams = Counter()
  edits = Counter()
  with open(edit1s_filename) as f:
    print >> sys.stderr, 'processing edit1s'
    for line in f:
      # the .rstrip() is needed to remove the \n that is stupidly included in the line
      line = line.rstrip()
      if line:
        # note that '-' is the dummy start symbol which the probability is
        # conditioned on when insertion/deletion happens at the first letter
        noisy, correct = line.split('\t')
        char_unigrams.update('-' + correct)
        char_bigrams.update(itertools.izip('-'+correct[:-1], correct))
        edits.update(get_edits(correct, noisy))
  
  print >> sys.stderr, 'calculating probabilities'
  for x, y in itertools.product(alphabet+'-', alphabet):
    edits[('i', x, y)] = (edits[('i', x, y)] + 1.0) / (char_unigrams[x] + len(alphabet) + 1.0)
    edits[('d', x, y)] = (edits[('d', x, y)] + 1.0) / (char_bigrams[(x,y)] + 2.0)
    if x != '-':
      edits[('s', x, y)] = (edits[('s', x, y)] + 1.0) / (char_unigrams[x] + len(alphabet) + 1.0)
      edits[('t', x, y)] = (edits[('t', x, y)] + 1.0) / (char_bigrams[(x,y)] + 2.0)
  edits[('l', 'e', 'a')] = (edits[('l', 'e', 'a')] + 1.0) / (char_bigrams[('l','e')] + 2.0)
  edits[('l', 'a', 'e')] = (edits[('l', 'a', 'e')] + 1.0) / (char_bigrams[('a','l')] + 2.0)
  with open('edits', 'wb') as efile:
    marshal.dump(dict(edits), efile)


if __name__ == '__main__':
  if len(sys.argv) != 3:
    print >> sys.stderr, 'usage: python models.py <training corpus dir> <training edit1s file>' 
    os._exit(-1)
  scan_corpus(sys.argv[1])
  read_edit1s(sys.argv[2])
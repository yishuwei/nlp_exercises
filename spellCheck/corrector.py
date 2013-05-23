import sys
import qmaster

hold_prob = 0.9
edit_prob = 0.01
bigram_interpolation = 0.1 # lambda (also used as alpha in stupid backoff mode)
relative_score_weight = 1 # mu

if len(sys.argv) != 3:
  print >> sys.stderr, 'usage: python corrector.py <uniform | empirical | extra> <queries file>' 
  os._exit(-1)

mode = 1
if sys.argv[1] == 'uniform':
  mode = 0
if sys.argv[1] == 'extra':
  mode = 2

print >> sys.stderr, 'loading...'
master = qmaster.QueryMaster(mode, hold_prob, edit_prob, bigram_interpolation, relative_score_weight)
print >> sys.stderr, 'ready'

print >> sys.stderr, 'processing queries...'

with open(sys.argv[2]) as queries_file:
  for query in queries_file:
    query = query.rstrip()
    rewrite = master.rewrite_query(query)
    print rewrite

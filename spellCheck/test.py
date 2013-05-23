import os, sys
import qmaster

mode = 1
hold_prob = 0.9
edit_prob = 0.01
bigram_interpolation = 0.1 # lambda (also used as alpha in stupid backoff mode)
relative_score_weight = 1 # mu

print >> sys.stderr, 'loading...'
master = qmaster.QueryMaster(mode, hold_prob, edit_prob, bigram_interpolation, relative_score_weight)
print >> sys.stderr, 'ready'

if len(sys.argv) > 1:
  print >> sys.stderr, 'processing queries...'
  total = 0
  miss = 0
  with open('data/queries.txt') as query_file:
    with open('data/gold.txt') as gold_file:
      for query in query_file:
        query = query.rstrip()
        gold = gold_file.readline().rstrip()
        if query:
          total += 1
          rewrite = master.rewrite_query(query)
          print rewrite
          if rewrite != gold:
            miss += 1
  r = 1 - float(miss)/total
  print >> sys.stderr, "hit rate: " + str(r)
  os._exit(-1)

while True:
  input = sys.stdin.readline()
  input = input.strip()
  if len(input) == 0: # end of file reached
    break
  
  print master.rewrite_query(input)

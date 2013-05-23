import marshal
from math import log
from edit import get_edits

def read_data(filename):
  with open(filename, 'rb') as f:
    return marshal.load(f)

class QueryMaster():
  def __init__(self, mode, hold_prob, edit_prob, bigram_interpolation, relative_score_weight):
    self.alphabet = "abcdefghijklmnopqrstuvwxyz0123546789&$+_' "
    self.mode = mode
    self.hold_prob = hold_prob
    self.edit_prob = edit_prob
    self.bigram_interpolation = bigram_interpolation
    self.relative_score_weight = relative_score_weight
    self.unigrams = read_data('unigrams')
    self.bigrams = read_data('bigrams')
    if mode > 0:
      self.edits = read_data('edits')
  
  def verify_string(self, s):
    for term in s.split():
      if term not in self.unigrams:
        return False
    return True
  
  def verify_sequence(self, seq):
    for term in seq:
      if term not in self.unigrams:
        return False
    return True
  
  def bigram_score(self, query):
    terms = query.split()
    score = log(self.unigrams[terms[0]])
    for i in range(1, len(terms)):
      if self.mode < 2: 
        prob = self.bigram_interpolation * self.unigrams[terms[i]] + (1-self.bigram_interpolation) * self.bigrams.get((terms[i-1], terms[i]), 0)
        score += log(prob)
      else: # stupid backoff
        if (terms[i-1], terms[i]) in self.bigrams:
          score += log(self.bigrams[(terms[i-1], terms[i])])
        else:
          score += log(self.bigram_interpolation * self.unigrams[terms[i]])
    return score
  
  def channel_score(self, correct_query, noisy_query):
    if correct_query == noisy_query:
      return log(self.hold_prob)
    
    if self.mode == 0:
      # uniform mode
      return len(get_edits(correct_query, noisy_query)) * log(self.edit_prob)
    else:
      # empirical mode
      score = 0
      for edit in get_edits(correct_query, noisy_query):
        score += log(self.edits[edit])
    return score
  
  def terms_edited_once(self, term):
    edited = set()
    splits = [(term[:i], term[i:]) for i in range(len(term) + 1)]
    # deletion
    edited.update(a + b[1:] for a, b in splits if b)
    # transposition
    edited.update(a + b[1] + b[0] + b[2:] for a, b in splits if len(b) > 1)
    # substitution
    edited.update(a + c + b[1:] for a, b in splits for c in self.alphabet if b)
    # insertion
    edited.update(a + c + b for a, b in splits for c in self.alphabet)
    
    edited.update(a + 'al' + b[2:] for a, b in splits if len(b) > 1 and b[:2] == 'le')
    edited.update(a + 'le' + b[2:] for a, b in splits if len(b) > 1 and b[:2] == 'al')
    return edited
  
  def terms_edited_once_filtered(self, term):
    return set(w for w in self.terms_edited_once(term) if self.verify_string(w))
  
  def terms_edited_twice_filtered(self, term):
    return set(w2 for w1 in self.terms_edited_once(term) for w2 in self.terms_edited_once(w1) if self.verify_string(w2))

  def queries_edited_once_filtered(self, query_terms, eterms_lookup):
    edited_queries = set()
    # case 1: one term is edited
    for i in range(len(query_terms)):
      split1 = query_terms[:i]
      split2 = query_terms[i+1:]
      if split1 and not self.verify_sequence(split1):
        continue
      if split2 and not self.verify_sequence(split2):
        continue
      for eterm in eterms_lookup[i]:
        edited_queries.add(' '.join(split1 + [eterm] + split2))
    
    # case 2: two terms are joined
    for i in range(1, len(query_terms)):
      join_term = query_terms[i-1] + query_terms[i]
      if join_term not in self.unigrams:
        continue
      split1 = query_terms[:i-1]
      split2 = query_terms[i+1:]
      if split1 and not self.verify_sequence(split1):
        continue
      if split2 and not self.verify_sequence(split2):
        continue      
      edited_queries.add(' '.join(split1 + [join_term] + split2))
    return edited_queries
  
  def queries_edited_twice_filtered(self, query_terms, eterms_lookup):
    edited_queries = set()
    """
    # case 1: one term is edited twice
    for i in range(len(query_terms)):
      split1 = query_terms[:i]
      split2 = query_terms[i+1:]
      if split1 and not self.verify_sequence(split1):
        continue
      if split2 and not self.verify_sequence(split2):
        continue
      for eterm in self.terms_edited_twice_filtered(query_terms[i]):
        edited_queries.add(' '.join(split1 + [eterm] + split2))
    
    # case 2: two terms are edited once
    for i in range(len(query_terms)-1):
      for j in range(i+1, len(query_terms)):
        split1 = query_terms[:i]
        split2 = query_terms[i+1:j]
        split3 = query_terms[j+1:]
      if split1 and not self.verify_sequence(split1):
        continue
      if split2 and not self.verify_sequence(split2):
        continue
      if split3 and not self.verify_sequence(split3):
        continue
      for eterm1 in eterms_lookup[i]:
        for eterm2 in eterms_lookup[j]:
          edited_queries.add(' '.join(split1 + [eterm1] + split2 + [eterm2] + split3))
    """
    # case 3: two terms are joined, and the joined term is edited
    for i in range(1, len(query_terms)):
      split1 = query_terms[:i-1]
      split2 = query_terms[i+1:]
      if split1 and not self.verify_sequence(split1):
        continue
      if split2 and not self.verify_sequence(split2):
        continue
      join_term = query_terms[i-1] + query_terms[i]
      for eterm in self.terms_edited_once_filtered(join_term):
        edited_queries.add(' '.join(split1 + [eterm] + split2))
    
    # case 4: two terms are joined, and another term is edited
    for i in range(1, len(query_terms)):
      join_term = query_terms[i-1] + query_terms[i]
      if join_term not in self.unigrams:
        continue
      for j in range(len(query_terms)):
        if j < (i-1):
          split1 = query_terms[:j]
          split2 = query_terms[j+1:i-1]
          split3 = query_terms[i+1:]
          if split1 and not self.verify_sequence(split1):
            continue
          if split2 and not self.verify_sequence(split2):
            continue
          if split3 and not self.verify_sequence(split3):
            continue
          for eterm in eterms_lookup[j]:
            edited_queries.add(' '.join(split1 + [eterm] + split2 + [join_term] + split3))
        elif j > i:
          split1 = query_terms[:i-1]
          split2 = query_terms[i+1:j]
          split3 = query_terms[j+1:]
          if split1 and not self.verify_sequence(split1):
            continue
          if split2 and not self.verify_sequence(split2):
            continue
          if split3 and not self.verify_sequence(split3):
            continue
          for eterm in eterms_lookup[j]:
            edited_queries.add(' '.join(split1 + [join_term] + split2 + [eterm] + split3))
    
    # case 5: two joins
    for i in range(1, len(query_terms)-1):
      for j in range(i+1, len(query_terms)):
        if j == (i+1):
          join_term = query_terms[i-1] + query_terms[i] + query_terms[j]
          if join_term not in self.unigrams:
            continue
          split1 = query_terms[:i-1]
          split2 = query_terms[j+1:]
          if split1 and not self.verify_sequence(split1):
            continue
          if split2 and not self.verify_sequence(split2):
            continue      
          edited_queries.add(' '.join(split1 + [join_term] + split2))
        else:
          join_term1 = query_terms[i-1] + query_terms[i]
          join_term2 = query_terms[j-1] + query_terms[j]
          if join_term1 not in self.unigrams or join_term2 not in self.unigrams:
            continue
          split1 = query_terms[:i-1]
          split2 = query_terms[i+1:j-1]
          split3 = query_terms[j+1:]
          if split1 and not self.verify_sequence(split1):
            continue
          if split2 and not self.verify_sequence(split2):
            continue
          if split3 and not self.verify_sequence(split3):
            continue
          edited_queries.add(' '.join(split1 + [join_term1] + split2 + [join_term2] + split3))
    
    return edited_queries
  
  def rewrite_query(self, query):
    query_terms = query.split()
    eterms_lookup = []
    for term in query_terms:
      eterms_lookup.append(self.terms_edited_once_filtered(term))

    candidates = set()
    if self.verify_string(query):
      candidates.add(query)
    candidates |= self.queries_edited_once_filtered(query_terms, eterms_lookup)
    candidates |= self.queries_edited_twice_filtered(query_terms, eterms_lookup)
    
    max_score = float('-inf')
    new_query = query
    
    for candidate in candidates:
      if candidate.strip():
        score = self.relative_score_weight * self.bigram_score(candidate) + self.channel_score(candidate, query)
        if score > max_score:
          max_score = score
          new_query = candidate
    return new_query.strip()

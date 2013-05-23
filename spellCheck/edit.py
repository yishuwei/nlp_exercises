# returns a minimal sequence of edits that transforms str1 to str2
# as a list of (type, x, y) pairs, where type can be 'i','d','s','t','l'
# for insertion, deletion, substitution, transposition, and confusion between 'le' and 'al'
def get_edits(str1, str2):
  if str1 == '':
    str2 = '-' + str2
    return [('i', str2[i-1], str2[i]) for i in range(1,len(str2))]
  if str2 == '':
    str1 = '-' + str1
    return [('d', str1[i-1], str1[i]) for i in range(1,len(str1))]
  
  edit_matrix = {}
  len1 = len(str1)
  len2 = len(str2)
  
  edit_matrix[(-1,-1)] = []
  edit_matrix[(0,-1)] = [('d', '-', str1[0])]
  edit_matrix[(-1,0)] = [('i', '-', str2[0])]
  for i in range(1, len1):
    edit_matrix[(i,-1)] = edit_matrix[(i-1,-1)] + [('d', str1[i-1], str1[i])]
  for j in range(1, len2):
    edit_matrix[(-1,j)] = edit_matrix[(-1,j-1)] + [('i', str2[j-1], str2[j])]
  
  for i in range(len1):
    for j in range(len2):
      possible = []
      # deletion
      if i == 0:
        possible.append(edit_matrix[(-1,j)] + [('d', '-', str1[0])])
      else:
        possible.append(edit_matrix[(i-1,j)] + [('d', str1[i-1], str1[i])])
      # insertion
      if j == 0:
        possible.append(edit_matrix[(i,-1)] + [('i', '-', str2[0])])
      else:
        possible.append(edit_matrix[(i,j-1)] + [('i', str2[j-1], str2[j])])
      # substitution
      if str1[i] == str2[j]:
        possible.append(edit_matrix[(i-1,j-1)])
      else:
        possible.append(edit_matrix[(i-1,j-1)] + [('s', str1[i], str2[j])])
      # transposition
      if i > 0 and j > 0 and str1[i] == str2[j-1] and str1[i-1] == str2[j]:
        possible.append(edit_matrix[(i-2,j-2)] + [('t', str1[i-1], str1[i])])
      
      # confusion between 'le' and 'al'
      if i > 0 and j > 0 and str1[i] == 'l' and str1[i-1] == 'e' and str2[j-1] == 'a' and str2[j] == 'l':
        possible.append(edit_matrix[(i-2,j-2)] + [('l', 'e', 'a')])
      if i > 0 and j > 0 and str1[i] == 'a' and str1[i-1] == 'l' and str2[j-1] == 'l' and str2[j] == 'e':
        possible.append(edit_matrix[(i-2,j-2)] + [('l', 'a', 'e')])
      
      edit_matrix[(i,j)] = min(possible, key=len)
  
  return edit_matrix[(len1-1, len2-1)]

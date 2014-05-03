# A useful Tree class

class Tree:
  def __init__(self, label):
    self.label = label
    self.mother = None
    self.children = []
  
  def add_daughter(self, subtree):
    subtree.mother = self
    self.children.append(subtree)
  
  # returns a list of production rules that license this tree
  def get_productions(self):
    if not self.children:
      return []
    return sum(  (daughter.get_productions() for daughter in self.children),
                [(self.label, tuple(daughter.get_label() for daughter in self.children))] )
  
  # This will add quotes around label if children is empty
  def get_label(self):
    if not self.children:
      return "'" + self.label + "'"
    return self.label
  
  def bracket_format(self):
    if len(self.children) == 0:
      return self.label
    return '(' + self.label + ' ' + ' '.join(daughter.bracket_format() for daughter in self.children) + ')'
  
  @staticmethod
  def parse_bracket(tree_string):
    tree_string = tree_string.strip()
    tree_string_len = len(tree_string)
    curr = None
    label_buffer = []
    i = 0
    while i < tree_string_len:
      if tree_string[i] == ' ':
        i += 1
      elif tree_string[i] == ')':
        if curr.mother == None:
          break
        curr = curr.mother
        i += 1
      else:
        label_buffer = [tree_string[i]]
        go_deeper = False
        if tree_string[i] == '(':
          label_buffer = []
          go_deeper = True
        
        while True:
          i += 1
          if tree_string[i] in ' ()':
            break
          else:
            label_buffer.append(tree_string[i])
        
        new_node = Tree(''.join(label_buffer))
        if curr != None:
          curr.add_daughter(new_node)
        if go_deeper:
          curr = new_node
    
    if curr != None:
      while curr.mother != None:
        curr = curr.mother
    return curr

import re

class AVC_tex_handler:
	def __init__(self):
		self._conv_table = [
				(re.compile(r'\\frac\{.+\}'), self._frac_to_slash),
				(re.compile(r'_\{[0-9aeijoruvx+-=()]+\}|_[0-9aeijoruvx+-=()]'), self._underscore_to_subscript),
				(re.compile(r'\^\{[0-9aeijoruvx+-=()]+\}|\^[0-9aeijoruvx+-=()]'), self._caret_to_superscript),
				(re.compile(r'\\sqrt'), '√'),
				(re.compile(r'\\pm'), '±'),
				(re.compile(r'\\div'), '÷'),
				(re.compile(r'\\times'), '×'),
				(re.compile(r'\\neq'), '≠'),
				(re.compile(r'\\not='), '≠'),
				(re.compile(r'\\leqq'), '≦'),
				(re.compile(r'\\leq'), '≤'),
				(re.compile(r'\\geqq'), '≧'),
				(re.compile(r'\\geq'), '≥'),
				(re.compile(r'\\cap'), '∩'),
				(re.compile(r'\\cup'), '∪'),
				(re.compile(r'\\subseteq'), '⊆'),
				(re.compile(r'\\subset'), '⊂'),
				(re.compile(r'\\supseteq'), '⊇'),
				(re.compile(r'\\supset'), '⊃'),
				(re.compile(r'\\in'), '∈'),
				(re.compile(r'\\ni'), '∋'),
				(re.compile(r'\\vee'), '∨'),
				(re.compile(r'\\\wedge'), '∧'),
				(re.compile(r'\\cdots'), '⋯'),
				(re.compile(r'\\ldots'), '…'),
				(re.compile(r'\\vdots'), '⋮'),
				(re.compile(r'\\cdot'), '∙'),
				(re.compile(r'\\bullet'), '⦁'),
				(re.compile(r'\\left'), ''),
				(re.compile(r'\\right'), ''),
				(re.compile(r'\\max'), 'max'),
				(re.compile(r'\\min'), 'min'),
				(re.compile(r'\\{'), '{'),
				(re.compile(r'\\}'), '}'),
				(re.compile(r'\\ '), '')
				]
		self._subscript_table = str.maketrans('aeijoruvx0123456789+-=()', 'ₐₑᵢⱼₒᵣᵤᵥₓ₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎', '_{}')
		self._superscript_table = str.maketrans('AaBbDdEeGgHhIiJjKkLlMmNnOoPpRrTtUuVvWwcfsxyz0123456789+-=()', 'ᴬᵃᴮᵇᴰᵈᴱᵉᴳᵍᴴʰᴵⁱᴶʲᴷᵏᴸˡᴹᵐᴺⁿᴼᵒᴾᵖᴿʳᵀᵗᵁᵘⱽᵛᵂʷᶜᶠˢˣʸᶻ⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾', '^{}')
		self._exclude_pattern = re.compile(r'^[a-zA-Z0-9(...)\s,+=-]+$')

	def replace_var_text(self, section):
		var_tags = section.findAll('var')
		for var_tag in var_tags:
			if var_tag != [] and not self._exclude_pattern.match(var_tag.text):
				for tex_expression in self._conv_table:
					if tex_expression[0].search(var_tag.text):
						var_tag.string = tex_expression[0].sub(tex_expression[1], var_tag.text)

	def test(self, text):
		if not self._exclude_pattern.match(text):
			for tex_expression in self._conv_table:
				if tex_expression[0].search(text):
					text = tex_expression[0].sub(tex_expression[1], text)
		print(text)

	def _frac_to_slash(self, matchobj):
		text = matchobj.group(0)
		table = str.maketrans('{}', '()')
		for i in range(2):
			stack = []
			for j in range(len(text)):
				if text[j] == '{' or text[j] == '}':
					stack.append(j)
				if text[j] == '}':
					if len(stack) == 2 and text[stack[0]] == '{' and text[stack[1]] == '}':
						break
					try:
						stack.pop()
						stack.pop()
					except:
						return matchobj.group(0)
			if i == 0:
				try:
					if len(text[stack[0]:stack[1]+1]) == 3:
						numerator = text[stack[0]+1]
					else:
						numerator = text[stack[0]:stack[1]+1].translate(table)
					text = text[stack[1]+1:]
				except:
					return matchobj.group(0)
			if i == 1:
				try:
					if len(text[stack[0]:stack[1]+1]) == 3:
						denominator = text[stack[0]+1]
					else:
						denominator = text[stack[0]:stack[1]+1].translate(table)
					return numerator + '/' + denominator + text[stack[1]+1:]
				except:
					return matchobj.group(0)

	def _underscore_to_subscript(self, matchobj):
		original_text = matchobj.group(0)
		return original_text.translate(self._subscript_table)

	def _caret_to_superscript(self, matchobj):
		original_text = matchobj.group(0)
		return original_text.translate(self._superscript_table)

if __name__=='__main__':
	handler = AVC_tex_handler()
	handler.test(r'\sqrt{\frac{{{}{3}{5}}')

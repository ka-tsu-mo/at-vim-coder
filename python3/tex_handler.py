import re

class AVC_tex_handler:
	def __init__(self):
		self._conv_table = [
				# todo <code>にシングルクォーとを加える
				(re.compile(r'\\frac\{.+\}\{.+\}'), self._frac_to_slash),
				(re.compile(r'_\{[0-9aeijoruvx+-=()]+\}|_[0-9aeijoruvx+-=()]'), self._underscore_to_subscript),
				(re.compile(r'\^\{[0-9aeijoruvx+-=()]+\}|\^[0-9aeijoruvx+-=()]'), self._caret_to_superscript),
				(re.compile(r'\\sqrt'), '√'),
				(re.compile(r'\\pm'), '±'),
				(re.compile(r'\\div'), '÷'),
				(re.compile(r'\\times'), '×'),
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

	def _frac_to_slash(self, matchobj):
		original_text = matchobj.group(0)
		args = re.findall(r'\{.+?\}', original_text)
		table = str.maketrans('{}', '()')
		for index, arg in enumerate(args):
			if len(arg) == 3:
				if index == 0: numerator = arg[1]
				if index == 1: denominator = arg[1]
			else:
				if index == 0: numerator = arg.translate(table)
				if index == 1: denominator = arg.translate(table)
		return numerator + '/' + denominator

	def _underscore_to_subscript(self, matchobj):
		original_text = matchobj.group(0)
		return original_text.translate(self._subscript_table)

	def _caret_to_superscript(self, matchobj):
		original_text = matchobj.group(0)
		return original_text.translate(self._superscript_table)

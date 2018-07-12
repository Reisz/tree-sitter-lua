module.exports = grammar({
	name: 'lua',

	word: $ => $.identifier,
	conflicts: $ => [
		[$.identifier_list],
		[$._statement, $._prefix_expression],
		[$.function_call, $._expression]
	],

	extras: $ => [
		/\s/,
		$.comment
	],

	inline: $ => [
		$._function_body
	],

	externals: $ => [
		$._long_string,
		$.comment
	],

	rules: {
		chunk: $ => optional($._block),
		_block: $ => choice(
			seq(repeat1($._statement), optional($.return_statement)),
			seq(repeat($._statement), $.return_statement)
		),

		_statement: $ => choice(
			';',
			$.global_assignment,
			$.function_call,
			$.label,
			$.break,
			$.goto,
			$.do_statement,
			$.while_statement,
			$.repeat_statement,
			$.if_statement,
			$.numerical_for_statement,
			$.iterative_for_statement,
			$.function_definition,
			$.local_assignment
		),

		function_identifier: $ => seq(
			$.identifier,
			repeat(seq('.', $.identifier)),
			optional(seq(':', $.identifier))
		),

		break: $ => 'break',
		label: $ => seq('::', $.identifier, '::'),
		goto: $ => seq('goto', $.identifier),
		do_statement: $ => seq('do', optional($._block), 'end'),
		while_statement: $ => seq('while', $._expression, 'do', optional($._block), 'end'),
		repeat_statement: $ => seq('repeat', optional($._block), 'until', $._expression),

		if_statement: $ => seq(
			'if', $._expression, 'then', optional($._block),
			repeat(seq('elseif', $._expression, 'then', optional($._block))),
			optional(seq('else', optional($._block))),
			'end'
		),

		numerical_for_statement: $ => seq(
			'for', $.identifier, '=', $._expression,
			',', $._expression, optional(seq(',', $._expression)),
			'do', optional($._block), 'end'
		),

		iterative_for_statement: $ => seq(
			'for', $.identifier_list, 'in',
			$.expression_list, 'do',
			optional($._block), 'end'
		),

		function_definition: $ => choice(
			seq(
				'local', 'function',
				$.identifier, $._function_body
			),
			seq(
				'function',
				$.function_identifier,
				$._function_body
			)
		),
		function_literal: $ => seq('function', $._function_body),

		_function_body: $ => seq(
			'(', optional($._parameter_list), ')',
			optional($._block), 'end'
		),

		local_assignment: $ => seq(
			'local', $.identifier_list, optional(seq('=', $.expression_list))
		),

		global_assignment: $ => seq(
			$.variable_list, '=', $.expression_list
		),

		return_statement: $ => seq('return', optional($.expression_list), optional(';')),

		variable: $ => choice(
			$.identifier,
			seq($._prefix_expression, '[', $._expression, ']'),
			seq($._prefix_expression, '.', $.identifier)
		),

		_prefix_expression: $ => choice(
			$.variable,
			$.function_call,
			seq('(', $._expression, ')')
		),

		function_call: $ => choice(
			seq($._prefix_expression, $._function_arguments),
			seq($._prefix_expression, ':', $.identifier, $._function_arguments)
		),

		_function_arguments: $ => choice(
			seq('(', optional($.expression_list), ')'),
			$.table_constructor,
			$.string_literal
		),

		variable_list: $ => seq($.variable, repeat(seq(',', $.variable))),
		expression_list: $ => seq($._expression, repeat(seq(',', $._expression))),
		identifier_list: $ => seq($.identifier, repeat(seq(',', $.identifier))),
		_parameter_list: $ => choice(
			seq($.identifier_list, optional(seq(',', $.vararg))),
			$.vararg
		),

		_expression: $ => choice(
				$.nil, $.false, $.true,
				$.number_literal, $.string_literal,
				$.vararg,
				$.function_literal,
				$._prefix_expression,
				$.table_constructor,
				$.binary_expression,
				$.unary_expression
		),

		nil: $ => 'nil',
		false: $ => 'false',
		true: $ => 'true',
		vararg: $ => '...',

		binary_expression: $ => choice(
			prec.left(1, seq($._expression, 'or', $._expression)),
			prec.left(2, seq($._expression, 'and', $._expression)),
			prec.left(3, seq($._expression, /<|>|<=|>=|~=|==/, $._expression)),
			prec.left(4, seq($._expression, '|', $._expression)),
			prec.left(5, seq($._expression, '~', $._expression)),
			prec.left(6, seq($._expression, '&', $._expression)),
			prec.left(7, seq($._expression, /<<|>>/, $._expression)),
			prec.right(8, seq($._expression, '..', $._expression)),
			prec.left(9, seq($._expression, /[\+-]/, $._expression)),
			prec.left(10, seq($._expression, /\*|\/|\/\/|%/, $._expression)),
			prec.right(12, seq($._expression, '^', $._expression))
		),

		unary_expression: $ => prec.right(11, seq(/not|#|-|~/, $._expression)),

		identifier: $ => /[_a-zA-Z]\w*/,

		table_constructor: $ => seq(
			'{', optional(seq(
				$.field, repeat(seq(/[,;]/, $.field)), optional(/[,;]/)
			)), '}'
		),
		field: $ => choice(
			seq('[', $._expression, ']', '=', $._expression),
			seq($.identifier, '=', $._expression),
			$._expression
		),

		number_literal: $ => token(choice(
			seq(
				choice(/\d+/,/\d+\.\d*/,/\d*\.\d+/),
				optional(/[eE][\+-]?\d+/)
			),
			seq(
				/0[xX]/,
				choice(/[0-9a-fA-F]+/, /[0-9a-fA-F]+\.[0-9a-fA-F]*/, /[0-9a-fA-F]*\.[0-9a-fA-F]+/),
				optional(/[pP][\+-]?[0-9a-fA-F]+/)
			)
		)),

		string_literal: $ => choice(
			seq('"', repeat(choice(
				/[^\\"\n]/,
				/\\[abfnrtv\\"'\n]/,
				/\\z\s*/,
				/\\x[0-9a-fA-F]{2}/,
				/\\[0-9][0-9]?[0-9]?/,
				/\\u\{[0-9a-fA-F]+\}/
			)), '"'),
			seq("'", repeat(choice(
				/[^\\'\n]/,
				/\\[abfnrtv\\"'\n]/,
				/\\z\s*/,
				/\\x[0-9a-fA-F]{2}/,
				/\\[0-9][0-9]?[0-9]?/,
				/\\u\{[0-9a-fA-F]+\}/
			)), "'"),
			$._long_string
		)
	}
});

#include <tree_sitter/parser.h>

enum TokenType {
	LONG_STRING,
	COMMENT
};

bool line_comment(TSLexer *lexer) {
	if (lexer->result_symbol != COMMENT)
		return false;

	while (lexer->lookahead != '\n' && lexer->lookahead != 0)
		lexer->advance(lexer, false);

	return true;
}

extern "C" {
	void *tree_sitter_lua_external_scanner_create() {
	  return nullptr;
	}

	bool tree_sitter_lua_external_scanner_scan(void *payload, TSLexer *lexer,
                                          const bool *valid_symbols) {
    unsigned startCount = 0, endCount = 0;

    while (lexer->lookahead == '\t' || lexer->lookahead == '\n' || lexer->lookahead == '\r' || lexer->lookahead == ' ')
    	lexer->advance(lexer, true);

		// handle comments
		if (lexer->lookahead == '-') {
			if (!valid_symbols[COMMENT])
				return false;
			lexer->result_symbol = COMMENT;

			lexer->advance(lexer, false);
			if (lexer->lookahead != '-')
				return false;
			lexer->advance(lexer, false);
		} else {
			if (!valid_symbols[LONG_STRING])
				return false;
			lexer->result_symbol = LONG_STRING;
		}

		// first opening bracket
    if (lexer->lookahead != '[')
    	return line_comment(lexer);
		lexer->advance(lexer, false);

		// count starting equals signs
		while (lexer->lookahead == '=') {
			++startCount;
			lexer->advance(lexer, false);
		}

		// second opening bracket
		if (lexer->lookahead != '[')
			return line_comment(lexer);
		lexer->advance(lexer, false);

		// find correct closing brackets
		do {
			endCount = 0;

			// find first closing bracket
			while (lexer->lookahead != ']' && lexer->lookahead != 0)
				lexer->advance(lexer, false);
			if (lexer->lookahead == 0)
				return false;
			lexer->advance(lexer, false);

			// count closing equals signs
			while (lexer->lookahead == '=') {
				++endCount;
				lexer->advance(lexer, false);
			}
		} while (startCount != endCount || lexer->lookahead != ']');
		// second closing bracket
		lexer->advance(lexer, false);

    return true;
	}

	unsigned tree_sitter_lua_external_scanner_serialize(void *payload, char *buffer) {
	  return 0;
	}

	void tree_sitter_lua_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
	}

	void tree_sitter_lua_external_scanner_destroy(void *payload) {
	}
}
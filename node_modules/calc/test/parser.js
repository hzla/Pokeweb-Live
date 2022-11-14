var lexer = require('../lib/lexer');
var parser = require('../lib/parser').parser;

parser.yy = {
  Nodes: function () { }
};

parser.lexer = {
  lex: function () {
    var tag, _ref2;
    _ref2 = this.tokens[this.pos++] || [''];
    tag = _ref2[0];
    this.yytext = _ref2[1];
    this.yylineno = _ref2[2] || 0;
    return tag;
  },
  setInput: function (tokens) {
    this.tokens = tokens;                                                                                                                          
    return this.pos = 0;
  },
  upcomingInput: function () {
    return "";
  }
};

//var tokens = lexer.tokenize("4 + 4 * (2 + 2) / 2");
//var tokens = lexer.tokenize("4 ^ 2 + 4 * 5");
var tokens = lexer.tokenize("35%");
console.log(tokens);

var parsed = parser.parse(tokens);
console.log(parsed);

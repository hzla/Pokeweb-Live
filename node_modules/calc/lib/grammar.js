const fs = require('fs');
const Jison = require('jison').Parser;

var parser = new Jison((function () {
  var unwrap, o, tokens, grammar, operators;

  unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/;

  o = function (patternString, action, options) {
    var match;
    patternString = patternString.replace(/\s{2,}/g, ' ');
    if (!action) {
      return [patternString, '$$ = $1;', options];
    }
    action = (match = unwrap.exec(action)) ? match[1] : "(" + action + "())";
    action = action.replace(/\bnew /g, '$&yy.');
    action = action.replace(/\b(?:Block\.wrap|extend)\b/g, 'yy.$&');
    return [patternString, "$$ = " + action + ";", options];
  };

  tokens = "NUMBER";

  grammar = {
    Root: [
      ['Math EOF', 'return $$ = $1;']
    ],

    Math: [
      o('Math + Math', function () {
        return $1 + $3;
      }),
      o('Math - Math', function () {
        return $1 - $3;
      }),
      o('Math * Math', function () {
        return $1 * $3;
      }),
      o('Math / Math', function () {
        return $1 / $3;
      }),
      o('Math ^ Math', function () {
        return Math.pow($1, $3);
      }),
      o('( Math )', function () {
        return $2;
      }),
      o('NUMBER %', function () {
        return $1 / 100;
      }),
      o('NUMBER', function () {
        return Number($1)
      })
    ]
  };

  var operators = [
    ['left', '+', '-'],
    ['left', '*', '/'],
    ['left', '^']
  ];

  return {
    tokens: tokens,
    bnf: grammar,
    operators: operators,
    startSymbol: 'Root'
  };
}()));

// write to file
fs.writeFileSync('./lib/parser.js', parser.generate(), 'utf8');

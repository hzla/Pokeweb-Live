var jison = require('jison').Parser;

var parser = new jison({
   "lex": {
      "rules": [
         ["\\s+",                    ""],
         ["[0-9]+(?:\\.[0-9]+)?\\b", "return 'NUMBER'"],
         ["\\+",                     "return '+'"],
         ["$",                       "return 'EOF'"]
      ]
   },

   "operators": [
   ],

   "bnf": {
      "expressions": [["e EOF",   "return $1"]],

      "e" :[
         ["e + e",  "$$ = $1+$3"],
         ["NUMBER", "$$ = Number(yytext)"]
      ]
   }
});

var parsed = parser.parse("4 + 2");
console.log(parsed);

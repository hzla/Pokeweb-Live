/*global module */

var Lexer = (function () {

  const rx = {
    token: /^\+|-|\*|\/|\^/,
    number: /^([0-9]+)/,
    whitespace: /^ /
  };

  var $ = {};

  $.tokenize = function (arithmetic) {
    // Cleanup arithmetic by removing extra space
    arithmetic.trim();

    // pointer
    var i = 0,

    // collection of parsed tokens
        tokens = [],

    // the item which we found
        item = "",

    // current chunk of arithmetic
        chunk = "";

    // scan each character until we find something to parse
    while (i < arithmetic.length) {
      // grabs the remaining chunk of arithmetic
      chunk = arithmetic.substr(i, arithmetic.length);

      // matches tokens
//      if (rx.token.test(chunk)) {
//        item = rx.token.exec(chunk)[0];
//        tokens.push(["OPERATOR", item]);
//        i += item.length;

      // matches numbers
//      } else if (rx.number.test(chunk)) {
      if (rx.number.test(chunk)) {
        item = rx.number.exec(chunk)[1];
        tokens.push(["NUMBER", item]);
        i += item.length;

      // newlines
//      } else if (rx.newline.test(chunk)) {
//        tokens.push(["TERMINATOR", "\n"]);
//        i += 1;

      // ignore whitespace
      } else if (rx.whitespace.test(chunk)) {
        i += 1;

      } else {
        // nothing matched
        tokens.push([chunk[0], chunk[0]]);
        i += 1;
      }
    }

    tokens.push(["EOF"]);
    return tokens;
  };

  return $;
}());

module.exports = Lexer;

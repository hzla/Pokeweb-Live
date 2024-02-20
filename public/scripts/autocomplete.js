$.fn.selectRange = function(start, end) {
    var e = document.getElementById($(this).attr('id')); // I don't know why... but $(this) don't want to work today :-/
    if (!e) return;
    else if (e.setSelectionRange) { e.focus(); e.setSelectionRange(start, end); } /* WebKit */ 
    else if (e.createTextRange) { var range = e.createTextRange(); range.collapse(true); range.moveEnd('character', end); range.moveStart('character', start); range.select(); } /* IE */
    else if (e.selectionStart) { e.selectionStart = start; e.selectionEnd = end; }
};

jQuery.each( [ "put", "delete" ], function( i, method ) {
  jQuery[ method ] = function( url, data, callback, type ) {
    if ( jQuery.isFunction( data ) ) {
      type = type || callback;
      callback = data;
      data = undefined;
    }

    return jQuery.ajax({
      url: url,
      type: method,
      dataType: type,
      data: data,
      success: callback
    });
  };
});

function hasWhiteSpace(s) {
  return s.indexOf(' ') >= 0;
}

function isAlphaNumeric(str) {
  var code, i, len;

  for (i = 0, len = str.length; i < len; i++) {
    code = str.charCodeAt(i);
    if (!(code > 47 && code < 58) && // numeric (0-9)
        !(code > 64 && code < 91) && // upper alpha (A-Z)
        !(code > 96 && code < 123)) { // lower alpha (a-z)
      return false;
    }
  }
  return true;
};

$(document).mouseup(function(e) 
{
    var container = $(".popup-editor");

    // if the target of the click isn't the container nor a descendant of the container
    if (!container.is(e.target) && container.has(e.target).length === 0) 
    {
        container.hide();
    }
});

jQuery.fn.selectText = function(){
   var doc = document;
   var element = this[0];

   if (doc.body.createTextRange) {
       var range = document.body.createTextRange();
       range.moveToElementText(element);
       range.select();
   } else if (window.getSelection) {
       var selection = window.getSelection();        
       var range = document.createRange();
       range.selectNodeContents(element);
       selection.removeAllRanges();
       selection.addRange(range);
   }
};

$.fn.removeClassPrefix = function(prefix) {
    this.each(function(i, el) {
        var classes = el.className.split(" ").filter(function(c) {
            return c.lastIndexOf(prefix, 0) !== 0;
        });
        el.className = $.trim(classes.join(" "));
    });
    return this;
};

if(typeof(String.prototype.trim) === "undefined")
{
    String.prototype.trim = function() 
    {
        return String(this).replace(/^\s+|\s+$/g, '');
    };
}

String.prototype.toCamelCase = function() {
    return this.replace(/^([A-Z])|[\s-_](\w)/g, function(match, p1, p2, offset) {
        if (p2) return p2.toUpperCase();
        return p1.toLowerCase();        
    });
};


/******/ (function(modules) { // webpackBootstrap
/******/  // The module cache
/******/  var installedModules = {};

/******/  // The require function
/******/  function __webpack_require__(moduleId) {

/******/    // Check if module is in cache
/******/    if(installedModules[moduleId])
/******/      return installedModules[moduleId].exports;

/******/    // Create a new module (and put it into the cache)
/******/    var module = installedModules[moduleId] = {
/******/      exports: {},
/******/      id: moduleId,
/******/      loaded: false
/******/    };

/******/    // Execute the module function
/******/    modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);

/******/    // Flag the module as loaded
/******/    module.loaded = true;

/******/    // Return the exports of the module
/******/    return module.exports;
/******/  }


/******/  // expose the modules object (__webpack_modules__)
/******/  __webpack_require__.m = modules;

/******/  // expose the module cache
/******/  __webpack_require__.c = installedModules;

/******/  // __webpack_public_path__
/******/  __webpack_require__.p = "";

/******/  // Load entry module and return exports
/******/  return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

  __webpack_require__(1);
  module.exports = __webpack_require__(2);


/***/ },
/* 1 */
/***/ function(module, exports) {

  module.exports = contenteditableAutocomplete

  function contenteditableAutocomplete ($) {
    // AUTOCOMPLETE CLASS DEFINITION
    // =============================

    //
    var ContenteditableAutocomplete = function (el) {
      var $container, $input, $suggestions
      var currentValue, currentValues, currentSuggestions

      // multiple words?
      var isMultiple

      var KEY = {
        UP: 38,
        DOWN: 40,
        TAB: 9,
        RETURN: 13,
        ESC: 27,
        COMMA: 188
      }

      // 1. cache elements for performance reasons and
      // 2. setup event bindings
      function initialize () {
        $input = $(el)
        $container = $('<' + el.nodeName + ' data-autocomplete/>')
        $suggestions = $('<div class="suggestions">').appendTo($container)
        $suggestions.append('<div>Suggestion 1</div><div>Suggestion 2</div><div>Suggestion 3</div>')
        $suggestions.hide()

        isMultiple = $input.is('[data-autocomplete-multiple]')

        $input.on('focus', handleFocus)
        $input.on('input', handleInput)
        $input.on('click', handleInput)
        $input.on('keydown', handleKeydown)
        $input.on('blur', handleBlur)
        $suggestions.on('mousedown touchstart', '> div', handleSuggestionClick)

        // wrap input into container. Use setTimeout to prevent
        // blur event to be triggered before focus. Yeah it's odd.
        // And as if that wouldn't be enough, the input looses focus
        // when wrapped by $container, so we have to re-set the cursor
        // position manually
        setTimeout(function () {
          var cursorPosition = getCaretCharacterOffsetWithin($input[0])
          $input.after($container).appendTo($container)
          $input.focus()
          setCursorAt(cursorPosition)
          $input.selectText()
        })
      }

      // Event handlers
      // --------------

      //
      function handleFocus () {
        currentValue = $input.text()
        if (isMultiple) addTrailingComma()
      }
      //
      function handleInput (/* event */) {
        var newValue = $input.text()
        var query

        if (!newValue.trim()) {
          $suggestions.hide()
          currentValue = newValue
          return
        }

        if (currentValue !== newValue) {
          currentValue = newValue

          if (isMultiple) {
            query = getCurrentQuery()
          } else {
            query = newValue
          }
          console.log(query)

          $input.trigger('autocomplete:request', [query, handleNewSuggestions])
        }
      }

      //
      // handling of navigation through or selecting one of the suggestions
      //
      function handleKeydown (event) {
        if (!$suggestions.is(':visible') || $suggestions.find('div').length === 0) {
          return
        }

        switch (event.keyCode) {
          case KEY.UP:
            event.preventDefault()
            highlightPreviousSuggestion()
            return

          case KEY.DOWN:
            event.preventDefault()
            highlightNextSuggestion()
            return

          case isMultiple && KEY.COMMA:
          case KEY.RETURN:
          case KEY.TAB:
            selectHighlightedSuggestion()

            $suggestions.hide()

            // do not cancel event on TAB
            if (event.keyCode === KEY.TAB) return

            event.preventDefault()
            return

          case KEY.ESC:
            $suggestions.hide()
            return
        }
      }

      //
      function handleBlur (/* event */) {
        $suggestions.hide()

        if (isMultiple) removeTrailingComma()
      }

      //
      function handleSuggestionClick (event) {
        event.preventDefault()
        event.stopPropagation()

        selectSuggestionByElement($(event.currentTarget))
        $suggestions.hide()
      }

      // Internal Methods
      // ----------------

      // http://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
      var regexEscapeLatters = /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g
      var regexTrailingComma = /[,\s]*$/
      var regexSplitWordsWithWhitespace = /\s*,\s*/

      //
      function handleNewSuggestions (suggestions) {
        var html = ''
        var search = currentValue.replace(regexEscapeLatters, '\\$&')
        var regex = new RegExp('(' + search + ')', 'i')

        currentValues = currentValue.trim().split(regexSplitWordsWithWhitespace)
        currentSuggestions = suggestions.map(normalizeSuggestion).filter(newSuggestionsOnly)

        if (currentSuggestions.length === 0) {
          $suggestions.hide()
          return
        }

        currentSuggestions.forEach(function (suggestion, index) {
          var label = suggestion.label
          var highlight = (index === 0) ? ' class="highlight"' : ''

          if (!label) return

          label = htmlEscape(label)

          // select first result per default
          html += '<div' + highlight + '>'
          html += label.replace(regex, '<strong>$1</strong>')
          html += '</div>'
        })
        $suggestions.html(html).show()
      }

      //
      function newSuggestionsOnly (suggestion) {
        if (!suggestion) return
        return currentValues.indexOf(suggestion.value) === -1
      }

      //
      function normalizeSuggestion (suggestion) {
        if (!suggestion) return
        if (typeof suggestion === 'string') {
          return {
            label: suggestion,
            value: suggestion
          }
        }

        return suggestion
      }

      //
      function highlightNextSuggestion () {
        var $highlighted = $suggestions.find('.highlight')
        var $next = $highlighted.next()

        if (!$next.length) return

        $highlighted.removeClass('highlight')
        $next.addClass('highlight')
      }
      //
      function highlightPreviousSuggestion () {
        var $highlighted = $suggestions.find('.highlight')
        var $prev = $highlighted.prev()

        if (!$prev.length) return

        $highlighted.removeClass('highlight')
        $prev.addClass('highlight')
      }

      //
      function selectHighlightedSuggestion () {
        var $highlighted = $suggestions.find('.highlight')
        selectSuggestionByElement($highlighted)
      }

      //
      function selectSuggestionByElement ($element) {
        var selected = currentSuggestions[ $element.index() ]
        var value = selected.value
        if (isMultiple) {
          replaceCurrentWordWith(value)
        } else {
          $input.text(value).focus()
          setCursorAt(value.length)
        }

        $input.trigger('autocomplete:select', [selected])
      }

      function setCursorAt (position) {
        var range = document.createRange()
        var sel = window.getSelection()
        var textNode = $input[0].childNodes.length ? $input[0].childNodes[0] : $input[0]
        position = Math.min(textNode.length, position)
        range.setStart(textNode, position)
        range.collapse(true)
        sel.removeAllRanges()
        sel.addRange(range)
      }

      //
      // to find out what the current word is, we get the current
      // position of the cursor and go through word by word until
      // the total lenght is bigger than the cursor position
      //
      var splitWordsRegex = /,/
      function getCurrentQuery () {
        var cursorAt = getCaretCharacterOffsetWithin($input[0])
        var charCount = 0
        var words = currentValue.split(splitWordsRegex)
        var word

        for (var i = 0; i < words.length; i++) {
          word = words[i]

          // if we are in the current word, we return all characters
          // between the beginning of the current word and the cursor
          // as query
          if (charCount + word.length >= cursorAt) {
            return currentValue.substring(charCount, cursorAt).trim()
          }
          charCount += word.length + 1 // add 1 for the ,
        }

        // we should not get here
        console.log('getCurrentQuery: Could not find query!')
      }

      //
      function replaceCurrentWordWith (newWord) {
        var cursorAt = getCaretCharacterOffsetWithin($input[0])
        var charCount = 0
        var words = currentValue.split(splitWordsRegex)
        var word
        var beforeQuery
        var afterQuery

        for (var i = 0; i < words.length; i++) {
          word = words[i]

          // if we are in the current word, we replace all characters
          // between the beginning of the current word and the cursor
          // with the newly selected word and set the cursor to the end
          if (charCount + word.length >= cursorAt) {
            beforeQuery = currentValue.substring(0, charCount).trim()
            afterQuery = currentValue.substring(cursorAt)
            $input.html(htmlEscape(beforeQuery + ' ' + newWord) + ',&nbsp' + htmlEscape(afterQuery))
            setCursorAt((beforeQuery + ' ' + newWord + ', ').length)
            return
          }
          charCount += word.length + 1 // add 1 for the ,
        }

        // we should not get here
        console.log('replaceCurrentWordWith: Could not find word, returning last')
      }

      // http://stackoverflow.com/questions/4811822/get-a-ranges-start-and-end-offsets-relative-to-its-parent-container/4812022#4812022
      // also: http://stackoverflow.com/questions/22935320/uncaught-indexsizeerror-failed-to-execute-getrangeat-on-selection-0-is-not
      function getCaretCharacterOffsetWithin (element) {
        var caretOffset = 0
        var doc = element.ownerDocument || element.document
        var win = doc.defaultView || doc.parentWindow
        var range, preCaretRange
        if (typeof win.getSelection !== 'undefined' && win.getSelection().rangeCount > 0) {
          range = win.getSelection().getRangeAt(0)
          preCaretRange = range.cloneRange()
          preCaretRange.selectNodeContents(element)
          preCaretRange.setEnd(range.endContainer, range.endOffset)
          caretOffset = preCaretRange.toString().length
        }
        return caretOffset
      }

      //
      function addTrailingComma () {
        var currentValue = $input.text()

        if (currentValue) {
          $input.val(currentValue.replace(regexTrailingComma, ', '))
        }
      }

      //
      function removeTrailingComma () {
        var currentValue = $input.text()
        $input.val(currentValue.replace(regexTrailingComma, ''))
      }

      //
      var regexAmpersands = /&/g
      var regexSingleQuotes = /'/g
      var regexDoubleQuotes = /"/g
      var regexLessThanSigns = /</g
      var regexGreaterThanSigns = />/g
      function htmlEscape (string) {
        return string
          .replace(regexAmpersands, '&amp')
          .replace(regexSingleQuotes, '&#39')
          .replace(regexDoubleQuotes, '&quot')
          .replace(regexLessThanSigns, '&lt')
          .replace(regexGreaterThanSigns, '&gt')
      }

      initialize()
    }

    // AUTOCOMPLETE PLUGIN DEFINITION
    // ==============================

    $.fn.contenteditableAutocomplete = function (/* option */) {
      return this.each(function () {
        var $this = $(this)
        var api = $this.data('bs.contenteditableAutocomplete')

        if (!api) {
          $this.data('bs.contenteditableAutocomplete', (api = new ContenteditableAutocomplete(this)))
        }
      })
    }

    $.fn.contenteditableAutocomplete.Constructor = ContenteditableAutocomplete

    // EDITABLE TABLE DATA-API
    // =======================

    $(document).on('focus.bs.contenteditableautocomplete.data-api', '[data-autocomplete-spy]', function (event) {
      var $input = $(event.currentTarget)

      event.preventDefault()
      event.stopImmediatePropagation()

      $input.removeAttr('data-autocomplete-spy').contenteditableAutocomplete()
      $input.trigger($.Event(event))
    })
  }

  // if run in a browser, init immediately
  if (typeof window !== 'undefined' && window.jQuery) {
    contenteditableAutocomplete(window.jQuery)
  }


/***/ },
/* 2 */
/***/ function(module, exports) {

  // removed by extract-text-webpack-plugin

/***/ }
/******/ ]);


/****************************************
 *  jQuery 上下文菜单插件，支持多级菜单和图标显示，
 *  自定义样式实现灵活控制菜单风格
 *
 *  在 MTI 许可下，可自由分发、修改、复制该代码。
 *  可以在你的项目（不限于商业盈利性项目）下免费
 *  使用源码
 *
 *  @copyright jhoneleeo@gmail.com
 *  @version 1.0.0
 *  Date: 2017-3-5
 ****************************************/
(function ($) {
    /**
     * 为对象绑定上下文菜单方法
     * @function contextMenu
     * @param {Object} data 菜单数据。由text、items、action组成的对象数组
     * @param {Object} options 配置参数
     */
    $.fn.contextMenu = function (data, options) {

        var $body = $("body"),
            defaults = {
                name: "",  // 字符串。上下文菜单的名称，用以区分不同的上下文菜单。如果缺省，插件将自动分配名称
                offsetX: 15, // 数值。上下文菜单左上角距离鼠标水平偏移距离
                offsetY: 5, // 数值。上下文菜单左上角距离鼠标垂直偏移距离
                beforeShow: $.noop, // 函数。菜单即将显示之前执行的回调函数
                afterShow: $.noop // 函数。菜单显示后执行的回调函数
            };

        var params = $.extend(defaults, options || {}), keyMap = {},
            idKey = "site_cm_", classKey = "site-cm-",
            name = name || ("JCM_" + +new Date() + (Math.floor(Math.random() * 1000) + 1)),
            count = 0;

        /**
         * 构建菜单HTML
         * @param {*} mdata 菜单数据，如果没有菜单数据以data数据为准
         */
        var buildMenuHtml = function (mdata) {
                // 菜单数据
                var menuData = mdata || data,
                    idName = idKey + (mdata ? count++ : name),
                    className = classKey + "box";

                var $mbox = $('<div id="' + idName + '" class="' + className + '" style="position:absolute; display: none;">');

                $.each(menuData, function (index, group) {
                    if (!$.isArray(group)) {
                        throw TypeError();
                    }
                    index && $mbox.append('<div class="' + classKey + 'separ">');
                    if (!group.length) {
                        return;
                    }
                    var $ul = $('<ul class="' + classKey + 'group">');
                    // 循环遍历每组菜单
                    $.each(group, function (innerIndex, item) {
                        // 需要检测菜单项目是否包含子菜单
                        var key, $li = $("<li>" + item.text + ($.isArray(item.items) && item.items.length ? buildMenuHtml(item.items) : "") + "</li>");
                        $.isFunction(item.action) && (key = (name + "_" + count + "_" + index + "_" + innerIndex), keyMap[key] = item.action, $li.attr("data-key", key));
                        $ul.append($li).appendTo($mbox);
                    });
                });
                var html = $mbox.get(0).outerHTML;
                $mbox = null;
                return html;
            },
            // 创建上下文菜单
            createContextMenu = function () {
                var $menu = $("#" + idKey + name);
                if (!$menu.length) {
                    var html = buildMenuHtml();
                    $menu = $(html).appendTo($body);
                    $("li", $menu).on("mouseover", function () {
                        $(this).addClass("hover").children("." + classKey + "box").show();
                    }).on("mouseout", function () {
                        $(this).removeClass("hover").children("." + classKey + "box").hide();
                    }).on("click", function () {
                        var key = $(this).data("key");
                        key && (keyMap[key].call(this) !== false) && $menu.hide();  // 调用执行函数
                    });
                    $menu.on("contextmenu", function () {
                        return false;
                    });
                }
                return $menu;
            };

        $body.on("mousedown", function (e) {
            var jid = ("#" + idKey + name);
            !$(e.target).closest(jid).length && $(jid).hide();
        });

        return this.each(function () {

            $(this).on("contextmenu", function (e) {

                if ($.isFunction(params.beforeShow) && params.beforeShow.call(this, e) === false) {
                    return;
                }

                e.cancelBubble = true;
                e.preventDefault();

                var $menu = createContextMenu();

                $menu.show().offset({left: e.clientX + params.offsetX - 240, top: e.clientY + params.offsetY + window.scrollY + 10});

                $.isFunction(params.afterShow) && params.afterShow.call(this, e)
            });

        });
    };
})(jQuery);


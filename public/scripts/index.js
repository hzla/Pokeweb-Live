$( document ).ready(function() {
    

///////////////////// EVENT BINDINGS //////////////////////////
    

    //////////////// Rom Buttons //////////////////
    
    $(document).on('click', '#load-rom', function(){
        var rom_name = $('#rom-select').val()
        $(this).text('loading...')
        $.post( "extract", {rom_name: rom_name }, function( data ) {
          window.location.href = data["url"]
        });
    })

    $(document).on('click', '#save-rom', function(){
    	btn = $(this)
    	btn.text('Exporting...')
        
        $.post( "/rom/save", function( data ) {
        	alert("saved to /exports folder")
        	btn.text('Export')
        });
    })


    //////////////// Filters ////////////////////////


    $('.gen-filters button, .type-filters button').on('click', function(){
    	$(this).toggleClass('-active')
    	filter()
    })
    $('#search-text-btn').on('click', function(){	
    	filter()
    })
    $('#search-text').on('keypress',function(e) {
	    if(e.which == 13) {
	        filter()
	    }
	});
	///////////////////////////////////////////////////////////////////////


	////////////////////// POKEMON PERSONAL CARD UI ////////////////////////
	 
	$(document).on('click', '.expand-card', function(){
		expanded_card = $(this).attr('data-expand')

		// if hiding tab
		console.log('.expanded-' + expanded_card + ":visible")
		if ($(this).parent().find('.expanded-' + expanded_card + ":visible").length > 0) {
			$(this).parent().find('.expanded-card-content').removeClass('show-flex')
			$(this).css('box-shadow', '')
		} else { // else switching tabs
			$(this).parent().find('.expanded-card-content').removeClass('show-flex')
			$(this).parent().find('.expanded-' + expanded_card).addClass('show-flex');
			$(this).parent().find('.card-icon').css('box-shadow', '')
			$(this).css('box-shadow', '2px 3px 15px #3498db')
		}
	})

	$(document).on('click', '.retract-card', function(){
		expanded_card = $(this).attr('data-retract')
		$(this).parents('.pokemon-card').find('.expanded-' + expanded_card).hide()
		$(this).parents('.pokemon-card').find('.expand-card').show()
		$(this).parents('.pokemon-card').find('.exp-' + expanded_card).show();
	})

	/////////////////////////////// DATA UPLOAD ON EDIT ///////////////////////////////



	$(document).on('focusout', "[contenteditable='true']", function(){
		var value = $(this).text().trim()
		$(this).text(value)
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.pokemon-card').attr('data-index')
		var narc = $(this).attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc
		
		if ($(this).attr('data-type') && $(this).attr('data-type').includes("int")) {
			data["int"] = true
			max_value = parseInt($(this).attr('data-type').split("-")[1])
			//validate int fields
			if (!parseInt(value) || parseInt(value) > max_value ) {
				$(this).css('border', '1px solid red')
				return
			}
		} else {
			// validate string fields
			console.log("validating string...")
			valid_fields = autofills[$(this).attr('data-autofill')]
			if (!valid_fields.includes(value)) {
				$(this).css('border', '1px solid red')
				return
			}
		}

		// validate required fields
		if ($(this).attr('data-require')) {
			required_field = "." + $(this).attr('data-require')
			required_input = $(this).parents('.expanded-field').find(required_field)

			console.log(required_input.text())
			if (required_input.text() == "" || required_input.text() == "-" ) {
				required_input.css('border', '1px solid red')
			}
		}

		$(this).css('border', '')

		$.post( "/personal", {"data": data }, function( data ) {
          console.log(data)
        });
	})


	$(document).on('click', "[contenteditable='true']", function(e){
		console.log()
		$(this).selectText()
	})


	$(document).on('keypress', "[contenteditable='true']", function(e){
		if(e.which == 13) {
	        $(this).blur()
	    }
	})

	$(document).on('focusout', ".pokemon-type[contenteditable='true']", function(){
		var value = $(this).text().trim()
		$(this).removeClass().addClass('pokemon-type').addClass("-" + value.toLowerCase())
	})

	$(document).on('focusout', ".move-name[contenteditable='true']", function(){
		var value = $(this).text().trim()
		move_data = Object.values(moves).find(e => e["name"].toLowerCase().toCamelCase() == value.toLowerCase().toCamelCase() )

		console.log(move_data)
		if (move_data) {
			type = move_data["type"] 
			power = move_data["power"]
			acc = move_data["accuracy"]

			row = $(this).parents('.expanded-field')

			row.find('button').removeClass().addClass('btn').addClass('-active').addClass("-" +type.toLowerCase()).text(type.toUpperCase().slice(0,3))
			row.find('.mov-cat img').show().attr("src", "/images/move-" + type.toLowerCase() + ".png")

			row.find('.move-power').text(power)
			row.find('.move-accuracy').text(acc)
		}

	})

	$(document).on('focusout', "td[contenteditable='true']", function(){
		var value = $(this).text().trim()


		value = parseInt(value)
		var width = value / 2.55
		$(this).parent().find(".pokemon-card__graph").css('width', width.toString() + "%")
	})

	$(document).on('autocomplete:request', "[contenteditable='true']", function(event, query, callback) {
	  var suggestions = autofills[$(this).attr('data-autofill')].filter(function(e){
	  	return e.toLowerCase().includes(query.toLowerCase())
	  });
	  callback(suggestions);
	})


})

////////////////////////////////////////////////////////////////////////

function filter() {
	cards = $('.pokemon-card')
	
	gen_filters = ""
	type_filters = ""
	text_filters = ""

	//ex: "134"
	gen_filters = $('.gen-filters button.-active').text() 

	// ex: "fighing, rock"
	$('.type-filters button.-active').each(function(){
		type_filters += $(this).attr('data-ptype') + " "
	})

	// ex "hello world"
	text_filters = $('#search-text').val()

	
	if (gen_filters || type_filters || text_filters) {
		cards.hide()
	} else {
		cards.show()
		return
	}
	
	search_results = pokemons.filter(function(e) {
		if (!e) {
			return false
		}
		gen = e["gen"]
		type_1 = e["type_1"].toLowerCase()
		type_2 = e["type_2"].toLowerCase()

		gen_match = false
		type_match = false
		text_match = false
		
		if (gen_filters) {
			gen_match = gen_filters.includes(gen)
		} else { // when no gen filter
			gen_match = true
		}

		if (type_filters) {
			type_match = (type_filters.includes(type_1) || type_filters.includes(type_2))
		} else { // when no type filter
			type_match = true
		}
		

		if (text_filters) {
			texts = text_filters.split(" ")
			for (text in texts) {
				// console.log(texts)
				text = texts[text]
				text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
				if (text_match ) {break;}
			} 
		} else { // when no text filter
			text_match = true
		}

		if (type_match && gen_match && text_match) {
			$(cards[e["index"] - 1]).show()
		}

		return type_match && gen_match && text_match
	})
}

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
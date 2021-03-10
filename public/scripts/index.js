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
		$(this).parents('.pokemon-card').find('.expanded-card-content').css('display', 'flex');
		$(this).hide()
	})

	$(document).on('click', '.retract-card', function(){
		$(this).parents('.pokemon-card').find('.expanded-card-content').hide()
		$(this).parents('.pokemon-card').find('.expand-card').show();
	})

	/////////////////////////////// DATA UPLOAD ON EDIT ///////////////////////////////



	$(document).on('focusout', "[contenteditable='true']", function(){
		var value = $(this).text().trim()
		$(this).text(value)
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.pokemon-card').attr('data-index')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		
		if ($(this).attr('data-type') == "int") {
			data["int"] = true
			
			//validate int fields
			if (!parseInt(value) || parseInt(value) > 255 ) {
				$(this).css('border', '1px solid red')
				return
			}

			// validate ev fields
			if ($(this).hasClass('ev-field')) {
				if (!parseInt(value) || parseInt(value) > 3 ) {
					$(this).css('border', '1px solid red')
					return
				}
			}
		} else {
			// validate string fields
			valid_fields = autofills[$(this).attr('data-autofill')]
			if (!valid_fields.includes(value)) {
				$(this).css('border', '1px solid red')
				return
			}
		}

		$(this).css('border', '')


		console.log(data)



		$.post( "/personal", {"data": data }, function( data ) {
          console.log(data)
        });
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

	$(document).on('focusout', "td[contenteditable='true']", function(){
		var value = $(this).text().trim()
		console.log(value)

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

	console.log(gen_filters)
	
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
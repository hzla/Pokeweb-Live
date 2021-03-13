$( document ).ready(function() {
    

///////////////////// EVENT BINDINGS //////////////////////////
    

    //////////////// Rom Buttons //////////////////
    
    $(document).on('click', '#load-rom', function(){
        var rom_name = $('#rom-select').val()
        $(this).text('loading...')
        $.post( "extract?rom_name=" + rom_name , {rom_name: rom_name }, function( data ) {
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


    $('.small-filters button').on('click', function(){
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
	
	// delay to bind to replaced svgs


	$(document).on('click', '.expand-action', function(){
		expanded_card = $(this).attr('data-expand')

		// console.log($(this).parents('.filterable').find('.expanded-card-content'))
		// if hiding tab
		if ($(this).parents('.filterable').find('.expanded-' + expanded_card + ":visible").length > 0) {
			$(this).parents('.filterable').find('.expanded-card-content').removeClass('show-flex')
			$(this).removeClass('-active')
		} else { // else switching tabs
			$(this).parents('.filterable').find('.expanded-card-content').removeClass('show-flex')
			
			$(this).parents('.filterable').find('.expanded-' + expanded_card).addClass('show-flex');
			$(this).parents('.filterable').find('.card-icon').removeClass('-active')
			$(this).addClass('-active')
		}
	})	

	
	
	/////////////////////////////// DATA UPLOAD ON EDIT ///////////////////////////////


	$(document).on('focusout', "[contenteditable='true']", function(){
		var value = $(this).text().trim()
		$(this).text(value)
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc
		
		if ($(this).attr('data-type') && $(this).attr('data-type').includes("int")) {
			data["int"] = true
			max_value = parseInt($(this).attr('data-type').split("-")[1])
			
			//validate int value less than max if int field
			if ((!parseInt(value) || parseInt(value) > max_value ) && parseInt(value) != 0) {
				$(this).css('border', '1px solid red')
				return
			}
		} else {
			// validate string in autofill bank if string field
			valid_fields = autofills[$(this).attr('data-autofill')]
			valid_fields = JSON.stringify(valid_fields).toLowerCase()

			if (!valid_fields.includes(value.toLowerCase())) {
				$(this).css('border', '1px solid red')
				return
			}
		}

		// validate required fields
		if ($(this).attr('data-require')) {
			required_field = "." + $(this).attr('data-require')
			required_input = $(this).parents('.expanded-field').find(required_field)

			if (required_input.text() == "" || required_input.text() == "-" ) {
				required_input.css('border', '1px solid red')
			}
		}

		$(this).css('border', '')
		console.log(data)
		
		// send data to server
		$.post( "/personal", {"data": data }, function( e ) {     
          console.log('upload successful')
        });
	})

	//high light text on click
	$(document).on('click', "[contenteditable='true']", function(e){
		$(this).selectText()
	})

	// upload choice when clicking 
	$(document).on('click', ".choosable", function(e){
		var value = $(this).attr('data-value')
		var field_name = $(this).parent().attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).parent().attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc

		$(this).parent().children().removeClass('chosen').addClass('unchosen')
		$(this).addClass('chosen').removeClass('unchosen')

		console.log(data)
		$.post( "/personal", {"data": data }, function( e ) {     
          console.log('upload successful')
        });
	})

	$(document).on('click', ".move-prop", function(e){
		$(this).toggleClass('-active')

		var value = ($(this).hasClass('-active') ? 1 : 0)
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).parent().attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc
		data["int"] = true
		
		console.log(data)
		$.post( "/personal", {"data": data }, function( e ) {     
          console.log('upload successful')
        });	
	})





	//blur box on enter
	$(document).on('keypress', "[contenteditable='true']", function(e){
		if(e.which == 13) {
	        $(this).blur()
	    }
	})

	// add pokemon type class to change color 
	$(document).on('focusout', ".pokemon-type[contenteditable='true'], .move-type .btn", function(){
		var value = $(this).text().trim()
		$(this).removeClassPrefix("-").addClass("-" + value.toLowerCase())
		
		if ($(this).parents('.move-type').length > 0) {
			$(this).addClass('-active')
		}
	})

	// expand move data 
	$(document).on('focusout', ".move-name[contenteditable='true']", function(){
		var value = $(this).text().trim()
		move_data = Object.values(moves).find(e => e["name"].toLowerCase().toCamelCase() == value.toLowerCase().toCamelCase() )

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

	// adjust base stat bar length
	$(document).on('focusout', "td[contenteditable='true']", function(){
		var value = $(this).text().trim()

		value = parseInt(value)
		var width = value / 2.55
		$(this).parent().find(".pokemon-card__graph").css('width', width.toString() + "%")
	})


	$(document).on('autocomplete:request', "[contenteditable='true']", function(event, query, callback) {
	  console.log("acing")
	  var suggestions = autofills[$(this).attr('data-autofill')].filter(function(e){
	  	return e.toLowerCase().includes(query.toLowerCase())
	  });
	  callback(suggestions);
	})


})

//////////////////////////////  FUNCTIONS //////////////////////////////////////////

function filter() {
	cards = $('.filterable')
	
	gen_filters = ""
	type_filters = ""
	text_filters = ""
	cat_filters = ""

	//ex: "134"
	gen_filters = $('.gen-filters button.-active').text() 

	// ex: "fighing, rock"
	$('.type-filters button.-active').each(function(){
		type_filters += $(this).attr('data-ptype') + " "
	})

	// ex "hello world"
	text_filters = $('#search-text').val()

	selected_cats = $('.cat-filters button.-active img')
	selected_cats.map(n => cat_filters += $(selected_cats[n]).attr('data-mcat'))


	// show all cards if no filters selected
	if (gen_filters || type_filters || text_filters || cat_filters) {
		cards.hide()
	} else {
		cards.show()
		return
	}
	
	if ($('#personals').length > 0) {
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
				texts = text_filters.split(",")
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

	if ($('#moves').length > 0) {		
		move_list = Object.values(moves).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})

		search_results = move_list.filter(function(e) {
			e = e[1]
			if (!e["type"]) {
				return false
			}
			
			type = e["type"].toLowerCase()
			cat = e["category"].toLowerCase()

			type_match = false
			text_match = false
			cat_match = false

			if (cat_filters) {
				cat_match = cat_filters.includes(cat)
			} else { // when no type filter
				cat_match = true
			}
			
			if (type_filters) {
				type_match = type_filters.includes(type)
			} else { // when no type filter
				type_match = true
			}
			
			if (text_filters) {
				texts = text_filters.split(",")
				for (text in texts) {
					// console.log(texts)
					text = texts[text]
					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (type_match && text_match && cat_match) {
				$(cards[e["index"]]).show()
			}

			return type_match && cat_match && text_match
		})
	}
	
}


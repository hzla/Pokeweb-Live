
edit_in_progress = false
async function postData(url = "", data = {}) {
  // Default options are marked with *
  const response = await fetch(url, {
    method: "POST", // *GET, POST, PUT, DELETE, etc.
    mode: "cors", // no-cors, *cors, same-origin
    cache: "no-cache", // *default, no-cache, reload, force-cache, only-if-cached
    credentials: "same-origin", // include, *same-origin, omit
    headers: {
      "Content-Type": "application/json",
      // 'Content-Type': 'application/x-www-form-urlencoded',
    },
    redirect: "follow", // manual, *follow, error
    referrerPolicy: "no-referrer", // no-referrer, *no-referrer-when-downgrade, origin, origin-when-cross-origin, same-origin, strict-origin, strict-origin-when-cross-origin, unsafe-url
    body: JSON.stringify(data), // body data type must match "Content-Type" header
  });
  return response.json(); // parses JSON response into native JavaScript objects
}


$(document).on('click', '#load-save', async function() {
		
		var file = $('#save-upload')[0].files[0]
		var level = $('#save-lvl').val()

		
		let formData = new FormData();           
	    formData.append("file", file);
	    formData.append("level", level);
	    formData.append("game", window.location.href.split("/").pop());

	    const response = await fetch(`/read_save`, {
	      method: "POST", 
	      body: formData
	    })

	    showdown = await response.text()

	    $('#showdown-export').val( JSON.parse(showdown)["showdown"])
	    $('#showdown-export').selectRange(0, -1);

	    console.log(JSON.parse(showdown))
	    $("#debug-info").val(JSON.stringify(JSON.parse(showdown)["debug_info"]))
	})



$(document).on('change', '#save-upload', function(){

	$('#save-upload-btn').text($(this).val().split('\\').pop())
})

$(document).on('keyup', '#save-lvl', function(){

	if ($('textarea').val() != ""){
		var lines = $('textarea').val().split("\n")

		for (i in lines) {
			line = lines[i]
			if (line.includes("Level: ")) {
				lines[i] = `Level: ${$(this).val()}`
			}
		}

		$('textarea').val(lines.join("\n"))
	}
	
})


$(document).ready(function() {
	console.log("ready")
	editable_menu = [
	    [{
	      text: "Apply to all displayed entries",
	      action: function (e, i) {
	      	var value = current_edit.text().trim()
			current_edit.text(value)
			var field_name = current_edit.attr('data-field-name')
			var narc = current_edit.attr('data-narc')

			to_change = $('.filterable:visible')
			file_count = to_change.length

			var data = {}


			data["field"] = field_name
			data["value"] = value
			data["narc"] = narc


			if (current_edit.css('border') == '1px solid rgb(255, 0, 0)') {
				alert("Value is not valid")
				return
			}


			if (confirm(`You are about to change the ${field_name} of every displayed entry to ${value}. Proceed to change all ${file_count} entries?`)){
				file_names = []

				to_change.each(function(i,v) {
					file_names.push($(v).attr('data-index'))
				})
				data ["file_names"] = file_names

				$.post( "/batch_update", {"data": data }, function( e ) {     
					alert("Update completed")		
	        

		        });
		        $(`.filterable:visible [data-field-name='${field_name}']`).text(value)

		        if (current_edit.hasClass('enc-slot')) {
		        	$('.filterable:visible').each(function(i,v) {
		        		updateWilds($(v));
		        	})
		        }

		        if (current_edit.hasClass('trpok-name')) {
		        	var pok_index = current_edit.parents('.expanded-pok').index() - 2
		        	$('.filterable:visible').each(function(i,v) {
		        		updateTrImage(value, $(v), pok_index )
		        	})
		        }
		        alert("Update in progress, please wait for completion notification before making any changes")
			} 

	      }
	    }]
	];

	copy_menu = [
	    [{
	      text: "Copy to other seasons",
	      action: function (e, i) {
	      	console.log(current_season)
	      	console.log(current_encounter)
	      	var data = {}
	      	data["season"] = current_season
	      	data["id"] = current_encounter
	      	if (confirm(`Copy ${current_season} to other seasons in enc file ${current_encounter}? Changes will not be reflected in ui until page is refreshed`)){

				$.post( "/encounter_season_copy", {"data": data }, function( e ) {     
						
	        

		        });
			} 

			

	      }
	    }]
	];

	$(".season-icon").contextMenu(copy_menu)
	$(":not(.log-text, .editable-doc, .pallete-color, .color-label)[contenteditable='true']").contextMenu(editable_menu)
	console.log("menu ready")

	get_offset = function(height, direction) {
		var offsets = [0,0,0,0]
		if (height >= 12) {
			offsets = [0,3,6,9]
		}
		if (height == 16) {
			offsets = [0,4,8,12]
		}
		if (height == 2) {
			offsets = [0,4,8,12]
		}
		if (height == 6 || height == 7|| height == 9) {
			offsets = [0,3,5,"f"]
		}

		return offsets[direction]
	}

	adjust_directions = function(){
		$('.overworld-sprite').each(function(){
			var sprite_height = Math.round($(this)[0].naturalHeight / 32)
			var direction = $(this).parent().attr('data-dir')
			var offset = get_offset(sprite_height, direction)
			if (offset == "f") {
				$(this).css("top", `-${5 * 32}px`)
				$(this).css("transform", "scaleX(-1)")
			} else {
				$(this).css("top", `-${offset * 32}px`)
			}
		})


	}
	setTimeout(adjust_directions, 1000)

	if ($('#offline').length > 0) {   
	    $(document).on('click', '#load-rom', function(){

	        	console.log($('#xdelta').length)
	        	var rom_name = $('#rom-select').val()
	        	var fairy = $('#fairy-checkbox').is(':checked')
		        $(this).text('loading...')
		        $.post( "extract_rom?rom_name=" + rom_name , {rom_name: rom_name, fairy: fairy }, function( data ) {
		          window.location.href = data["url"]
		        });     
	    })
    }

    $(document).on('click', '#extract-file', function(){

        	var file_path = $('#file-path').val()
        	var file_index = $('#file-index').val()
	        
	        $.get(`file/${file_path}/${file_index}`)
    })

})


///////////////////// EVENT BINDINGS //////////////////////////
    
    //////////////// Rom Buttons //////////////////
  
    $(document).on('submit', '#rom-form', function(e){
    	
    	var rom_name = $('#rom-name').val()
    	var file_name = $('#xdelta').val()

    	if (rom_name.slice(-4) != ".nds" ){
    		e.preventDefault()
    		$('#rom-name').css('border', '1px solid red')
    		alert("rom name must end in .nds")
    		return 
    	}

    	if (hasWhiteSpace(rom_name) || hasWhiteSpace(file_name)) {
    		e.preventDefault()
    		$('#rom-name').css('border', '1px solid red')
    		alert("rom name and xdelta file cannot contain spaces")
    		return
    	}

    	if (file_name == "") {	
    		if (!confirm("No xdelta detected, load the default base rom?")) {
    			e.preventDefault()
    			return false
    		}
    	}

    	rom_name = rom_name.slice(0,-4)


    	var project_names = []
    	$('#project-select option').each(function(){
    		project_names.push($(this).val().split("/")[1])
    	})


    	console.log(project_names)

    	if (project_names.includes(rom_name)) {
    		e.preventDefault()
    		$('#rom-name').css('border', '1px solid red')
    		alert("That name has already been taken")
    		return 	
    	}
    })




	$(document).on('change', '#xdelta', function() {
		if(this.files[0].size > 50000000){
	       alert("This file is too big, Make sure this is an xdelta between the rom you want to edit and the original base rom and NOT an xdelta between the rom you want to edit and a blank rom. Join DS Hacking Discord https://discord.gg/zAtqJDW2jC for more info");
	       this.value = "";
	    };
	})

	$(document).on('change', '#save-upload', function() {
		if(this.files[0].size > 1000000){
	       alert("This file is too big");
	       this.value = "";
	    };
	})

    $(document).on('click', '#randomize', function(e){
        if (confirm('Randomization is irreversible and will take 4-5 minutes. Are you sure?')) {
        	window.location.href = '/randomize'
        }

    })

    $(document).on('click', '#save-rom', function(){
    	btn = $(this)
    	btn.text('Exporting...')
        
    })

    //  $(document).on('click', '#load-project', function(){
    // 	var rom_name = $('#project-select').val()
    // 	var pw = $('#rom-pw').val()
    //     $(this).text('loading...')
    //     console.log("loading")
    //     $.get( "/load_project", {"project": rom_name, "pw": pw }, function( data ) {
    //     	window.location.href = data["url"]
    //     });
    // })


    //////////////// Filters ////////////////////////


    $(document).on('click', '.small-filters button', function(){
    	$(this).toggleClass('-active')
    	filter()
    })

    $(document).on('click', '#header', function(){
    	if (screen.width <= 1180) {
    		$('.header-item').toggle()
    		$('.header-item.-active').show()
    	}
    	
    })


    $(document).on('swipeup', '#header', function(){
    	$('.header-item').hide()
    	$('.header-item.-active').show()
    })
    $(document).on('click', '#search-text-btn', function(){	
    	filter()
    })

    $(document).on('click', '.settings-toggle', function(){	
    	var field = $(this).attr('data-field')
    	$.get(`/settings/set?field=${field}`, function(data){ 
    		console.log(data)
    		alert(`${field} changed to ${data}`)
    	})
    })

    $(document).on('keypress', '#search-text', function(e){
	    if(e.which == 13) {
	        filter()
	    }
	});

	$(document).on('click', '#search-textbanks-btn', function(){	
		terms = $('#search-textbanks').val() 
		var text_bank = window.location.href.split("/")[3].split("_")[0]

		var url = `/${text_bank}_texts/search?terms=${terms}`
		if ($('.filter-check input:checked').length > 0) {	
			url += '&ignore_case=true'
		}
		location.replace(url);
    })

    $(document).on('keypress', '#search-textbanks', function(e){
	    if(e.which == 13) {
	    	terms = $('#search-textbanks').val() 
			text_bank = window.location.href.split("/")[3].split("_")[0]
			url = `/${text_bank}_texts/search?terms=${terms}`
			if ($('.filter-check input:checked').length > 0) {	
				url += '&ignore_case=true'
			}
			location.replace(url);
		    }
	});


	///////////////////////////////////////////////////////////////////////


	////////////////////// POKEMON PERSONAL CARD UI ////////////////////////
	
	// delay to bind to replaced svgs

	// $(document).on('dblclick', '.spreadsheet .filterable', function(){
	// 	element = $(this)
	// 	$([document.documentElement, document.body]).animate({
	//         scrollTop: (element.offset().top - 100)
	//     }, 100);
	//     element.find('.expand-action').first().click()
	//     clearSelection()
	// })

	$(document).on('dblclick', '.spreadsheet .text-header', function(){
		element = $(this)

		if (element.hasClass('expanded')) {
			element.next().children().hide()
			element.next().children().first().show()
			element.removeClass('expanded')
			return
		}

		narc = $('#texts').attr('data-narc')
		bank_id = $(this).attr('data-index')
        element.addClass('expanded')
        $.get( `texts/${narc}/${bank_id}`, function( data ) {
        	element.next().html(data)
        });
	})



	$(document).on('click', '.expand-action', function(){
		expanded_card = $(this).attr('data-expand')
		var card = $(this).parents('.filterable')
		// console.log($(this).parents('.filterable').find('.expanded-card-content'))
		// if hiding tab
		element_to_scroll = $(this).parents('.filterable')
		$([document.documentElement, document.body]).animate({
	        scrollTop: (element_to_scroll.offset().top - 100)
	    }, 100);


		// lazy load personal content because it's too laggy to load it all 
	    if ($('#personals').length > 0 && card.find('.expanded-card-content').length == 0 ) {
	    	index = card.attr('data-index')
	    	console.log("retrieving personal info")
	        $.ajax({
			    url: "/expanded_personal/" + index,
			    type: "get",
			    async: false,
			    success: function( e ) {     
		          card.find('table').after(e)
		          card.find("[contenteditable='true']").contextMenu(editable_menu)
		          	$('.filterable, .expanded-card-content').css('background', '')
					$('.filterable:visible:odd, .filterable:visible:even .expanded-card-content').css('background', '#383a59');
					$('.filterable:visible:even, .filterable:visible:odd .expanded-card-content').css('background', '#282a36'); 
		        }
			 });

	    }


		if (card.find('.expanded-' + expanded_card + ":visible").length > 0) {
			card.find('.expanded-card-content').removeClass('show-flex')
			$(this).removeClass('-active')
			card.find('.expanded-tab-icons').removeClass('show-flex')
		} else { // else switching tabs
			card.find('.expanded-card-content').removeClass('show-flex')
			
			card.find('.expanded-tab-icons').addClass('show-flex')
			card.find('.expanded-' + expanded_card).first().addClass('show-flex');
			console.log(expanded_card)

			card.find('.expanded-tab-icon').removeClass('-active')
			card.find('.expanded-tab-icon').first().addClass('-active')

			card.find('.card-icon, .expand-action').removeClass('-active')
			$(this).addClass('-active')
		}
	})	

	$(document).on('click', '.expanded-tab-icon', function(){
		expanded_tab = $(this).attr('data-show')
		var card = $(this).parents('.filterable')
		var tab_group = '.expanded-' + card.find('.expand-action.-active').attr('data-expand')

		if (card.find('.expanded-' + expanded_tab + ":visible").length > 0) {
			// do nothing

		} else { // else switching tabs
			card.find('.expanded-card-content').removeClass('show-flex')
			
			card.find('.expanded-' + expanded_tab + tab_group).addClass('show-flex');
			card.find('.expanded-tab-icon').removeClass('-active')
			$(this).addClass('-active')
		}
	})	

	$(document).on('click', '.trainer-poks img', function(){
		expanded_tab = $(this).attr('data-show')
		var card = $(this).parents('.filterable')

		element_to_scroll = $(this).parents('.filterable')
		$([document.documentElement, document.body]).animate({
	        scrollTop: (element_to_scroll.offset().top - 100)
	    }, 100);

		if (card.find('.expanded-' + expanded_tab + ":visible").length > 0) {
			// do nothing
			card.find('.expanded-pok').removeClass('show-flex')
			$(this).removeClass('-active')
		} else { // else switching tabs
			card.find('.expanded-pok').removeClass('show-flex')
			card.find('.expanded-' + expanded_tab).addClass('show-flex');
			
			card.find('.trainer-poks img').removeClass('-active')
			$(this).addClass('-active')
		}
	})	

	$(document).on('click', '.overworld-item', function(){
		keys = Object.keys(overworld).filter((key) => key.includes($(this).attr("data-id")))

		$('.overworld-item').removeClass("selected")
		$(this).addClass("selected")
		$('#del-npc').attr('data-npc-index', $(this).attr("data-id"))

		for (n in keys) {
			
			var fieldName = keys[n].split($(this).attr("data-id"))[1] 

			$(`#${fieldName}`).text(overworld[keys[n]])
			$(`#${fieldName}`).attr("data-field-name", keys[n])
		}
	})

	$(document).on('click', '.tile', function(){
		var index = $(this).attr('data-index')
		var map_id = $(this).attr('data-map')
		var flag = $(this).attr('data-perm')
		var mov = $(this).attr('data-mov')


		$('.popup-editor').show()
		$('.popup-editor').attr('data-index', map_id)
		$('.popup-editor').attr('data-map', index)
		$('.popup-editor').find('#tile-flag').text(flag)
		
		var flag_field = $('.popup-editor').find('#tile-flag')
		var mov_field = $('.popup-editor').find('#tile-mov')
		
		flag_field.text(flag)
		mov_field.text(mov)
		flag_field.attr('data-field-name',`layer_2_index_${index}`)
		mov_field.attr('data-field-name',`layer_3_index_${index}`)
	})	

	$(document).on('click', '#del-text', function(){	
		var count = parseInt($(this).parent().find('.sb-field').val())
		
		for(var i = 0; i < count; i++){
		   $('#texts').children().last().remove()
		   $('#texts').children().last().remove()
		}
	})

	$(document).on('click', '#add-text', function(){	
		var count = parseInt($(this).parent().find('.sb-field').val())
		
		// create empty msg
		var last_msg = $('.text-bank').last().clone()
		var empty_line = last_msg.find('.expanded-field').last()
		last_msg.html(empty_line)
		
		var last_header = $('.text-header').last().clone()
		var last_msg_id = parseInt(last_msg.attr('data-index'))
		


		for(var i = 0; i < count; i++){
		    
			last_header.find('.log-text').text(`MSG ${last_msg_id + i + 1}`)
		    last_msg.attr('data-index', last_msg_id + i + 1)

		    $('#texts').append(last_header.clone())
		    $('#texts').append(last_msg.clone())

		}
	})

	$(document).on('click', '#add-npc', function(){	
		base_url = window.location.href.split("?")[0]
		$.put(base_url + `/npc`, data => {
			var new_ow_id = parseInt($(".overworld-item").last().attr("data-id").split("_")[1]) + 1
			new_ow_id = `npc_${new_ow_id}_`
			$.get(base_url + `/box?selected=${new_ow_id}`, data => {		
				$("#overworld").html(data)
				$(".overworld-item").last().click()
				adjust_directions()
			})
		})	
	})

	$(document).on('click', '#del-npc', function(){	
		base_url = window.location.href.split("?")[0]

		if ($('#del-npc').attr('data-npc-index') == '') {
			alert('no npc selected')
			return
		}

		var npc_index = $(this).attr('data-npc-index').split("_")[1]

		$.delete(base_url + `/npc?npc_index=${npc_index}`, data => {
			$.get(base_url + `/box?selected`, data => {		
				$("#overworld").html(data)
				adjust_directions()
			})
		})	
	})	

	$(document).on('click', '.script-btn', function(){	
		var btn = $(this)
		var url = btn.attr('href')
		$.get(url, function(){
			if (btn.attr('id') == "save-script") {
				alert("Script Applied")
			}
		})	
	})	


	
	 document.onkeydown = function (event) {
      if ($("#overworld").length > 0) {
	      switch (event.keyCode) {
	         case 37:
	            console.log("Left key is pressed.");
	            $('#x_cord').text(parseInt( $('#x_cord').text()) - 1)
	            $('#x_cord').focus().blur()
	            break;
	         case 38:
	            console.log("Up key is pressed.");
	            $('#y_cord').text(parseInt( $('#y_cord').text()) - 1)
	            $('#y_cord').focus().blur()
	            break;
	         case 39:
	            console.log("Right key is pressed.");
	            $('#x_cord').text(parseInt( $('#x_cord').text()) + 1)
	            $('#x_cord').focus().blur()
	            break;
	         case 40:
	            console.log("Down key is pressed.");
	            $('#y_cord').text(parseInt( $('#y_cord').text()) + 1)
	            $('#y_cord').focus().blur()
	            break;
      	}
      }
   };




	$(document).on('click', '.add-trpok', function(){
		var card = $(this).parents('.filterable')

		if (card.find('.wild').length == 6) {
			return
		}

		var index = card.attr('data-index')
		var narc = $(this).attr('data-narc')
		var pok_index = card.find('.wild').length

		data = {}

		data["file_name"] = index
		data["sub_index"] = pok_index
		data["narc"] = narc

		while (edit_in_progress == false) {
			edit_in_progress = true
			$.post( "/create", {"data": data }, function( e ) {     
	          edit_in_progress = false
	          card.append(e)
	        });
		}
		
        card.find('img').removeClass('-active')
        card.find('.expanded-card-subcontent').removeClass('show-flex')

        card.find('.trainer-poks').append("<div class='wild'> <img class='-active' src='images/pokesprite/-.png' data-show='pok-" + pok_index.toString() + "'> </div>")

	})

	$(document).on('click', '.autofill-btn', function() {
		card = $(this).parents('.expanded-pok')
		lvl = card.find('.trpok-lvl').text()
		pok_index = card.attr('data-sub-index')
		trainer = $(this).parents('.filterable').attr('data-index')

		moves = []


		$.get(`trpoks/moves/${trainer}/${pok_index}?lvl=${lvl}`, function( data ) {
        	console.log(data)
        	moves = data["moves"]
        	card.find('.trpok-mov').each(function(i,v) {
	        	console.log(v)
	        	$(this).text(moves[i])  
	        })
        });





	})

	$(document).on('click', '.iv-label', function(){
		var card = $(this).parents('.filterable')
		trdata_index = card.attr('data-index')
		trpok_index = $(this).parents('.expanded-pok').attr('data-sub-index')
		iv = $(this).parent().find('.tr-item').text()

		url = `trainers/${trdata_index}/${trpok_index}/natures/${iv}`
		window.open(url, '_blank');
	})

	
	
	/////////////////////////////// DATA UPLOAD ON EDIT ///////////////////////////////

	
	$(document).on('click', '.upload-script',  function() {
		


		var entry = $(this).parents('.filterable')
		console.log(entry)
		var index = entry.attr('data-index')
		var file = entry.find('.move-script')[0].files[0]
		var ani = entry.find("[data-field-name='animation']").text()

		if (!file) {
			alert("no file uploaded")
			return
		}

		if (ani != "0") {
			alert("animation must first be set to 0")
			return
		}
		
		let formData = new FormData();           
	    formData.append("file", file);
	    fetch(`/moves/${index}/script`, {
	      method: "POST", 
	      body: formData
	    }); 
	    alert("Script Uploaded")


	})




	


	$(document).on('mousedown',"[contenteditable='true']", function(e){
		current_edit = $(this)
		initial_value = $(this).text()

	} )

	$(document).on('mousedown',".season-icon", function(e){
			current_encounter = $(this).parents('.expanded-field').attr('data-index')
			current_season = $(this).attr('data-show')
	} )

	$(document).on('focusout', ".text-line[contenteditable='true']", function(){
		var bank = []
		$('.text-bank').each(function(){
			var entry = []
			$(this).find('.text-line').each(function(){
				if ($(this).text() != "") {
					entry.push($(this).text())
				}
				
			})
			bank.push(entry)
		})
		
		var narc = $('.pokemon-list').attr('data-narc')
		var bank_id = $('.pokemon-list').attr('data-index')

		$.post( `/texts/${bank_id}`, { bank: bank, narc: narc }, function(data){
			console.log(data)
		})
	})

	$(document).on('click', ".text-line[contenteditable='true']", function(){
		var line = $(this).parents('.expanded-field')
		
		if (line.is(':last-child')) {
			console.log(line)
			$(this).parents('.text-bank').append(line.clone())
			// $(this).parents('.text-bank').find('text-line:last-child').text("")
		}
	})


	$(document).on('mouseover', ".pallete-color", function() {
		var pallete_index = $(this).attr('data-color-index')
		var texture = $(this).parent().prev()

		texture.find(`[data-pallete-index*='${pallete_index}']`).addClass('highlighted-tile')
	})

	$(document).on('mouseout', ".pallete-color", function() {
		var pallete_index = $(this).attr('data-color-index')
		var texture = $(this).parent().prev()

		texture.find(`[data-pallete-index*='${pallete_index}']`).removeClass('highlighted-tile')
	})





	$(document).on('focusout', ":not(.text-line, .editable-doc)[contenteditable='true']", function(){
		var input = $(this)
		var card = input.parents('.filterable')

		var value = $(this).text().trim()
		$(this).text(value)
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.filterable, .field-holder').attr('data-index')
		var narc = $(this).attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc

		if (!input.hasClass('no-validate')) {
			if ($(this).attr('data-type') && $(this).attr('data-type').includes("int")) {
				data["int"] = true
				data["value"] = parseInt(data["value"])
				max_value = parseInt($(this).attr('data-type').split("-")[1])
				min_value = 0

				if (max_value == 6) {
					min_value = -6
				}
				
				//validate int value less than max if int field
				if (((!parseInt(value) || parseInt(value) > max_value ) && parseInt(value) != 0)  || parseInt(value) < min_value) {
					$(this).css('border', '1px solid red')
					return
				}
			} else {
				
				if (input.attr('data-type') != 'array') {
									// validate string in autofill bank if string field
					valid_fields = autofills[$(this).attr('data-autofill')]
					
					if ($(this).attr('data-autofill') == "evo_params") {
					  	
					  	var method = $(this).parents('.expanded-field').prev().find('.evo-value').text().toLowerCase()
					  	console.log(method)
					  	
					  	if (!isNaN(value)) {
					  		data["int"] = true
					  	}

					  	if (method.includes("item")) {
					  		valid_fields = autofills["items"]
					  		data["int"] = false
					  	} else if (method.includes("move")) {
					  		valid_fields = autofills["move_names"]
					  		data["int"] = false
					  	} else if (method.includes("member")) {
					  		valid_fields = autofills["pokemon_names"]
					  		data["int"] = false
					  	} else {
					  		valid_fields = Array.from(Array(256).keys())
					  	}
					 }


					valid_fields = JSON.stringify(valid_fields)
					if (data["int"]) {
						value_to_check = value
					} else {
						value_to_check = `"${value}"`
					}
					
					if (!valid_fields.includes(value_to_check) || value == "-" || value == "") {
						
						
						$(this).css('border', '1px solid red')
						

						return
					}

				}

			}
		} else {
			// data["narc"] = $('#texts').attr('data-narc')			
			// data["narc_const"] = "text"
			data["narc"] = $(this).attr('data-narc')
			data["file_name"] = index
			data["field"] = field_name
			data["value"] = value

			

			if (!$(this).hasClass('color-label')) {
				data["file_name"] = data["field"]

			} else {
				$(this).next().css('background', $(this).text())
			}
			


			
			if ($(this).hasClass("pallete-color")) {
				var color = $(this).attr('style').slice(11,-1)
				var texture = $(this).parent().prev()

				var new_color = $(this).text()
				if (new_color[0] == "#") {
					texture.find(`[style*='${color}']`).css("background", $(this).text())
					$(this).css("background", $(this).text())
				}
				else {
					texture.find(`[style*='${color}']`).css("background", `rgb(${$(this).text()})`)
					$(this).css("background", `rgb(${$(this).text()})`)
				}
				$.get(location.href + "/save")
			}



			if ($(this).hasClass('empty-text')) {
				data['narc_const'] = 'trdata'
				data['trtext'] = true
				data["file_name"] = index
				var old_field_name = $(this).attr('data-field-name')

				
				if (data["value"] == "" && initial_value == "") {
					// do nothing if no change
					console.log("already empty no change")
				} else if (data["value"] == "" && initial_value != "") {
					// if deleting
					console.log("deleting")
					var text_id = parseInt(data["field"].split("_").slice(-1)[0])
					$('.empty-text').each(function() {
						var field_name = $(this).attr('data-field-name')
						var field_text_id = parseInt(field_name.split("_").slice(-1)[0])

						if (field_text_id >= text_id) {
							var new_field_name = field_name.replace(`entry_${field_text_id}`, `entry_${field_text_id - 1}`)
							$(this).attr('data-field-name', new_field_name)
						}
					})
					$(this).attr('data-field-name', old_field_name)


				} else if (data["value"] != "" && initial_value != "") {
					// do nothing if editing
					console.log("just editting no change")
				} else {
					// if adding entry
					console.log("adding")
					var text_id = parseInt(data["field"].split("_").slice(-1)[0])
					$('.empty-text').each(function() {
						var field_name = $(this).attr('data-field-name')
						var field_text_id = parseInt(field_name.split("_").slice(-1)[0])

						if (field_text_id >= text_id) {
							var new_field_name = field_name.replace(`entry_${field_text_id}`, `entry_${field_text_id + 1}`)
							$(this).attr('data-field-name', new_field_name)
						}
					})
					$(this).attr('data-field-name', old_field_name)
				}
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

		// the while loops are to stop concurrent requests from editing a file at the same time
		while (edit_in_progress == false) {
			edit_in_progress = true	
			$.post( "/update", {"data": data }, function( e ) {     
	          console.log(JSON.parse(e)["url"])
	          if (JSON.parse(e)["url"] == "/") {
	          	location.href = "/"
	          	return
	          }
	          console.log('upload successful')
	          
	          edit_in_progress = false
	          var checkbox = card.find("." + input.attr('data-check'))
	          if (!checkbox.prop("checked")){
	          	checkbox.click()
	          } 
	          checkbox.prop("checked", true).addClass('-active')

	          if ($("#overworld").length > 0) {
	          	ow_id = $(".overworld-item.selected").attr("data-id")
	          	var base_url = window.location.href.split("?")[0]
	          	$.get(base_url + `/box?selected=${ow_id}`, function(data){
					
					$("#overworld").html(data)
					adjust_directions()
				})

	          }
	        }).fail(function(xhr, status, error) {
		       	edit_in_progress = false
		    });;
	        return
		}
		console.log("concurrent update detected")
	})

	//high light text on click
	$(document).on('click', ":not(.log-text, .editable-doc)[contenteditable='true']", function(e){
		$(this).selectText()
	})

	$(document).on('click', ".show-bottom", function(e){
		$(this).parents('.expanded-card-content').find('.expanded-bottom').toggle()
	})

	// upload choice when clicking 
	$(document).on('click', ".choosable", function(e){
		card = $(this).parents('.filterable')

		var value = $(this).attr('data-value')
		var field_name = $(this).parent().attr('data-field-name')
		var index = card.attr('data-index')
		var narc = $(this).parent().attr('data-narc')

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc

		$(this).parent().children().removeClass('chosen').addClass('unchosen')
		$(this).addClass('chosen').removeClass('unchosen')

		console.log(data)

		while (edit_in_progress == false) {
			edit_in_progress = true
			$.post( "/update", {"data": data }, function( e ) {     
	          edit_in_progress = false
	          console.log('upload successful')
	        });
		}
		
	})

	$(document).on('click', ".move-prop, .choosable-prop", function(e){
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
		while (edit_in_progress == false) {
			edit_in_progress = true
			$.post( "/update", {"data": data }, function( e ) {     
	          edit_in_progress = false
	          console.log('upload successful')
	        });
		}
		
	})

	$(document).on('click', ".cell", function(e){
		$(this).toggleClass('-active')

		var value = []
		var field_name = $(this).attr('data-field-name')
		var index = $(this).parents('.filterable').attr('data-index')
		var narc = $(this).attr('data-narc')

		cells = $(this).parent().children()
		cells.each(function(n) {
			
			if ($(cells[n]).hasClass('-active')){
				value.push(1)
			} else {
				value.push(0)
			}
		}) 

		var data = {}

		data["file_name"] = index
		data["field"] = field_name
		data["value"] = value
		data["narc"] = narc
		
		console.log(data)
		while (edit_in_progress == false) {
			edit_in_progress = true
			$.post( "/update", {"data": data }, function( e ) {     
	          edit_in_progress = false
	          console.log('upload successful')
	        });
		}
		



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

	$(document).ready(function() {
		$(document).on('focusout', ".move-name[contenteditable='true']", function(){
			var value = $(this).text().trim()
			move_data = Object.values(moves).find(e => e[1]["name"].toLowerCase().toCamelCase() == value.toLowerCase().toCamelCase() )

			if (move_data) {
				type = move_data[1]["type"] 
				power = move_data[1]["power"]
				acc = move_data[1]["accuracy"]
				effect = move_data[1]["effect"]
				cat = move_data[1]["category"]
				
				type_name_length = 3
				if ($('.tm-list').length > 0) {
					type_name_length = type.length
				}

				row = $(this).parents('.expanded-field')

				row.find('button, .btn').removeClass().addClass('btn').addClass('-active').addClass("-" +type.toLowerCase()).text(type.toUpperCase().slice(0,type_name_length))
				
				row.find('img').show().attr("src", "/images/move-" + cat.toLowerCase() + ".png")
				row.find('.move-power').text(power)
				row.find('.move-accuracy').text(acc)
				row.find('.move-effect').text(effect)
			}
		})
	})
	// expand move data 


	// adjust base stat bar length
	$(document).on('focusout', "td[contenteditable='true']", function(){
		var value = $(this).text().trim()

		value = parseInt(value)
		var width = value / 2.55
		$(this).parent().find(".pokemon-card__graph").css('width', width.toString() + "%")
	})

	// update encounter preview
	$(document).on('focusout', ".enc-name[contenteditable='true']", function(){
		var value = $(this).text().trim()
		var card = $(this).parents('.filterable')
		updateWilds(card)
	})

	function updateWilds(card) {
		var all_encs = card.find('.enc-name')

		var encs = all_encs.map(function(e) {	
			return $(all_encs[e]).text() 
		}).toArray()

		let unique_encs = encs.filter((c, index) => {
		    return (encs.indexOf(c) === index && c != "-");
		});
		
		card.find(".wild").remove()
		
		$.each(unique_encs, function(i,v) {
			if (v != "") {
				var sprite = "<div class='wild'><img src='/images/pokesprite/" + v.toLowerCase() + ".png'></div>"
				card.find(".encounter-wilds, .grotto-wilds").append(sprite)
			}		
		})
	}

	//update mart inv
	$(document).on('focusout', ".mart-item", function(){
		var value = $(this).text().trim()
		var card = $(this).parents('.filterable')

		inventory = []
		card.find('.mart-item').each(function(i,v) {
			inventory.push($(v).text())
		})
		console.log(inventory)

		card.find('.mart-inv').text(inventory.filter(x => x !== "None").join(", "))


	})

	$(document).on('focusout', ".trpok-name", function(){
		var value = $(this).text().trim()
		var card = $(this).parents('.filterable')
		var pok_index = $(this).parents('.expanded-pok').index() - 2

		updateTrImage(value, card, pok_index)

	})

	function updateTrImage(value, card, pok_index) {
		img_name = value.replace(". ", "-").toLowerCase()

		img_to_update = $(card.find('.wild img')[parseInt(pok_index)])

		img_to_update.attr('src', '/images/pokesprite/' + img_name + ".png")

	}

	$(document).on('click', ".delete-trpok", function(){
		var card = $(this).parents('.filterable')
		var pok_index = $(this).parents('.expanded-pok').index() - 2
		var index = card.attr('data-index')
		var narc = $(this).attr('data-narc')


		var data = {}

		data["file_name"] = index
		data["narc"] = narc
		data["sub_index"] = parseInt(pok_index)
		
		console.log(data)

		while (edit_in_progress == false) {
			edit_in_progress = true

			$.post( "/delete", {"data": data }, function( e ) { 
				edit_in_progress = false    
	          	card.find('img.-active').parent().remove()
	        	card.find('.expanded-card-subcontent')[parseInt(pok_index)].remove()
	        });
		}
	})


	$(document).on('autocomplete:request', "[contenteditable='true']", function(event, query, callback) {
	   var textbank = autofills[$(this).attr('data-autofill')]

	  if ($(this).attr('data-autofill') == "evo_params") {
	  	textbank = autofills["pokemon_names"].concat(autofills["items"]).concat(autofills["move_names"])
	  }

	  if ($(this).attr('data-autofill') == "mastersheet") {
	  	textbank = autofills["true_pokemon_names"].concat(autofills["move_names"])
	  }

	  var suggestions = textbank.filter(function(e){
	  	return e.toLowerCase().includes(query.toLowerCase())
	  });
	  callback(suggestions);
	})

	$(document).on('autocomplete:request', ".filter-input", function(event, query, callback) {

	  	textbank = autofills["true_pokemon_names"].concat(autofills["move_names"])
	  

	  var suggestions = textbank.filter(function(e){
	  	return e.toLowerCase().includes(query.toLowerCase())
	  });
	  callback(suggestions);
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
		$('.filterable, .expanded-card-content').css('background', '')
		$('.filterable:visible:odd, .filterable:visible:even .expanded-card-content').css('background', '#383a59');
		$('.filterable:visible:even, .filterable:visible:odd .expanded-card-content').css('background', '#282a36'); 
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
				texts = text_filters.split(", ")
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
		var tms = true
		if ($("[data-index='tms']").length == 0) {
			tms = false
			
		}
		console.log(tms)
		search_results = move_list.filter(function(e) {
			

			e = e[1]
		
			

			if (!e || !e["type"]) {
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
				texts = text_filters.split(", ")
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
				// $(cards[e["index"]]).show()
				if (tms) {
					$(".filterable[data-move-index='" + e["index"] + "']").show()
				} else {
					$(cards[e["index"]]).show()
				}
				
			}

			return type_match && cat_match && text_match
		})
	}

	if ($('#headers').length > 0) {		
		var list = Object.values(headers).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})

		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					// console.log(texts)
					text = texts[text]
					
					if (e["location_name"]) {
						text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					}
					
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}

	if ($('#encounters').length > 0) {		
		var list = Object.values(encounters).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})

		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}

	if ($('#trainers').length > 0) {		
		var list = Object.values(trainers).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})

		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})

		var list = Object.values(trainer_poks).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})

		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}

	if ($('#items').length > 0) {		
		var list = Object.values(items).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})
		console.log(list) 
		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}


	if ($('#marts').length > 0) {		
		var list = Object.values(marts).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})
		console.log(list) 
		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}


	if ($('#grottos').length > 0) {		
		var list = Object.values(grottos).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})
		console.log(list) 
		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}

	if ($('#natures').length > 0) {		
		var list = Object.values(natures).sort(function(a,b) {
			parseInt(a["index"]) - parseInt(b["index"]);
		})
		console.log(list) 
		search_results = list.filter(function(e) {
			text_match = false

			if (text_filters) {
				texts = text_filters.split(", ")
				for (text in texts) {
					text = texts[text]

					text_match = JSON.stringify(e).toLowerCase().includes(text.toLowerCase())
					if (text_match ) {break;}
				} 
			} else { // when no text filter
				text_match = true
			}

			if (text_match) {
				$(cards[list.indexOf(e)]).show()
			}
			return text_match
		})
	}

	$('.filterable, .expanded-card-content').css('background', '')
	$('.filterable:visible:odd, .filterable:visible:even .expanded-card-content').css('background', '#383a59');
	$('.filterable:visible:even, .filterable:visible:odd .expanded-card-content').css('background', '#282a36'); 
	
}

function clearSelection() {
    if(document.selection && document.selection.empty) {
        document.selection.empty();
    } else if(window.getSelection) {
        var sel = window.getSelection();
        sel.removeAllRanges();
    }
}
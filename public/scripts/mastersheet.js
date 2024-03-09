dupes = {}

function getEncInfo(enc) {
	var tables = enc.find('.expanded-left')

	var grass = $(tables[0])
	var grass_doubles = $(tables[1])
	var grass_special = $(tables[2])

	var level = $('#manip-lvl').val() || 1

	if (level == "") {
		level = 1
	}
	else {
		level = parseInt(level)
	}

	var surf = $(tables[3])
	var surf_special = $(tables[4])
	var super_rod = $(tables[5])
	var super_rod_special =$(tables[6])

	var enc_types = [["Grass", grass, "manip" ], ["Grass Doubles", grass_doubles, "manip" ],["Grass Special", grass_special], ["Surf", surf, "manip"], ["Surf Special", surf_special], ["Super Rod", super_rod], ["Super Rod Special", super_rod_special]]

	var enc_probabilities = {}
	enc_probabilities["totals"] = []

	for (i in enc_types) {
		enc_type = enc_types[i]
		enc_probabilities[enc_type[0]] = {}
		var total_prob = 0


		enc_type[1].find('.expanded-field:not(.field-header)').each(function(){
			var enc_name = $(this).find('.enc-name').text().trim()
			enc_probabilities[enc_type[0]][enc_name] ||= 0
			var prob = parseInt($(this).find('.enc-percent').text())
			if (dupes[enc_name]) {
				prob = 0
			}

			if (enc_type[2]) {
				var max_lvl = parseInt($(this).find('.enc-lvl').last().text())
				if (level <= max_lvl) {
					enc_probabilities[enc_type[0]][enc_name] += prob
					total_prob += prob
				}
			} else {
				enc_probabilities[enc_type[0]][enc_name] += prob
				total_prob += prob
			}
		})


		enc_probabilities["totals"].push(total_prob)


	}
	return [enc_probabilities, enc]
}

function displayEnc(info) {
	var enc_html = ""
	var enc_types = [["Grass"], ["Grass Doubles" ],["Grass Special"], ["Surf"], ["Surf Special"], ["Super Rod"], ["Super Rod Special"]]

	var probabilities = info[0]
	var location_title = $(info[1]).prev().text()
	var repel_manip = parseInt($('#manip-lvl').val()) || 1

	enc_html += `<div class='ms-enc-main-header'>${location_title} at Lv <input value='${repel_manip}' id='manip-lvl'/> </div>`

	$('.ms-pok, .ms-move').hide()


	for (i in enc_types) {
		enc_type = enc_types[i]
		
		if ( !('  ' in probabilities[enc_type]) && !('' in probabilities[enc_type])) {
			enc_html += `<div class='ms-enc-header'>${enc_type}</div>`
			for (const [key, value] of Object.entries(probabilities[enc_type])) {
			  displayed_prob = (Math.round((value / probabilities["totals"][i] * 100) * 100) / 100) 
			  enc_html += `<div class='ms-enc-row'><div class='ms-enc-name' data-species-id='${key}'>${key}</div><div class='ms-enc-percent'>${displayed_prob} %</div></div>`
			}
		}	
	}
	$('#enc-info').html(enc_html).show()
}

$(document).ready(function() {


	

	$(document).on('click', '.doc-species, .doc-sprite', function(e){
		var species_id = parseInt($(this).attr('data-species-id'))
		
		$('.ms-pok, .ms-move, #enc-info').hide()
		$(`[data-species-id='${species_id}']`).show()
	}) 



	$(document).on('click', '.ms-enc-name, .enc-name', function(e){ 
		e.stopPropagation()
		var species_id = $(this).attr('data-species-id').replace("-", " ")
		
		$('.ms-pok, .ms-move, #enc-info').hide()
		$(`[data-species-name='${species_id}']`).show()

	}) 


	$(document).on('click', '.doc-move', function() {
		var move_id = parseInt($(this).attr('data-id'))
		$('.ms-pok, .ms-move, #enc-info').hide()
		$(`[data-move-id='${move_id}']`).show()
	})

	$(document).on('click', '.doc-enc', function() {
		info = getEncInfo($(this))
		displayEnc(info)
		lastClickedEnc = $(this)
	})

	$(document).on('blur', '#manip-lvl', function() {
		info = getEncInfo(lastClickedEnc)
		displayEnc(info)
	})

	$(document).on('click', '#mastersheet .wild', function() {
		var species_name = $(this).attr('data-species-name')
		$(`[data-species-name='${species_name}']`).toggleClass('dupe')
		dupes[species_name] = !!!dupes[species_name]
	})

	$(document).keydown(function(event) {
      if (event.key === '`') {
        $('#ms-editor').toggle();
      }
    });

    $(document).keydown(function(event) {
      if (event.key === '~') {
        e.stopPropagation()
        $('#submit-ms').click();
      }
    });

	$('.master-sidebar input').keypress(function (e) {
	  if (e.which == 13) {
	    var value = $(this).val()
	    $(this).attr('style',"")
	    
	    for (i in autofills["true_pokemon_names"]) {
	    	var pok_name = autofills["true_pokemon_names"][i]


	    	if (value.toLowerCase().replace(/[^\w\s]/gi, '') == pok_name.toLowerCase().replace(/[^\w\s]/gi, '')) {
	    		$('.ms-pok, .ms-move, #enc-info').hide()
	    		$(`[data-species-id='${i}']`).show()
	    		return
	    	}
	    	
	    }

	    for (i in autofills["move_names"]) {
	    	var mov_name = autofills["move_names"][i]

	    	if (value.toLowerCase().replace(/[^\w\s]/gi, '') == mov_name.toLowerCase().replace(/[^\w\s]/gi, '')) {
	    		$('.ms-pok, .ms-move, #enc-info').hide()
	    		$(`[data-move-id='${i}']`).show()
	    		return
	    	}
	    	
	    }

	    $(this).css('border', '1px solid red')
	  }
	});
	$('#submit-ms').on('click', async function() {
		var content = $('textarea').val()

		let formData = new FormData();  
		formData.append("content", content);  
		

		const response = await fetch(`/mastersheet`, {
	      method: "POST", 
	      body: formData
	    })

	    var html = await response.text()
	    var parser = new DOMParser();

        // Parse the text
        var doc = parser.parseFromString(html, "text/html");	
	    $('#mastersheet').html(html)

	    // save memory
	    html = null 

	})

})











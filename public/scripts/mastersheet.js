

function getEncInfo(enc) {
	var tables = enc.find('.expanded-left')

	var grass = $(tables[0])
	var grass_doubles = $(tables[1])
	var grass_special = $(tables[2])

	var level = enc.find('.repel-manip').val()

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
			var enc_name = $(this).find('.enc-name').text()
			enc_probabilities[enc_type[0]][enc_name] ||= 0
			var prob = parseInt($(this).find('.enc-percent').text())

			if (enc_type[2]) {
				var min_lvl = parseInt($(this).find('.enc-lvl').first().text())
				if (level <= min_lvl) {
					enc_probabilities[enc_type[0]][enc_name] += prob
					total_prob += prob
				}
			} else {
				enc_probabilities[enc_type[0]][enc_name] += prob
			}
		})

		if (enc_type[2]) {
			enc_probabilities["totals"].push(total_prob)
		} else {
			enc_probabilities["totals"].push(100)
		}


	}
	return enc_probabilities
}

function displayEnc(info) {
	var enc_html = ""
	var enc_types = [["Grass"], ["Grass Doubles" ],["Grass Special"], ["Surf"], ["Surf Special"], ["Super Rod"], ["Super Rod Special"]]

	$('.ms-pok, .ms-move').hide()

	for (i in enc_types) {
		enc_type = enc_types[i]
		
		if (!info[enc_type]['  ']) {
			enc_html += `<div class='ms-enc-header'>${enc_type}</div>`
			for (const [key, value] of Object.entries(info[enc_type])) {
			  
			  enc_html += `<div class='ms-enc-row'><div class='ms-enc-name'>${key}</div><div class='ms-enc-percent'>${value / info["totals"][i] * 100 } %</div></div>`
			}
		}	
	}
	$('#enc-info').html(enc_html).show()
}

$(document).ready(function() {


	$('.doc-species, .doc-sprite').on('click', function(){
		var species_id = parseInt($(this).attr('data-species-id'))
		
		$('.ms-pok, .ms-move, #enc-info').hide()
		$(`[data-species-id='${species_id}']`).show()
	}) 

	$('.doc-move').on('click', function() {
		var move_id = parseInt($(this).attr('data-id'))
		$('.ms-pok, .ms-move, #enc-info').hide()
		$(`[data-move-id='${move_id}']`).show()
	})

	$('.encounter-locations').on('click', function() {
		info = getEncInfo($(this).parent().parent())
		displayEnc(info)
	})

	$('.repel-manip').on('blur', function() {
		info = getEncInfo($(this).parent().parent())
		displayEnc(info)
	})

	$('.master-sidebar input').keypress(function (e) {
	  if (e.which == 13) {
	    var value = $(this).val()
	    $(this).attr('style',"")
	    console.log(value.toLowerCase().replace(/[^\w\s]/gi, ''))
	    
	    for (i in autofills["true_pokemon_names"]) {
	    	var pok_name = autofills["true_pokemon_names"][i]

	    	console.log(pok_name.toLowerCase().replace(/[^\w\s]/gi, ''))

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


})











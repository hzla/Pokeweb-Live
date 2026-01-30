class Trpok < Pokenarc
	def self.get_all personal=nil
		@@narc_name = "trpok"
		poks = super
		poks.each_with_index do |pok, i|
			poks[i]["index"] = i
			poks[i]["class"] = get_trainer_class(i)
		end

		

		poks
	end

	def self.get_trainer_class id
		Trdata.get_data("#{$rom_name}/json/trdata/#{id}.json")["class"]
	end


	def self.get_data file_name
		@@narc_name = "trpok"
		super
	end

	def self.normalize_spellings
		correct_spellings = File.read("#{$rom_name}/texts/pokedex.txt").split("\n").map(&:name_titleize)

		get_all.each_with_index do |pok, i|
			file_path = "#{$rom_name}/json/trpok/#{i}.json"
			trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})
			(0..5).each do |n|
				break if !trpok["readable"]["species_id_#{n}"]
				trpok["readable"]["species_id_#{n}"] = correct_spellings[trpok["raw"]["species_id_#{n}"]]
			end
			File.open(file_path, "w") { |f| f.write trpok.to_json }
		end
		return "success"
	end


	

	def self.search trdata, trpok, tr_name, mon_lvl, mon_name
		tr_name = tr_name.downcase.gsub(" ", "").strip
		mon_name == mon_name.downcase.gsub(" ", "").strip
		if mon_name == ""
			no_name_match = true
		else
			no_name_match = false
		end

		trdata.each_with_index do |tr, i|
			parsed_name = tr["name"].downcase.gsub(" ", "")
			if tr_name == parsed_name
				trpok_name = trpok[i]["species_id_0"].downcase.gsub(" ", "")
				trpok_lvl = trpok[i]["level_0"]

				if (no_name_match || (trpok_name == mon_name)) and trpok_lvl == mon_lvl
					return i
				end
			end
		end
		return 0
	end


	def self.get_all_mods

		@@narc_name = "trpok"
		collection = []
		files = Dir["#{$rom_name}/json/#{@@narc_name}/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			
			file = File.open("#{$rom_name}/json/#{@@narc_name}/#{n}.json", "r:ISO8859-1") {|f| f.read }
			json = JSON.parse(file)
			entry = json["readable"]
			entry["id"] = n
			collection[n] = entry
		end
		
		
		
		collection.sort_by! do  |pok|
			
			pok["level_0"] || 0
	
		end

		collection = collection.filter do |n|
			
			n["ivs_0"] and n["ivs_0"] > 250
		end

		collection
	end

	def self.get_max_level trpok
		max = 1
		(0..5).each do |n|
			if trpok["level_#{n}"]
				max = trpok["level_#{n}"] if trpok["level_#{n}"] > max
			else
				break
			end
		end
		max
	end

	def self.level_grouped levels
		level_sorted = get_all.sort_by {|trpok| get_max_level(trpok)}
		grouped = [[],[],[],[],[],[],[],[],[]] 

		level_sorted.each do |trpok|
			levels.each_with_index do |lvl, i|
				found = false


				if get_max_level(trpok) < lvl
					grouped[i] << trpok 
					found = true
				end
				break if found
			end
		end
		grouped
	end

	def self.write_data data, batch=false
		@@narc_name = "trpok"
		@@upcases = ["species", "move"]
		super
	end

	def self.get_poks_for count, trainer_poks
		poks = []
		(0..20).each do |n|
			if trainer_poks["species_id_#{n}"]
				poks << trainer_poks["species_id_#{n}"].gsub(". ", "-").downcase
			end
			break if poks.length == count
		end
		poks
	end

	def self.fill_all
		trdatas = Trdata.get_all

		trdatas.each_with_index do |trdata, tr_id|
			next if trdata["has_moves"] != 0

			file_path = "#{$rom_name}/json/trpok/#{tr_id}.json"
			trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})

			(0...trdata["num_pokemon"]).each do |pok_index|

				
				pok_id = trpok["raw"]["species_id_#{pok_index}"] % 1024
			
				next [] if !pok_id

				learnset_path = "#{$rom_name}/json/learnsets/#{pok_id}.json"
				learnset = JSON.parse(File.open(learnset_path, "r"){|f| f.read})

				moves = []
				lvl = trpok["readable"]["level_#{pok_index}"]

				(0..19).to_a.reverse.each do |n|
					lvl_learned = learnset["readable"]["lvl_learned_#{n}"]
					if lvl_learned && lvl_learned.to_i <= lvl.to_i
						moves << [learnset["raw"]["move_id_#{n}"],learnset["readable"]["move_id_#{n}"]]
					end
					if moves.length == 4
						break
					end
				end
				# binding.pry

				moves.each_with_index do |move, i|
					trpok["raw"]["move_#{i + 1}_#{pok_index}"] = move[0]
					trpok["readable"]["move_#{i + 1}_#{pok_index}"] = move[1]
				end
			end
			File.open(file_path, "w") { |f| f.write trpok.to_json }
		end
	end

	# fill in moves for all default learnset trainers
	def self.fill_all_lvl_up_moves
		trainers = Trpok.get_all
		trdatas = Trdata.get_all

		trainers.each_with_index do |tr, idx|
			if trdatas[idx]["has_moves"] == 0

				num_poks = trdatas[idx]["num_pokemon"].to_i
				(0..num_poks - 1).each do |subindex|
					Trpok.fill_lvl_up_moves tr["level_#{subindex}"], idx, subindex, true, true
				end
			end
		end
		p "success"
	end

	def self.fill_lvl_up_moves lvl, trainer, pok_index, output_json=true, get_ids=false

		file_path = "#{$rom_name}/json/trpok/#{trainer}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})

		pok_id = trpok["raw"]["species_id_#{pok_index}"] % 1024

		return [] if !pok_id


		learnset_path = "#{$rom_name}/json/learnsets/#{pok_id}.json"
		learnset = JSON.parse(File.open(learnset_path, "r"){|f| f.read})

		moves = []

		(0..19).to_a.reverse.each do |n|
			lvl_learned = learnset["readable"]["lvl_learned_#{n}"]
			if lvl_learned && lvl_learned.to_i <= lvl.to_i
				moves << [learnset["raw"]["move_id_#{n}"],learnset["readable"]["move_id_#{n}"]]
			end
			if moves.length == 4
				break
			end
		end

		moves.each_with_index do |move, i|
			trpok["raw"]["move_#{i + 1}_#{pok_index}"] = move[0]
			trpok["readable"]["move_#{i + 1}_#{pok_index}"] = move[1]
		end

		if output_json
			File.open(file_path, "w") { |f| f.write trpok.to_json }
		end
		if !get_ids
			moves.map {|m| m[1].name_titleize}
		else
			moves.map {|m| [m[1].name_titleize, m[0]]}
		end

	end

	def self.create data
		file_name = data["file_name"]
		n = data["sub_index"]

		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r"){|f| f.read})

		new_readable_data = {"ivs_#{n}": 0, "ability_#{n}": 0, "level_#{n}": 0, "padding_#{n}": 0, "species_id_#{n}": "-", "form_#{n}": 0, "gender_#{n}": "Default"}

		json_data["readable"] = json_data["readable"].merge(new_readable_data)
		json_data["readable"]["count"] += 1

		File.open(file_path, "w") { |f| f.write json_data.to_json }

		json_data
	end

	def self.delete data
		file_name = data["file_name"]
		n = data["sub_index"]

		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r"){|f| f.read})

		#remove current pokemon
		json_data["readable"].each do |field, value|
			if field.split("_")[-1] == "#{n}"
				json_data["readable"].delete field
			end
		end

		#move everything above it down a slot
		json_clone = json_data["readable"].clone
		json_clone.each do |field, value|
			n = n.to_i
			((n+1)..(json_clone["count"] - 1)).each do |i|

				if field[-1] == i.to_s
					json_data["readable"].delete field 
					field_clone = field.dup
					field_clone[-1] = (i-1).to_s
					json_data["readable"][field_clone] = value
				end
			end
		end


		
		json_data["readable"]["count"] -= 1
		File.open(file_path, "w") { |f| f.write json_data.to_json }

		trdata_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		tr_data = JSON.parse(File.open(trdata_path, "r"){|f| f.read})
		tr_data["readable"]["num_pokemon"] = json_data["readable"]["count"]
		tr_data["raw"]["num_pokemon"] = json_data["readable"]["count"]
		File.open(trdata_path, "w") { |f| f.write tr_data.to_json }
	end

	def self.fill_in_natures_and_abilities
		trpoks = get_all
		trdatas = Trdata.get_all
		personals = Personal.poke_data

		$last_set_ability = 1

		trpoks.each_with_index do |trpok, file_name|
			trdata = trdatas[file_name]
			num_poks = trdata["num_pokemon"]

			$last_set_ability = 1

			(0..num_poks - 1).each do |sub_index|
				iv = trpok["ivs_#{sub_index}"]
				get_doc_nature(file_name, sub_index, iv, trpok, trdata, personals, true)
			end
		end
		return "success"
	end

	def self.get_doc_nature(file_name, sub_index, iv, trpok, trdata, personals, write=false)
		if $gen == 4
			return g4_get_nature_for(file_name, sub_index, iv)
		end

		ability_slot = trpok["ability_#{sub_index}"]

		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		trpok_file = JSON.parse(File.open(file_path, "r"){|f| f.read})
		trpok = trpok_file["raw"]

		pok_id = trpok["species_id_#{sub_index}"]

		return "Unknown" if !pok_id || pok_id.is_a?(String)
		personal = personals[pok_id]



		trainer_id = file_name.to_i
		trainer_class = trdata["class_id"]
		pok_iv = trpok["ivs_#{sub_index}"]
		pok_lvl = trpok["level_#{sub_index}"]
		ability_gender = trpok["ability_#{sub_index}"]
		personal_gender = personal["gender"]



		natures = RomInfo.natures


		pid = get_pid(trainer_id, trainer_class, pok_id, iv, pok_lvl, ability_gender, personal_gender, false, ability_slot)

		nature = convert_pid_to_nature(pid, natures)

		if write
			trpok_file["readable"]["nature_#{sub_index}"] = nature

			ability_to_be_set = ability_slot
			if ability_slot == 0
				ability_to_be_set = $last_set_ability
			else
				$last_set_ability = ability_slot
			end
			trpok_file["readable"]["ability_name_#{sub_index}"] = personal["ability_#{ability_to_be_set}"].name_titleize

			sprite = Trdata.sprite(trdata["name"], trdata["class"], trdata["class_id"], Trdata.gender_table)
			trpok_file["readable"]["tr_sprite"] = sprite

			trpok_file["readable"]["name"] = trdata["name"]

			File.write(file_path, trpok_file.to_json)
		end
		nature
	end

	# def self.get_nature 


	def self.get_nature_info_for(file_name, sub_index, desired_iv=255)
		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})
		ability_slot = trpok["readable"]["ability_#{sub_index}"]
		trpok = trpok["raw"]

		file_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		trdata = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]


		pok_id = trpok["species_id_#{sub_index}"]


		file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
		personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		pok_name = personal["name"].name_titleize

		trainer_id = file_name.to_i
		trainer_class = trdata["class"]
		pok_id = pok_id
		pok_iv = trpok["ivs_#{sub_index}"]
		pok_lvl = trpok["level_#{sub_index}"]
		ability_gender = trpok["ability_#{sub_index}"]
		personal_gender = personal["gender"]
		ability_slot = ability_slot


		natures = RomInfo.natures

		nature_info = [[],[], "Trainer #{trainer_id}'s #{pok_name}", nil, [], []]

		255.downto(0).each do |n|
			pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, false, ability_slot)

			nature_info[0] << "♀: #{n} IVs: #{convert_pid_to_nature(pid, natures)}"
			nature_info[4] << pid
			# nature_info[0] << "♀: #{convert_pid_to_nature(pid, natures)}"
		end

		255.downto(0).each do |n|
			pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, true, ability_slot)

			nature_info[1] << "♂: #{n} IVs: #{convert_pid_to_nature(pid, natures)}"
			nature_info[5] << pid
			# nature_info[1] << "♂: #{convert_pid_to_nature(pid, natures)}"
		end

		nature_info[3] = trpok["ivs_#{sub_index}"]
		nature_info
	end

	def self.get_nature_for(file_name, sub_index, desired_iv=255)
		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})
		ability_slot = trpok["readable"]["ability_#{sub_index}"]
		trpok = trpok["raw"]

		file_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		trdata = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]


		pok_id = trpok["species_id_#{sub_index}"]

		file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
		personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		pok_name = personal["name"].name_titleize

		trainer_id = file_name.to_i
		trainer_class = trdata["class"]
		pok_id = pok_id
		pok_iv = trpok["ivs_#{sub_index}"]
		pok_lvl = trpok["level_#{sub_index}"]
		ability_gender = trpok["ability_#{sub_index}"]
		personal_gender = personal["gender"]
		ability_slot = ability_slot 


		natures = RomInfo.natures

		n = desired_iv
		pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, false, ability_slot)

		nature = convert_pid_to_nature(pid, natures)
		return [nature, pid]
		
	end

	def self.g4_get_nature_for(file_name, sub_index, desired_iv=255)

		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})
		ability_slot = trpok["readable"]["ability_#{sub_index}"]
		trpok = trpok["raw"]

		file_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		trdata = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]


		pok_id = trpok["species_id_#{sub_index}"].to_i

		if pok_id.to_i > 1024
			pok_id = pok_id % 1024
		end

		file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
		personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		trainer_id = file_name.to_i
		trainer_class = trdata["class"]
		difficulty = trpok["ivs_#{sub_index}"]
		level = trpok["level_#{sub_index}"]
		ability = ability_slot / 16 - 1
		species = pok_id


		gender_file = ""
		if SessionSettings.base_rom == "HGSS"
			gender_file = "texts/hgss_genders.txt"
		else
			gender_file = "texts/plat_genders.txt"
		end

		gender_table = File.read(gender_file).split("\n")
		gender = gender_table[trainer_class] == "01" ? "female" : "male"



		# p [level, species, difficulty, trainer_id, trainer_class, gender, ability]
		nature = prng(level, species, difficulty, trainer_id, trainer_class, gender, ability)
		


	end

	def self.prng level, species, difficulty, trainer_id, trainer_class, gender, ability
		seed = (level + species + difficulty + trainer_id).to_s(16)


		trainer_class.times do 
			seed = seed.to_i 16
			result = 0x41C64E6D * seed + 0x00006073
			seed = result.to_s(16)[-8..-1]
		end
		# binding.pry
		result = seed[0...-4]

		if result != ""
			mid_bytes = result[-4..-1]
		else
			mid_bytes = seed
		end
		low_bytes = gender == "male" ? "88" : "78"
		high_bytes = "00"

		pid =  high_bytes + mid_bytes + low_bytes

		ab = ability > 0 ? 1 : 0

		# add ab if hgss

		nature_id = (pid.to_i(16).to_s[-2..-1].to_i) % 25

		# uncomment the next line if hgss
		if SessionSettings.base_rom == "HGSS"
			nature_id = ((pid.to_i(16).to_s[-2..-1].to_i) + ab) % 25
		end


		RomInfo.natures[nature_id]
	end

	def self.get_abilities_for tr_id, personals

		file_path = "#{$rom_name}/json/trpok/#{tr_id}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})
		raw = trpok["raw"]
		poks = trpok["readable"]

		poks_array = []

		(0..(poks["count"] - 1)).each do |i|			
			pok_id = raw["species_id_#{i}"]
			if !pok_id
				poks_array << "Unknown"
				next
			end

			if pok_id > 1024
				pok_id = pok_id % 1024
			end
			personal = personals[pok_id]

		
			ability_id = poks["ability_#{i}"]
			if $gen == 4
				ability_id = ability_id / 16
			end
			ability_id += 1 if ability_id < 1
			if (ability_id > 3) 
				ability = self.aiAbilities[pok_id][ability_id - 4]
			else 
				ability = personal["ability_#{ability_id}"]
			end
			poks_array << ability
		end

		poks_array	
	end


	def self.convert_pid_to_nature pid, natures
		nature = natures[(pid >> 8) % 25]
	end

	def self.get_pid(trainer_id, trainer_class, pok_id, pok_iv, pok_lvl, ability_gender, personal_gender, trainer_gender, ability_slot)

		seed = trainer_id.to_i + pok_id.to_i + pok_iv.to_i + pok_lvl.to_i

		trainer_class.to_i.times do 
			seed = seed * 0x5D588B656C078965 + 0x269EC3
		end

		pid = (((seed >> 32) & 0xFFFFFFFF) >> 16 << 8) + get_gender_ab(ability_gender, personal_gender, trainer_gender, ability_slot)
	end

	def self.get_gender_ab(ability_gender, personal_gender, trainer_gender, ability_slot)
		result = trainer_gender ? 120 : 136
		g = ability_gender & 0xF
		a = (ability_gender & 0xF0) >> 4

		if ability_gender != 0

			if g!= 0
				result = personal_gender
				if g == 1
					result += 2
				else
					result -= 2
				end
			end

			case ability_slot
			when 0
				result
			when 1
				result &= 0xFFFFFFFE
			else 
				result |= 1
			end
		end
		result
	end

	def self.field_is_integer_string?(string)
	  !!(string =~ /\A[+-]?\d+\z/)
	end

	def self.format_fields
		tr_count = Dir.entries("#{$rom_name}/json/trpok/").length - 1



		(0..tr_count).each do |n|
			begin
				file_path = "#{$rom_name}/json/trpok/#{n}.json"

				trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})

				trpok["readable"].each do |k,v|
					if v.is_a?(String) && field_is_integer_string?(v)
						p "faulty string: #{v}, field: #{k}"
						trpok["readable"][k] = v.to_i
					end
				end

				File.write(file_path, trpok.to_json)
			rescue
				break
			end
		end
	end


	def self.export_all_showdown use_format=true
		format_fields

		data = []
		sets = {}
		@@tr_name_counts = {}
		tr_count = Dir.entries("#{$rom_name}/json/trpok/").length
		rival_count = -1
		gender_table = Trdata.gender_table

		settings = SessionSettings.calc_settings

		(0..tr_count).each do |n|
			ai = nil
			begin
				file_path = "#{$rom_name}/json/trdata/#{n}.json"
				full_trdata = JSON.parse(File.open(file_path, "r"){|f| f.read})
				trdata = full_trdata["readable"]
				trdata["class_id"] = full_trdata["raw"]["class"]
				ai = full_trdata["raw"]["ais"] || full_trdata["raw"]["ai"]

				if trdata["name"].downcase.include?("rival") 
					rival_count += 1
				end
			rescue
				break
				# binding.pry
			end
			
			# 

			
			if (settings["ai_values"] == "all" or settings["ai_values"].include?(ai)) && settings["has_moves"].include?(trdata["has_moves"]) && settings["has_items"].include?(trdata["has_items"]) && settings["battle_types"].include?(trdata["battle_type_1"])

				data << export_showdown(n, trdata, settings["min_ivs"], rival_count, gender_table)
			end

		end
		
		return data if !use_format

		sets["data"] = data.flatten
		File.write("public/dist/sets.json", JSON.dump(sets))

		format_exports(sets)
	end


	def self.format_exports exports
		poks = exports["data"]
		formatted = {}
		#for each pokemon
		poks.each do |pok|
			species_name = ""
			set_name = ""
			set_data = ""

			
			pok.each do |species, sets|
				
		

				species_name = species
				sets.each do |set|
					set_name = set[0]
					set_data = pok[species_name][set_name]
	
				end
			end

			if formatted[species_name]
				counter = 1
				while formatted[species_name][set_name] do 
					if counter == 1
						formatted[species_name]["#{set_name} 1"] = formatted[species_name].delete set_name
					end
					set_name = "#{set_name} #{counter + 1}"
					counter += 1
				end
			else
				formatted[species_name] = {}
			end

			formatted[species_name][set_name] = set_data
		end

		File.write("public/dist/formatted_sets.json", JSON.dump(formatted))

		open("public/dist/js/data/sets/gen5.js", "w") do |f| 
			f.puts "SETDEX_BW ="
			f.puts JSON.dump(formatted)
		end
		formatted
	end

	def self.challenge_mode_exempt
		[825,827,178,179,765,690,847,829,766,754,755,756,831,346,833,366,319,320,321,322,323,324,325,768,868,835,852,291,300,301,845,837,381,382,383,384,385,770,840,841,772,773,774,775,776,844]
	end


	def self.rp_replacemets
		replace = {}
		replace["Barrage"]=  "Draining Kiss"
		replace["Brine"]=  "Scald"
		replace["Constrict"]=  "Icicle Crash"
		replace["Horn Drill"]=  "Drill Run"
		replace["Lunar Dance"]=  "Moonblast"
		replace["Luster Purge"]=  "Dazzling Gleam"
		replace["Mist Ball"]=  "Disarming Voice"
		replace["Sand Tomb"]=  "Bulldoze"
		replace["Submission"]=  "Play Rough"
		replace["Twister"]=  "Hurricane"
		replace["Volt Tackle"]=  "Wild Charge"
		replace
	end


	def self.get_name trpok, i
		species_name = trpok["species_id_#{i}"].downcase.titleize.gsub("Porygon Z", "Porygon-Z").gsub("Ho Oh","Ho-Oh").gsub("'","’")

		form = trpok["form_#{i}"]

		form_index = $gen == 4 ? 2 : 1
		if form > 0
			begin
				species_name += "-#{RomInfo.form_info[species_name][form - form_index]}"
			rescue

			end
		end

		if trpok["raw_species_id_#{i}"] >= 652 and trpok["raw_species_id_#{i}"] <= 666
			species_name = Personal.pokestar_mons[trpok["raw_species_id_#{i}"]].downcase.titleize
		end

		species_name


	end

	def self.export_showdown tr_id, trdata, min_ivs, rival_set=0, gender_table

		file_path = "#{$rom_name}/json/trpok/#{tr_id}.json"
		raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
		poks = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]





		trname_info = "#{trdata["class"]} #{trdata["name"]}"

		if @@tr_name_counts[trname_info]
			@@tr_name_counts[trname_info] += 1
		else
			@@tr_name_counts[trname_info] = 1
		end

		poks_array = []
	
		

		(0..(poks["count"] - 1)).each do |i|
			pok_id = raw["species_id_#{i}"]
			next if !pok_id
			next if poks["ivs_#{i}"].to_i < min_ivs

			species = poks["species_id_#{i}"].downcase.titleize.gsub("Porygon Z", "Porygon-Z").gsub("Ho Oh","Ho-Oh").gsub("'","’")

			# handle pokestar studios
			# binding.pry if tr_id == 868
			if species == "    "
				species = Personal.poke_data[pok_id]["name"].upcase

			end


			trname_count = @@tr_name_counts[trname_info]

			show_count = (trname_count > 1 || trdata["name"] == "Grunt" || trdata["name"] == "Shadow" )
			
			level = poks["level_#{i}"]
			tr_name = "Lvl #{level} #{trdata["class"].gsub("⒆⒇", "PKMN")} #{trdata["name"]}#{trname_count if show_count } "
			tr_name += " - #{trdata["location"][0]}" if trdata["location"]


			

			if tr_name.downcase.include?('rival')
				# binding.pry
				tr_name += " - Starter #{(rival_set % 3) + 1}"
				
			end
			
			pok_id = raw["species_id_#{i}"]
			next if !pok_id
			file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
			personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]
			
			form = poks["form_#{i}"].to_i
			ability_id = poks["ability_#{i}"]
			

			item = poks["item_id_#{i}"]

			nature_info = get_nature_for(tr_id, i, poks["ivs_#{i}"])
			nature = nature_info[0]
			pid = nature_info[1] 
			

			begin

				iv = poks["ivs_#{i}"].to_i * 31 / 255
			rescue
				p poks
				throw
			end


			if ability_id == 0	
				ability_id = ((pid >> 16) % 2) + 1
			end
			
			if (ability_id > 3) 
				ability = self.aiAbilities[pok_id][ability_id - 4]
			else 
				ability = personal["ability_#{ability_id}"]
			end


			# Adjust species name/ability for alt forms
			if form > 0 && !(["Arceus", "Deerling"].include?(species))
				species_name = species

				begin
					species += "-#{RomInfo.form_info[species_name][form - 1]}"
				rescue
				
				end
				alt_form_file_path = "#{$rom_name}/json/personal/#{personal["form_id"] + form - 1}.json"
				alt_form_personal_file = JSON.parse(File.open(alt_form_file_path, "r"){|f| f.read})["readable"]
				ability_index = poks["ability_#{i}"]
				ability = alt_form_personal_file["ability_#{ability_index}"]
			end

			moves = []
			(1..4).each do |n|

				move = sub_showdown(poks["move_#{n}_#{i}"].move_titleize)
				
				# if rp_replacemets[move]
				# 	move = rp_replacemets[move]
				# end

				moves << move

			end

			pok = {}

			pok[species] = {}

			pok[species][tr_name] =  {}

			pok[species][tr_name]["level"] = level
			pok[species][tr_name]["ai"] = trdata["ai"]

			pok[species][tr_name]["noCh"] = challenge_mode_exempt.include?(tr_id)
			pok[species][tr_name]["tr_id"] = tr_id
			pok[species][tr_name]["ivs"] = {"hp": iv,"at": iv,"df": iv,"sa": iv,"sd": iv,"sp": iv}
			pok[species][tr_name]["battle_type"] = trdata["battle_type_1"]
			pok[species][tr_name]["reward_item"] = trdata["reward_item"]
			pok[species][tr_name]["item"] = item_titlize(item).titleize
			pok[species][tr_name]["nature"] = nature
			pok[species][tr_name]["moves"] = moves
			pok[species][tr_name]["sub_index"] = i
			pok[species][tr_name]["ability"] = ability.titleize.gsub("Lightningrod", "Lightning Rod").gsub("Compoundeyes", "Compound Eyes")
			pok[species][tr_name]["sprite"] = Trdata.sprite trdata["name"], trdata["class"], trdata["class_id"], gender_table 



			pok[species][tr_name]["form"] = form
			pok[species][tr_name]["evs"] = {"df" => 0}

			poks_array << pok





		end
		poks_array


		
	end

	def self.item_titlize(input_str)
		result = ''

		return input_str if !input_str
		input_str.chars.each_with_index do |char, index|
		result += ' ' if index > 0 && char =~ /[A-Z]/ && input_str[index - 1] =~ /[a-z]/
		result += char
		end

		result.gsub("'", "’")
	end

	def self.showdown_subs
		{
		    "Bubblebeam": "Bubble Beam",
		    "Doubleslap": "Double Slap",
		    "Solarbeam": "Solar Beam",
		    "Sonicboom": "Sonic Boom",
		    "Poisonpowder": "Poison Powder",
		    "Thunderpunch": "Thunder Punch",
		    "Thundershock": "Thunder Shock",
		    "Ancientpower": "Ancient Power",
		    "Extremespeed": "Extreme Speed",
		    "Dragonbreath": "Dragon Breath",
		    "Dynamicpunch": "Dynamic Punch",
		    "Grasswhistle": "Grass Whistle",
		    "Featherdance": "Feather Dance",
		    "Faint Attack": "Feint Attack",
		    "Smellingsalt": "Smelling Salts",
		    "Roar Of Time": "Roar of Time",
		    "U-Turn": "U-turn",
		    "V-Create": "V-create",
		    "Sand-Attack": "Sand Attack",
		    "Selfdestruct": "Self-Destruct",
		    "Softboiled": "Soft-Boiled",
		    "Vicegrip": "Vise Grip",
		    "Hi Jump Kick": "High Jump Kick",
		    "BlackGlasses": "Black Glasses",
		    "BrightPowder": "Bright Powder",
		    "NeverMeltIce": "Never-Melt Ice", 
		    "SilverPowder": "Silver Powder",
		    "TwistedSpoon": "Twisted Spoon"
		}
	end

	def self.sub_showdown(move)
		subs = showdown_subs
		if showdown_subs[move.to_sym]
			return showdown_subs[move.to_sym]
		else
			return move
		end
	end


	@aiAbilities = [
        [ "Drought", "Chlorophyll", "Solar Power"],     # PK_NULL = 0x

		#
		# KANTO
		#
        [ "Drought", "Chlorophyll", "Flower Gift"],     # PK[ "Stench", "Stench", "Stench"],1_BULBASAUR = 0x
        [ "Drought", "Chlorophyll", "Flower Gift"],     # PK002_IVYSAUR = 0x2,
        [ "Drought", "Chlorophyll", "Flower Gift"],     # PK003_VENUSAUR = 0x3,
        [ "Drought", "Intimidate", "Turboblaze"],     # PK004_CHARMANDER = 0x4,
        [ "Drought", "Intimidate", "Turboblaze"],     # PK005_CHARMELEON = 0x5,
        [ "Drought", "Intimidate", "Turboblaze"],     # PK006_CHARIZARD = 0x6,
        [ "Drizzle", "Quick Draw", "Ballistics"],     # PK007_SQUIRTLE = 0x7,
        [ "Drizzle", "Quick Draw", "Ballistics"],     # PK008_WARTORTLE = 0x8,
        [ "Drizzle", "Quick Draw", "Ballistics"],     # PK009_BLASTOISE = 0x9,
        [ "Anticipation", "Serene Grace", "Serene Grace"],     # PK010_CATERPIE = 0xA,
        [ "Anticipation", "Serene Grace", "Serene Grace"],     # PK011_METAPOD = 0xB,
        [ "Anticipation", "Serene Grace", "Serene Grace"],     # PK012_BUTTERFREE = 0xC,
        [ "Sniper", "Anticipation", "Anticipation"],     # PK013_WEEDLE = 0xD,
        [ "Sniper", "Anticipation", "Anticipation"],     # PK014_KAKUNA = 0xE,
        [ "Sniper", "Anticipation", "Anticipation"],     # PK015_BEEDRILL = 0xF,
        [ "Serene Grace", "Serene Grace", "Serene Grace"],     # [ "Stench", "Stench", "Stench"],016_PIDGEY = 0x1
        [ "Serene Grace", "Serene Grace", "Serene Grace"],     # PK017_PIDGEOTTO = 0x1[ "Stench", "Stench", "Stench"],
        [ "Serene Grace", "Serene Grace", "Serene Grace"],     # PK018_PIDGEOT = 0x12,
        [ "Stench", "Stench", "Stench"],     # PK019_RATTATA = 0x13,
        [ "Stench", "Stench", "Stench"],     # PK020_RATICATE = 0x14,
        [ "Sniper", "Sniper", "Sniper"],     # PK021_SPEAROW = 0x15,
        [ "Sniper", "Sniper", "Sniper"],     # PK022_FEAROW = 0x16,
        [ "Stakeout", "Arena Trap", "Stench"],     # PK023_EKANS = 0x17,
        [ "Stakeout", "Arena Trap", "Stench"],     # PK024_ARBOK = 0x18,
        [ "Plus", "Minus", "Minus"],     # PK025_PIKACHU = 0x19,
        [ "Plus", "Minus", "Minus"],     # PK026_RAICHU = 0x1A,
        [ "Sand Stream", "Sand Veil", "Sand Veil"],     # PK027_SANDSHREW = 0x1B,
        [ "Sand Stream", "Sand Veil", "Sand Veil"],     # PK028_SANDSLASH = 0x1C,
        [ "Sand Stream", "Sand Veil", "Anger Point"],     # PK029_NIDORAN = 0x1D,
        [ "Sand Stream", "Sand Veil", "Anger Point"],     # PK030_NIDORINA = 0x1E,
        [ "Sand Stream", "Sand Veil", "Anger Point"],     # PK031_NIDOQUEEN = 0x1F,
        [ "Sand Stream", "Sand Veil", "Anger Point"],     # PK032_NIDORAN = 0x2[ "Stench", "Stench", "Stench"],
        [ "Sand Stream", "Sand Veil", "Anger Point"],     # PK[ "Stench", "Stench", "Stench"],3_NIDORINO = 0x2
        [ "Sand Stream", "Sand Veil", "Anger Point"],     # PK034_NIDOKING = 0x22,
        [ "Simple", "Simple", "Simple"],     # PK035_CLEFAIRY = 0x23,
        [ "Simple", "Simple", "Simple"],     # PK036_CLEFABLE = 0x24,
        [ "Drought", "Illusion", "Illusion"],     # PK037_VULPIX = 0x25,
        [ "Drought", "Illusion", "Illusion"],     # PK038_NINETALES = 0x26,
        [ "Moody", "Fluffy", "Simple"],     # PK039_JIGGLYPUFF = 0x27,
        [ "Moody", "Fluffy", "Simple"],       # PK040_WIGGLYTUFF = 0x28,
        [ "Shadow Tag", "Stakeout", "Anticipation"],     # PK041_ZUBAT = 0x29,
        [ "Shadow Tag", "Stakeout", "Anticipation"],     # PK042_GOLBAT = 0x2A,
        [ "Stench", "Effect Spore", "Drought"],     # PK043_ODDISH = 0x2B,
        [ "Stench", "Effect Spore", "Drought"],     # PK044_GLOOM = 0x2C,
        [ "Stench", "Effect Spore", "Drought"],     # PK045_VILEPLUME = 0x2D,
        [ "Effect Spore", "Stakeout", "Shadow Tag"],     # PK046_PARAS = 0x2E,
        [ "Effect Spore", "Stakeout", "Shadow Tag"],     # PK047_PARASECT = 0x2F,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK048_VENONAT = 0x3[ "Stench", "Stench", "Stench"],
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK[ "Stench", "Stench", "Stench"],9_VENOMOTH = 0x3
        [ "Stakeout", "Arena Trap", "Sand Veil"],     # PK050_DIGLETT = 0x32,
        [ "Stakeout", "Arena Trap", "Sand Veil"],     # PK051_DUGTRIO = 0x33,
        [ "Pickpocket", "Anticipation", "Anticipation"],     # PK052_MEOWTH = 0x34,
        [ "Pickpocket", "Anticipation", "Anticipation"],     # PK053_PERSIAN = 0x35,
        [ "Drizzle", "Anticipation", "Trace"],     # PK054_PSYDUCK = 0x36,
        [ "Drizzle", "Anticipation", "Trace"],     # PK055_GOLDUCK = 0x37,
        [ "Hustle", "Anger Point", "Moody"],     # PK056_MANKEY = 0x38,
        [ "Hustle", "Anger Point", "Moody"],     # PK057_PRIMEAPE = 0x39,
        [ "Drought", "Drought", "Drought"],     # PK058_GROWLITHE = 0x3A,
        [ "Drought", "Drought", "Drought"],     # PK059_ARCANINE = 0x3B,
        [ "Drizzle", "Mold Breaker", "Mold Breaker"],     # PK060_POLIWAG = 0x3C,
        [ "Drizzle", "Mold Breaker", "Mold Breaker"],     # PK061_POLIWHIRL = 0x3D,
        [ "Drizzle", "Mold Breaker", "Mold Breaker"],     # PK062_POLIWRATH = 0x3E,
        [ "Anticipation", "Illusion", "Savant"],     # PK063_ABRA = 0x3F,
        [ "Anticipation", "Illusion", "Savant"],     # PK064_KADABRA = 0x4[ "Stench", "Stench", "Stench"],
        [ "Anticipation", "Illusion", "Savant"],     # PK[ "Stench", "Stench", "Stench"],5_ALAKAZAM = 0x4
        [ "Mold Breaker", "Mold Breaker", "Mold Breaker"],     # PK066_MACHOP = 0x42,
        [ "Mold Breaker", "Mold Breaker", "Mold Breaker"],     # PK067_MACHOKE = 0x43,
        [ "Mold Breaker", "Mold Breaker", "Mold Breaker"],     # PK068_MACHAMP = 0x44,
        [ "Stench", "Stakeout", "Arena Trap"],     # PK069_BELLSPROUT = 0x45,
        [ "Stench", "Stakeout", "Arena Trap"],     # PK070_WEEPINBELL = 0x46,
        [ "Stench", "Stakeout", "Arena Trap"],     # PK071_VICTREEBEL = 0x47,
        [ "Drizzle", "Stakeout", "Arena Trap"],     # PK072_TENTACOOL = 0x48,
        [ "Drizzle", "Stakeout", "Arena Trap"],     # PK073_TENTACRUEL = 0x49,
        [ "Aftermath", "Sand Stream", "Sand Veil"],     # PK074_GEODUDE = 0x4A,
        [ "Aftermath", "Sand Stream", "Sand Veil"],     # PK075_GRAVELER = 0x4B,
        [ "Aftermath", "Sand Stream", "Sand Veil"],     # PK076_GOLEM = 0x4C,
        [ "Drought", "Hustle", "Serene Grace"],     # PK077_PONYTA = 0x4D,
        [ "Drought", "Hustle", "Serene Grace"],     # PK078_RAPIDASH = 0x4E,
        [ "Drizzle", "Simple", "Simple"],     # PK079_SLOWPOKE = 0x4F,
        [ "Drizzle", "Simple", "Simple"],     # P[ "Stench", "Stench", "Stench"],80_SLOWBRO = 0x5
        [ "Minus", "Plus", "Levitate"],     # PK0[ "Stench", "Stench", "Stench"],_MAGNEMITE = 0x5
        [ "Minus", "Plus", "Levitate"],     # PK082_MAGNETON = 0x52,
        [ "Quick Draw", "Hustle", "Hustle"],     # PK083_FARFETCH_D = 0x53,
        [ "Sand Stream", "Moody", "Sand Veil"],     # PK084_DODUO = 0x54,
        [ "Sand Stream", "Moody", "Sand Veil"],     # PK085_DODRIO = 0x55,
        [ "Snow Warning", "Slush Rush", "Snow Cloak"],     # PK086_SEEL = 0x56,
        [ "Snow Warning", "Slush Rush", "Snow Cloak"],     # PK087_DEWGONG = 0x57,
        [ "Stench", "Poison Touch", "Poison Touch"],     # PK088_GRIMER = 0x58,
        [ "Stench", "Poison Touch", "Poison Touch"],     # PK089_MUK = 0x59,
        [ "Quick Draw", "Aftermath", "Snow Warning"],     # PK090_SHELLDER = 0x5A,
        [ "Quick Draw", "Aftermath", "Snow Warning"],     # PK091_CLOYSTER = 0x5B,
        [ "Shadow Tag", "Illusion", "Stench"],     # PK092_GASTLY = 0x5C,
        [ "Shadow Tag", "Illusion", "Stench"],     # PK093_HAUNTER = 0x5D,
        [ "Shadow Tag", "Illusion", "Stench"],     # PK094_GENGAR = 0x5E,
        [ "Sand Stream", "Sand Rush", "Sand Veil"],     # PK095_ONIX = 0x5F,
        [ "Shadow Tag", "Illusion", "Illusion"],     # PK096_DROWZEE = 0x6[ "Stench", "Stench", "Stench"],
        [ "Shadow Tag", "Illusion", "Illusion"],     #[ "Stench", "Stench", "Stench"],K097_HYPNO = 0x6
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK098_KRABBY = 0x62,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK099_KINGLER = 0x63,
        [ "Plus", "Minus", "Aftermath"],     # PK100_VOLTORB = 0x64,
        [ "Plus", "Minus", "Aftermath"],     # PK101_ELECTRODE = 0x65,
        [ "Moody", "Aftermath", "Overcoat"],     # PK102_EXEGGCUTE = 0x66,
        [ "Moody", "Aftermath", "Overcoat"],     # PK103_EXEGGUTOR = 0x67,
        [ "Quick Draw", "Sand Stream", "Overcoat"],     # PK104_CUBONE = 0x68,
        [ "Quick Draw", "Sand Stream", "Overcoat"],     # PK105_MAROWAK = 0x69,
        [ "Hustle", "Strong Body", "Strong Body"],     # PK106_HITMONLEE = 0x6A,
        [ "Hustle", "Strong Body", "Strong Body"],     # PK107_HITMONCHAN = 0x6B,
        [ "Stench", "Stench", "Stench"],     # PK108_LICKITUNG = 0x6C,
        [ "Aftermath", "Quick Draw", "Stench"],     # PK109_KOFFING = 0x6D,
        [ "Aftermath", "Quick Draw", "Stench"],     # PK110_WEEZING = 0x6E,
        [ "Sand Stream", "Berserk", "Berserk"],     # PK111_RHYHORN = 0x6F,
        [ "Sand Stream", "Berserk", "Berserk"],     # PK112_RHYDON = 0x7[ "Stench", "Stench", "Stench"],
        [ "Huge Power", "Huge Power", "Huge Power"],     # PK113_CHANSEY = 0x7[ "Stench", "Stench", "Stench"],
        [ "Chlorophyll", "Chlorophyll", "Chlorophyll"],     # PK114_TANGELA = 0x72,
        [ "Hustle", "Hustle", "Hustle"],     # PK115_KANGASKHAN = 0x73,
        [ "Drizzle", "Quick Draw", "Serene Grace"],     # PK116_HORSEA = 0x74,
        [ "Drizzle", "Quick Draw", "Serene Grace"],     # PK117_SEADRA = 0x75,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK118_GOLDEEN = 0x76,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK119_SEAKING = 0x77,
        [ "Drizzle", "Patient", "Swift Swim"],     # PK120_STARYU = 0x78,
        [ "Drizzle", "Patient", "Swift Swim"],     # PK121_STARMIE = 0x79,
        [ "Savant", "Moody", "Illusion"],     # PK122_MR_MIME = 0x7A,
        [ "Strong Body", "Sturdy", "Sturdy"],     # PK123_SCYTHER = 0x7B,
        [ "Snow Warning", "Illusion", "Snow Cloak"],     # PK124_JYNX = 0x7C,
        [ "Minus", "Anger Point", "Plus"],     # PK125_ELECTABUZZ = 0x7D,
        [ "Quick Draw", "Drought", "Aftermath"],     # PK126_MAGMAR = 0x7E,
        [ "Sand Stream", "Intimidate", "Hustle"],     # PK127_PINSIR = 0x7F,
        [ "Moody", "Berserk", "Hustle"],     # PK128_TAUROS = 0x8[ "Stench", "Stench", "Stench"],
        [ "Berserk", "Drizzle", "Swift Swim"],     # PK129_MAGIKARP = 0x8[ "Stench", "Stench", "Stench"],
        [ "Berserk", "Drizzle", "Swift Swim"],     # PK130_GYARADOS = 0x82,
        [ "Snow Warning", "Snow Cloak", "Filter"],     # PK131_LAPRAS = 0x83,
        [ "Stench", "Stench", "Stench"],     # PK132_DITTO = 0x84,
        [ "Anticipation", "Moody", "Moody"],     # PK133_EEVEE = 0x85,
        [ "Anticipation", "Drizzle", "Drizzle"],     # PK134_VAPOREON = 0x86,
        [ "Anticipation", "Plus", "Minus"],     # PK135_JOLTEON = 0x87,
        [ "Anticipation", "Drought", "Drought"],     # PK136_FLAREON = 0x88,
        [ "Levitate", "Levitate", "Levitate"],     # PK137_PORYGON = 0x89,
        [ "Swift Swim", "Sturdy", "Sturdy"],     # PK138_OMANYTE = 0x8A,
        [ "Swift Swim", "Sturdy", "Sturdy"],     # PK139_OMASTAR = 0x8B,
        [ "Stench", "Stench", "Stench"],     # PK140_KABUTO = 0x8C,
        [ "Stench", "Stench", "Stench"],     # PK141_KABUTOPS = 0x8D,
        [ "Sand Stream", "Sand Veil", "Intimidate"],     # PK142_AERODACTYL = 0x8E,
        [ "Normalize", "Normalize", "Normalize"],     # PK143_SNORLAX = 0x8F,
        [ "Snow Warning", "Snow Cloak", "Snow Cloak"],     # PK[ "Stench", "Stench", "Stench"],4_ARTICUNO = 0x9
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK145_ZAPDOS = 0x9[ "Stench", "Stench", "Stench"],
        [ "Drought", "Drought", "Drought"],     # PK146_MOLTRES = 0x92,
        [ "Stench", "Stench", "Stench"],     # PK147_DRATINI = 0x93,
        [ "Stench", "Stench", "Stench"],     # PK148_DRAGONAIR = 0x94,
        [ "Stench", "Stench", "Stench"],     # PK149_DRAGONITE = 0x95,
        [ "Mold Breaker", "Unnerve", "Neutralizing Gas"],     # PK150_MEWTWO = 0x96,
        [ "Mold Breaker", "Unnerve", "Neutralizing Gas"],     # PK151_MEW = 0x97,

		#
		# JOHTO
		#
        [ "Flower Gift", "Flower Gift", "Flower Gift"],     # PK152_CHIKORITA = 0x98,
        [ "Flower Gift", "Flower Gift", "Flower Gift"],     # PK153_BAYLEEF = 0x99,
        [ "Flower Gift", "Flower Gift", "Flower Gift"],     # PK154_MEGANIUM = 0x9A,
        [ "Drought", "Sand Stream", "Sand Rush"],     # PK155_CYNDAQUIL = 0x9B,
        [ "Drought", "Sand Stream", "Sand Rush"],     # PK156_QUILAVA = 0x9C,
        [ "Drought", "Sand Stream", "Sand Rush"],     # PK157_TYPHLOSION = 0x9D,
        [ "Drizzle", "Stakeout", "Intimidate"],     # PK158_TOTODILE = 0x9E,
        [ "Drizzle", "Stakeout", "Intimidate"],     # PK159_CROCONAW = 0x9F,
        [ "Drizzle", "Stakeout", "Intimidate"],     # PK16[ "Stench", "Stench", "Stench"],FERALIGATR = 0xA
        [ "Stakeout", "Stakeout", "Stakeout"],     # PK161_SENTRET = 0xA[ "Stench", "Stench", "Stench"],
        [ "Stakeout", "Stakeout", "Stakeout"],     # PK162_FURRET = 0xA2,
        [ "Stakeout", "Illusion", "Shadow Tag"],     # PK163_HOOTHOOT = 0xA3,
        [ "Stakeout", "Illusion", "Shadow Tag"],     # PK164_NOCTOWL = 0xA4,
        [ "Stench", "Stench", "Stench"],     # PK165_LEDYBA = 0xA5,
        [ "Stench", "Stench", "Stench"],     # PK166_LEDIAN = 0xA6,
        [ "Stakeout", "Arena Trap", "Arena Trap"],     # PK167_SPINARAK = 0xA7,
        [ "Stakeout", "Arena Trap", "Arena Trap"],     # PK168_ARIADOS = 0xA8,
        [ "Shadow Tag", "Stakeout", "Anticipation"],     # PK169_CROBAT = 0xA9,
        [ "Drizzle", "Minus", "Plus"],     # PK170_CHINCHOU = 0xAA,
        [ "Drizzle", "Minus", "Plus"],     # PK171_LANTURN = 0xAB,
        [ "Plus", "Minus", "Minus"],     # PK172_PICHU = 0xAC,
        [ "Stench", "Stench", "Stench"],     # PK173_CLEFFA = 0xAD,
        [ "Moody", "Fluffy", "Fluffy"],     # PK174_IGGLYBUFF = 0xAE,
        [ "Healer", "Healer", "Healer"],     # PK175_TOGEPI = 0xAF,
        [ "Healer", "Healer", "Healer"],     # PK176_TOGETIC = 0xB[ "Stench", "Stench", "Stench"],
        [ "Illusion", "Illusion", "Illusion"],     #[ "Stench", "Stench", "Stench"],PK177_NATU = 0xB
        [ "Illusion", "Illusion", "Illusion"],     # PK178_XATU = 0xB2,
        [ "Plus", "Fluffy", "Minus"],     # PK179_MAREEP = 0xB3,
        [ "Plus", "Fluffy", "Minus"],     # PK180_FLAAFFY = 0xB4,
        [ "Plus", "Fluffy", "Minus"],     # PK181_AMPHAROS = 0xB5,
        [ "Effect Spore", "Drought", "Flower Gift"],     # PK182_BELLOSSOM = 0xB6,
        [ "Stench", "Stench", "Stench"],     # PK183_MARILL = 0xB7,
        [ "Stench", "Stench", "Stench"],     # PK184_AZUMARILL = 0xB8,
        [ "Sand Stream", "Stakeout", "Hustle"],     # PK185_SUDOWOODO = 0xB9,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK186_POLITOED = 0xBA,
        [ "Drought", "Simple", "Hustle"],     # PK187_HOPPIP = 0xBB,
        [ "Drought", "Simple", "Hustle"],     # PK188_SKIPLOOM = 0xBC,
        [ "Drought", "Simple", "Hustle"],     # PK189_JUMPLUFF = 0xBD,
        [ "Stench", "Stench", "Stench"],     # PK190_AIPOM = 0xBE,
        [ "Drought", "Drought", "Drought"],      # PK191_SUNKERN = 0xBF,
        [ "Drought", "Drought", "Drought"],      # PK[ "Stench", "Stench", "Stench"],2_SUNFLORA = 0xC
        [ "Stench", "Stench", "Stench"],     #[ "Stench", "Stench", "Stench"],K193_YANMA = 0xC
        [ "Drizzle", "Simple", "Simple"],     # PK194_WOOPER = 0xC2,
        [ "Drizzle", "Simple", "Simple"],     # PK195_QUAGSIRE = 0xC3,
        [ "Anticipation", "Illusion", "Inner Focus"],     # PK196_ESPEON = 0xC4,
        [ "Anticipation", "Stakeout", "Illusion"],     # PK197_UMBREON = 0xC5,
        [ "Stakeout", "Moxie", "Moxie"],     # PK198_MURKROW = 0xC6,
        [ "Drizzle", "Simple", "Simple"],     # PK199_SLOWKING = 0xC7,
        [ "Illusion", "Shadow Tag", "Shadow Tag"],     # PK200_MISDREAVUS = 0xC8,
        [ "Illusion", "Shadow Tag", "Shadow Tag"],      # PK201_UNOWN = 0xC9,
        [ "Shadow Tag", "Shadow Tag", "Shadow Tag"],     # PK202_WOBBUFFET = 0xCA,
        [ "Moody", "Moody", "Moody"],     # PK203_GIRAFARIG = 0xCB,
        [ "Aftermath", "Quick Draw", "Sturdy"],     # PK204_PINECO = 0xCC,
        [ "Aftermath", "Quick Draw", "Sturdy"],     # PK205_FORRETRESS = 0xCD,
        [ "Sand Stream", "Sand Veil", "Sand Veil"],     # PK206_DUNSPARCE = 0xCE,
        [ "Sand Stream", "Sand Veil", "Sand Veil"],     # PK207_GLIGAR = 0xCF,
        [ "Sand Stream", "Sand Rush", "Colossal"],     # PK208_STEELIX = 0xD[ "Stench", "Stench", "Stench"],
        [ "Guts", "Moody", "Anger Point"],     # PK[ "Stench", "Stench", "Stench"],9_SNUBBULL = 0xD
        [ "Guts", "Moody", "Anger Point"],     # PK210_GRANBULL = 0xD2,
        [ "Drizzle", "Aftermath", "Quick Draw"],     # PK211_QWILFISH = 0xD3,
        [ "Strong Body", "Sturdy", "Sturdy"],     # PK212_SCIZOR = 0xD4,
        [ "Sand Stream", "Moody", "Moody"],     # PK213_SHUCKLE = 0xD5,
        [ "Stench", "Stench", "Stench"],     # PK214_HERACROSS = 0xD6,
        [ "Technician", "Snow Warning", "Snow Cloak"],     # PK215_SNEASEL = 0xD7,
        [ "Sand Stream", "Hustle", "Hustle"],     # PK216_TEDDIURSA = 0xD8,
        [ "Sand Stream", "Hustle", "Hustle"],     # PK217_URSARING = 0xD9,
        [ "Aftermath", "Dry Skin", "Drought"],     # PK218_SLUGMA = 0xDA,
        [ "Aftermath", "Dry Skin", "Drought"],     # PK219_MAGCARGO = 0xDB,
        [ "Snow Warning", "Snow Cloak", "Anger Point"],     # PK220_SWINUB = 0xDC,
        [ "Snow Warning", "Snow Cloak", "Anger Point"],     # PK221_PILOSWINE = 0xDD,
        [ "Sand Stream", "Dry Skin", "Hustle"],     # PK222_CORSOLA = 0xDE,
        [ "Stakeout", "Quick Draw", "Moody"],     # PK223_REMORAID = 0xDF,
        [ "Stakeout", "Quick Draw", "Moody"],     # PK2[ "Stench", "Stench", "Stench"],_OCTILLERY = 0xE
        [ "Levitate", "Moody", "Snow Cloak"],     # PK225_DELIBIRD = 0xE[ "Stench", "Stench", "Stench"],
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK226_MANTINE = 0xE2,
        [ "Thunder Armor", "Sand Veil", "Sand Veil"],     # PK227_SKARMORY = 0xE3,
        [ "Turboblaze", "Intimidate", "Solar Power"],     # PK228_HOUNDOUR = 0xE4,
        [ "Turboblaze", "Intimidate", "Solar Power"],     # PK229_HOUNDOOM = 0xE5,
        [ "Drizzle", "Quick Draw", "Serene Grace"],     # PK230_KINGDRA = 0xE6,
        [ "Sand Stream", "Sand Veil", "Sturdy"],     # PK231_PHANPY = 0xE7,
        [ "Sand Stream", "Sand Veil", "Sturdy"],     # PK232_DONPHAN = 0xE8,
        [ "Levitate", "Levitate", "Levitate"],     # PK233_PORYGON2 = 0xE9,
        [ "Intimidate", "Illusion", "Shadow Tag"],     # PK234_STANTLER = 0xEA,
        [ "Moody", "Moody", "Moody"],     # PK235_SMEARGLE = 0xEB,
        [ "Hustle", "Strong Body", "Strong Body"],     # PK236_TYROGUE = 0xEC,
        [ "Hustle", "Strong Body", "Strong Body"],     # PK237_HITMONTOP = 0xED,
        [ "Snow Warning", "Illusion", "Snow Cloak"],     # PK238_SMOOCHUM = 0xEE,
        [ "Minus", "Anger Point", "Plus"],     # PK239_ELEKID = 0xEF,
        [ "Quick Draw", "Drought", "Aftermath"],     #[ "Stench", "Stench", "Stench"],K240_MAGBY = 0xF
        [ "Stench", "Stench", "Stench"],     # P[ "Stench", "Stench", "Stench"],41_MILTANK = 0xF
        [ "Huge Power", "Huge Power", "Huge Power"],     # PK242_BLISSEY = 0xF2,
        [ "Stench", "Stench", "Stench"],     # PK243_RAIKOU = 0xF3,
        [ "Stench", "Stench", "Stench"],     # PK244_ENTEI = 0xF4,
        [ "Stench", "Stench", "Stench"],     # PK245_SUICUNE = 0xF5,
        [ "Sand Stream", "Solid Rock", "Solid Rock"],     # PK246_LARVITAR = 0xF6,
        [ "Sand Stream", "Solid Rock", "Solid Rock"],     # PK247_PUPITAR = 0xF7,
        [ "Sand Stream", "Solid Rock", "Solid Rock"],     # PK248_TYRANITAR = 0xF8,
        [ "Stench", "Stench", "Stench"],     # PK249_LUGIA = 0xF9,
        [ "Stench", "Stench", "Stench"],     # PK250_HO_OH = 0xFA,
        [ "Stench", "Stench", "Stench"],     # PK251_CELEBI = 0xFB,
		
		#
		# HOENN
		#
        [ "Anticipation", "Sniper", "Solar Power"],     # PK252_TREECKO = 0xFC,
        [ "Anticipation", "Sniper", "Solar Power"],     # PK253_GROVYLE = 0xFD,
        [ "Anticipation", "Sniper", "Solar Power"],     # PK254_SCEPTILE = 0xFE,
        [ "Speed Boost", "Drought", "Hustle"],     # PK255_TORCHIC = 0xFF,
        [ "Speed Boost", "Drought", "Hustle"],     # PK25[ "Stench", "Stench", "Stench"],COMBUSKEN = 0x10
        [ "Speed Boost", "Drought", "Hustle"],     # PK257_BLAZIKEN = 0x10[ "Stench", "Stench", "Stench"],
        [ "Drizzle", "Sand Stream", "Anticipation"],     # PK258_MUDKIP = 0x102,
        [ "Drizzle", "Sand Stream", "Anticipation"],     # PK259_MARSHTOMP = 0x103,
        [ "Drizzle", "Sand Stream", "Anticipation"],     # PK260_SWAMPERT = 0x104,
        [ "Stench", "Stench", "Stench"],     # PK261_POOCHYENA = 0x105,
        [ "Stench", "Stench", "Stench"],     # PK262_MIGHTYENA = 0x106,
        [ "Stakeout", "Stakeout", "Stakeout"],     # PK263_ZIGZAGOON = 0x107,
        [ "Stakeout", "Stakeout", "Stakeout"],     # PK264_LINOONE = 0x108,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK265_WURMPLE = 0x109,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK266_SILCOON = 0x10A,
        [ "Anticipation", "Serene Grace", "Serene Grace"],     # PK267_BEAUTIFLY = 0x10B,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK268_CASCOON = 0x10C,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK269_DUSTOX = 0x10D,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK270_LOTAD = 0x10E,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK271_LOMBRE = 0x10F,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK2[ "Stench", "Stench", "Stench"],_LUDICOLO = 0x11
        [ "Drought", "Aftermath", "Anticipation"],     # P[ "Stench", "Stench", "Stench"],73_SEEDOT = 0x11
        [ "Drought", "Aftermath", "Anticipation"],     # PK274_NUZLEAF = 0x112,
        [ "Drought", "Aftermath", "Anticipation"],     # PK275_SHIFTRY = 0x113,
        [ "Stench", "Stench", "Stench"],     # PK276_TAILLOW = 0x114,
        [ "Stench", "Stench", "Stench"],     # PK277_SWELLOW = 0x115,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK278_WINGULL = 0x116,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK279_PELIPPER = 0x117,
        [ "Illusion", "Anticipation", "Anticipation"],     # PK280_RALTS = 0x118,
        [ "Illusion", "Anticipation", "Anticipation"],     # PK281_KIRLIA = 0x119,
        [ "Illusion", "Anticipation", "Anticipation"],     # PK282_GARDEVOIR = 0x11A,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK283_SURSKIT = 0x11B,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK284_MASQUERAIN = 0x11C,
        [ "Stench", "Effect Spore", "Effect Spore"],     # PK285_SHROOMISH = 0x11D,
        [ "Stench", "Effect Spore", "Effect Spore"],     # PK286_BRELOOM = 0x11E,
        [ "Guts", "Strong Body", "Unaware"],     # PK287_SLAKOTH = 0x11F,
        [ "Guts", "Strong Body", "Unaware"],     # PK2[ "Stench", "Stench", "Stench"],_VIGOROTH = 0x12
        [ "Guts", "Strong Body", "Unaware"],     # PK289_SLAKING = 0x12[ "Stench", "Stench", "Stench"],
        [ "Stakeout", "Sniper", "Sniper"],     # PK290_NINCADA = 0x122,
        [ "Stakeout", "Sniper", "Sniper"],     # PK291_NINJASK = 0x123,
        [ "Stakeout", "Sniper", "ABIL025_WONDER_GUARD"],     # PK292_SHEDINJA = 0x124,
        [ "Moody", "Anger Point", "Scrappy"],     # PK293_WHISMUR = 0x125,
        [ "Moody", "Anger Point", "Scrappy"],     # PK294_LOUDRED = 0x126,
        [ "Moody", "Anger Point", "Scrappy"],     # PK295_EXPLOUD = 0x127,
        [ "Scrappy", "Scrappy", "Scrappy"],     # PK296_MAKUHITA = 0x128,
        [ "Scrappy", "Scrappy", "Scrappy"],     # PK297_HARIYAMA = 0x129,
        [ "Stench", "Stench", "Stench"],     # PK298_AZURILL = 0x12A,
        [ "Sand Stream", "Sand Stream", "Sand Stream"],     # PK299_NOSEPASS = 0x12B,
        [ "Moody", "Fur Coat", "Fur Coat"],     # PK300_SKITTY = 0x12C,
        [ "Moody", "Fur Coat", "Fur Coat"],     # PK301_DELCATTY = 0x12D,
        [ "Stakeout", "Shadow Tag", "Shadow Tag"],     # PK302_SABLEYE = 0x12E,
        [ "Huge Power", "Arena Trap", "Arena Trap"],     # PK303_MAWILE = 0x12F,
        [ "Stench", "Stench", "Stench"],     #[ "Stench", "Stench", "Stench"],K304_ARON = 0x13
        [ "Stench", "Stench", "Stench"],     # PK305_LAIRON = 0x13[ "Stench", "Stench", "Stench"],
        [ "Stench", "Stench", "Stench"],     # PK306_AGGRON = 0x132,
        [ "Stench", "Stench", "Stench"],     # PK307_MEDITITE = 0x133,
        [ "Stench", "Stench", "Stench"],     # PK308_MEDICHAM = 0x134,
        [ "Plus", "Minus", "Minus"],     # PK309_ELECTRIKE = 0x135,
        [ "Plus", "Minus", "Minus"],     # PK310_MANECTRIC = 0x136,
        [ "Plus", "Minus", "Minus"],     # PK311_PLUSLE = 0x137,
        [ "Minus", "Plus", "Plus"],     # PK312_MINUN = 0x138,
        [ "Plus", "Minus", "Minus"],     # PK313_VOLBEAT = 0x139,
        [ "Minus", "Plus", "Plus"],     # PK314_ILLUMISE = 0x13A,
        [ "Stench", "Stench", "Stench"],     # PK315_ROSELIA = 0x13B,
        [ "Stench", "Stench", "Stench"],     # PK316_GULPIN = 0x13C,
        [ "Stench", "Stench", "Stench"],     # PK317_SWALOT = 0x13D,
        [ "Drizzle", "Drizzle", "Drizzle"],     #  PK318_CARVANHA = 0x13E,
        [ "Drizzle", "Drizzle", "Drizzle"],     #  PK319_SHARPEDO = 0x13F,
        [ "Drizzle", "Drizzle", "Drizzle"],     #   PK[ "Stench", "Stench", "Stench"],0_WAILMER = 0x14
        [ "Drizzle", "Moisturize", "Colossal"],     #   PK321_WAILORD = 0x14[ "Stench", "Stench", "Stench"],
        [ "Aftermath", "Simple", "Drought"],     #   PK322_NUMEL = 0x142,
        [ "Aftermath", "Simple", "Drought"],     #   PK323_CAMERUPT = 0x143,
        [ "Aftermath", "Simple", "Drought"],     #  PK324_TORKOAL = 0x144,
        [ "Moody", "Trace", "Trace"],     # PK325_SPOINK = 0x145,
        [ "Moody", "Trace", "Trace"],     # PK326_GRUMPIG = 0x146,
        [ "Moody", "Moody", "Moody"],     #   PK327_SPINDA = 0x147,
        [ "Sand Stream", "Sand Rush", "Sand Veil"],     # PK328_TRAPINCH = 0x148,
        [ "Sand Stream", "Sand Rush", "Sand Veil"],     # PK329_VIBRAVA = 0x149,
        [ "Sand Stream", "Sand Rush", "Sand Veil"],     # PK330_FLYGON = 0x14A,
        [ "Stakeout", "Sand Veil", "Sand Veil"],     #  PK331_CACNEA = 0x14B,
        [ "Stakeout", "Sand Veil", "Sand Veil"],     #  PK332_CACTURNE = 0x14C,
        [ "Fluffy", "Overcoat", "Overcoat"],     #   PK333_SWABLU = 0x14D,
        [ "Fluffy", "Overcoat", "Overcoat"],     #   PK334_ALTARIA = 0x14E,
        [ "Stench", "Stench", "Stench"],     #   PK335_ZANGOOSE = 0x14F,
        [ "Stench", "Stench", "Stench"],     #  PK[ "Stench", "Stench", "Stench"],6_SEVIPER = 0x15
        [ "Sand Stream", "Wonder Guard", "Sand Stream"],     #  PK337_LUNATONE = 0x15[ "Stench", "Stench", "Stench"],
        [ "Drought", "Wonder Guard", "Drought"],     #   PK338_SOLROCK = 0x152,
        [ "Drizzle", "Sand Stream", "Sand Stream"],     # PK339_BARBOACH = 0x153,
        [ "Drizzle", "Sand Stream", "Sand Stream"],     # PK340_WHISCASH = 0x154,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK341_CORPHISH = 0x155,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK342_CRAWDAUNT = 0x156,
        [ "Sand Stream", "Speed Boost", "Arena Trap"],     #  PK343_BALTOY = 0x157,
        [ "Sand Stream", "Speed Boost", "Arena Trap"],     #   PK344_CLAYDOL = 0x158,
        [ "Sand Stream", "Stakeout", "Sand Veil"],     # PK345_LILEEP = 0x159,
        [ "Sand Stream", "Stakeout", "Sand Veil"],     # PK346_CRADILY = 0x15A,
        [ "Swift Swim", "Sand Stream", "Sand Veil"],     # PK347_ANORITH = 0x15B,
        [ "Swift Swim", "Sand Stream", "Sand Veil"],     # PK348_ARMALDO = 0x15C,
        [ "Drizzle", "Serene Grace", "Serene Grace"],     # PK349_FEEBAS = 0x15D,
        [ "Drizzle", "Serene Grace", "Serene Grace"],     # PK350_MILOTIC = 0x15E,
        [ "Stench", "Stench", "Stench"],     # PK351_CASTFORM = 0x15F,
        [ "Shadow Tag", "Anticipation", "Illusion"],     #  PK352_KECLEON = 0x16[ "Stench", "Stench", "Stench"],
        [ "Shadow Tag", "Anticipation", "Illusion"],     #  PK[ "Stench", "Stench", "Stench"],3_SHUPPET = 0x16
        [ "Shadow Tag", "Anticipation", "Illusion"],     #   PK354_BANETTE = 0x162,
        [ "Shadow Tag", "Anticipation", "Illusion"],     #   PK355_DUSKULL = 0x163,
        [ "Shadow Tag", "Anticipation", "Illusion"],     #   PK356_DUSCLOPS = 0x164,
        [ "Stench", "Stench", "Stench"],     # PK357_TROPIUS = 0x165,
        [ "Stench", "Stench", "Stench"],     #   PK358_CHIMECHO = 0x166,
        [ "Anticipation", "Stakeout", "Sniper"],     # PK359_ABSOL = 0x167,
        [ "Shadow Tag", "Shadow Tag", "Shadow Tag"],     #   PK360_WYNAUT = 0x168,
        [ "Sturdy", "Moody", "Snow Warning"],     #   PK361_SNORUNT = 0x169,
        [ "Sturdy", "Moody", "Aftermath"],     #   PK362_GLALIE = 0x16A,
        [ "Snow Warning", "Snow Cloak", "Fur Coat"],     # PK363_SPHEAL = 0x16B,
        [ "Snow Warning", "Snow Cloak", "Fur Coat"],     # PK364_SEALEO = 0x16C,
        [ "Snow Warning", "Snow Cloak", "Fur Coat"],     # PK365_WALREIN = 0x16D,
        [ "Drizzle", "Swift Swim", "Swift Swim"],     # PK366_CLAMPERL = 0x16E,
        [ "Drizzle", "Swift Swim", "Swift Swim"],     # PK367_HUNTAIL = 0x16F,
        [ "Drizzle", "Swift Swim", "Swift Swim"],     # PK368_GOREBYSS = 0x17[ "Stench", "Stench", "Stench"],
        [ "Sand Stream", "Drizzle", "Drizzle"],     # PK36[ "Stench", "Stench", "Stench"],RELICANTH = 0x17
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK370_LUVDISC = 0x172,
        [ "Moxie", "Aerilate", "Aerilate"],     # PK371_BAGON = 0x173,
        [ "Moxie", "Aerilate", "Aerilate"],     # PK372_SHELGON = 0x174,
        [ "Moxie", "Aerilate", "Aerilate"],     # PK373_SALAMENCE = 0x175,
        [ "Speed Boost", "Heavy Metal", "Heavy Metal"],     #   PK374_BELDUM = 0x176,
        [ "Speed Boost", "Heavy Metal", "Heavy Metal"],     #   PK375_METANG = 0x177,
        [ "Speed Boost", "Heavy Metal", "Heavy Metal"],     #   PK376_METAGROSS = 0x178,
        [ "Stench", "Stench", "Stench"],     #    PK377_REGIROCK = 0x179,
        [ "Stench", "Stench", "Stench"],     #    PK378_REGICE = 0x17A,
        [ "Stench", "Stench", "Stench"],     #  PK379_REGISTEEL = 0x17B,
        [ "Stench", "Stench", "Stench"],     #  PK380_LATIAS = 0x17C,
        [ "Stench", "Stench", "Stench"],     #   PK381_LATIOS = 0x17D,
        [ "Stench", "Stench", "Stench"],     #    PK382_KYOGRE = 0x17E,
        [ "Stench", "Stench", "Stench"],     #   PK383_GROUDON = 0x17F,
        [ "Stench", "Stench", "Stench"],     #  PK3[ "Stench", "Stench", "Stench"],_RAYQUAZA = 0x18
        [ "Stench", "Stench", "Stench"],     #  PK385_JIRACHI = 0x18[ "Stench", "Stench", "Stench"],
        [ "Stench", "Stench", "Stench"],     #  PK386_DEOXYS = 0x182,

		#
		# SINNOH
		#
        [ "Sturdy", "Thick Fat", "Intimidate"],     # PK387_TURTWIG = 0x183,
        [ "Sturdy", "Thick Fat", "Intimidate"],     # PK388_GROTLE = 0x184,
        [ "Sturdy", "Thick Fat", "Intimidate"],     # PK389_TORTERRA = 0x185,
        [ "Drought", "Anticipation", "Anticipation"],     #  PK390_CHIMCHAR = 0x186,
        [ "Drought", "Anticipation", "Anticipation"],     #  PK391_MONFERNO = 0x187,
        [ "Drought", "Anticipation", "Anticipation"],     #  PK392_INFERNAPE = 0x188,
        [ "Lightning Rod", "Drizzle", "Snow Cloak"],     #  PK393_PIPLUP = 0x189,
        [ "Lightning Rod", "Drizzle", "Snow Cloak"],     #  PK394_PRINPLUP = 0x18A,
        [ "Lightning Rod", "Drizzle", "Snow Cloak"],     #   PK395_EMPOLEON = 0x18B,
        [ "Stench", "Stench", "Stench"],     #   PK396_STARLY = 0x18C,
        [ "Stench", "Stench", "Stench"],     #    PK397_STARAVIA = 0x18D,
        [ "Stench", "Stench", "Stench"],     #    PK398_STARAPTOR = 0x18E,
        [ "Simple", "Simple", "Simple"],     #   PK399_BIDOOF = 0x18F,
        [ "Simple", "Simple", "Simple"],     #  PK[ "Stench", "Stench", "Stench"],0_BIBAREL = 0x19
        [ "Stench", "Stench", "Stench"],     #   PK401_KRICKETOT = 0x19[ "Stench", "Stench", "Stench"],
        [ "Stench", "Stench", "Stench"],     #    PK402_KRICKETUNE = 0x192,
        [ "Stakeout", "Plus", "Minus"],     # PK403_SHINX = 0x193,
        [ "Stakeout", "Plus", "Minus"],     # PK404_LUXIO = 0x194,
        [ "Stakeout", "Plus", "Minus"],     # PK405_LUXRAY = 0x195,
        [ "Stench", "Stench", "Stench"],     # PK406_BUDEW = 0x196,
        [ "Stench", "Stench", "Stench"],     # PK407_ROSERADE = 0x197,
        [ "Sand Stream", "Sturdy", "Sand Rush"],     # PK408_CRANIDOS = 0x198,
        [ "Sand Stream", "Sturdy", "Sand Rush"],     # PK409_RAMPARDOS = 0x199,
        [ "Sand Stream", "Sturdy", "Solid Rock"],     # PK410_SHIELDON = 0x19A,
        [ "Sand Stream", "Sturdy", "Solid Rock"],     # PK411_BASTIODON = 0x19B,
        [ "Anticipation", "Sturdy", "Anticipation"],     #   PK412_BURMY = 0x19C,
        [ "Anticipation", "Sturdy", "Anticipation"],     #   PK413_WORMADAM = 0x19D,
        [ "Anticipation", "Sturdy", "Anticipation"],     #   PK414_MOTHIM = 0x19E,
        [ "Intimidate", "Intimidate", "Intimidate"],     # PK415_COMBEE = 0x19F,
        [ "Intimidate", "Intimidate", "Intimidate"],     # PK416_VESPIQUEN = 0x1A[ "Stench", "Stench", "Stench"],
        [ "Plus", "Minus", "Fur Coat"],     # PK41[ "Stench", "Stench", "Stench"],PACHIRISU = 0x1A
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK418_BUIZEL = 0x1A2,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK419_FLOATZEL = 0x1A3,
        [ "Stench", "Stench", "Stench"],     #   PK420_CHERUBI = 0x1A4,
        [ "Stench", "Stench", "Stench"],     #   PK421_CHERRIM = 0x1A5,
        [ "Drizzle", "Sand Stream", "Sand Stream"],     # PK422_SHELLOS = 0x1A6,
        [ "Drizzle", "Sand Stream", "Sand Stream"],     # PK423_GASTRODON = 0x1A7,
        [ "Stench", "Stench", "Stench"],     # PK424_AMBIPOM = 0x1A8,
        [ "Aftermath", "Wind Rider", "Lightning Rod"],     # PK425_DRIFLOON = 0x1A9,
        [ "Aftermath", "Wind Rider", "Lightning Rod"],     # PK426_DRIFBLIM = 0x1AA,
        [ "Moody", "Fluffy", "Fluffy"],     # PK427_BUNEARY = 0x1AB,
        [ "Moody", "Fluffy", "Fluffy"],     # PK428_LOPUNNY = 0x1AC,
        [ "Illusion", "Shadow Tag", "Shadow Tag"],    #   PK429_MISMAGIUS = 0x1AD,
        [ "Stakeout", "Moxie", "Moxie"],     # PK430_HONCHKROW = 0x1AE,
        [ "Moody", "Anticipation", "Anticipation"],     # PK431_GLAMEOW = 0x1AF,
        [ "Moody", "Anticipation", "Anticipation"],     # PK432_PURUGLY = 0x1B[ "Stench", "Stench", "Stench"],
        [ "Stench", "Stench", "Stench"],     #   PK433_CHINGLING = 0x1B[ "Stench", "Stench", "Stench"],
        [ "Aftermath", "Stench", "Quick Draw"],     #  PK434_STUNKY = 0x1B2,
        [ "Aftermath", "Stench", "Quick Draw"],     #   PK435_SKUNTANK = 0x1B3,
        [ "Drizzle", "Drizzle", "Drizzle"],     #   PK436_BRONZOR = 0x1B4,
        [ "Drizzle", "Drizzle", "Drizzle"],     #   PK437_BRONZONG = 0x1B5,
        [ "Sand Stream", "Stakeout", "Stakeout"],     # PK438_BONSLY = 0x1B6,
        [ "Savant", "Moody", "Illusion"],     # PK439_MIME_JR = 0x1B7,
        [ "Huge Power", "Huge Power", "Huge Power"],     #   PK440_HAPPINY = 0x1B8,
        [ "Moody", "Moody", "Moody"],     # PK441_CHATOT = 0x1B9,
        [ "Illusion", "Shadow Tag", "Prankster"],     #  PK442_SPIRITOMB = 0x1BA,
        [ "Sand Veil", "Sand Stream", "Sand Force"],     #   PK443_GIBLE = 0x1BB,
        [ "Sand Veil", "Sand Stream", "Sand Force"],     #  PK444_GABITE = 0x1BC,
        [ "Sand Veil", "Sand Stream", "Sand Force"],     #   PK445_GARCHOMP = 0x1BD,
        [ "Normalize", "Normalize", "Normalize"],     # PK446_MUNCHLAX = 0x1BE,
        [ "Stench", "Stench", "Stench"],     # PK447_RIOLU = 0x1BF,
        [ "Stench", "Stench", "Stench"],     # PK448_LUCARIO = 0x1C
        [ "Sand Veil", "Sand Stream", "Sand Stream"],     #  PK449_HIPPOPOTAS = 0x1C0],
        [ "Sand Veil", "Sand Stream", "Sand Stream"],     #  PK450_HIPPOWDON = 0x1C2,
        [ "Stench", "Stench", "Stench"],     #   PK451_SKORUPI = 0x1C3,
        [ "Stench", "Stench", "Stench"],     #   PK452_DRAPION = 0x1C4,
        [ "Swift Swim", "Anticipation", "Anticipation"],     #   PK453_CROAGUNK = 0x1C5,
        [ "Swift Swim", "Anticipation", "Anticipation"],     #   PK454_TOXICROAK = 0x1C6,
        [ "Arena Trap", "Stakeout", "Stakeout"],     #   PK455_CARNIVINE = 0x1C7,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK456_FINNEON = 0x1C8,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK457_LUMINEON = 0x1C9,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK458_MANTYKE = 0x1CA,
        [ "Snow Warning", "Slush Rush", "Snow Cloak"],     #   PK459_SNOVER = 0x1CB,
        [ "Snow Warning", "Slush Rush", "Snow Cloak"],     #   PK460_ABOMASNOW = 0x1CC,
        [ "Technician", "Snow Warning", "Snow Cloak"],   # PK461_WEAVILE = 0x1CD,
        [ "Minus", "Plus", "Levitate"],     # PK462_MAGNEZONE = 0x1CE,
        [ "Stench", "Stench", "Stench"],     # PK463_LICKILICKY = 0x1CF,
        [ "Sand Stream", "Berserk", "Berserk"],     # PK464_RHYPERIOR = 0x1D
        [ "Chlorophyll", "Chlorophyll", "Chlorophyll"],     # PK46TANGROWTH = 0x1D
        [ "Minus", "Anger Point", "Plus"],     # PK466_ELECTIVIRE = 0x1D2,
        [ "Quick Draw", "Drought", "Aftermath"],     #  PK467_MAGMORTAR = 0x1D3,
        [ "Healer", "Healer", "Healer"],     # PK468_TOGEKISS = 0x1D4,
        [ "Stench", "Stench", "Stench"],     # PK469_YANMEGA = 0x1D5,
        [ "Anticipation", "Drought", "Flower Gift"],     #  PK470_LEAFEON = 0x1D6,
        [ "Anticipation", "Snow Warning", "Snow Cloak"],     #   PK471_GLACEON = 0x1D7,
        [ "Sand Stream", "Sand Veil", "Sand Veil"],     # PK472_GLISCOR = 0x1D8,
        [ "Snow Warning", "Snow Cloak", "Anger Point"],    #  PK473_MAMOSWINE = 0x1D9,
        [ "Levitate", "Levitate", "Levitate"],     #  PK474_PORYGON_Z = 0x1DA,
        [ "Illusion", "Friend Guard", "Quick Draw"],     #   PK475_GALLADE = 0x1DB,
        [ "Sand Stream", "Sand Stream", "Sand Stream"],     #   PK476_PROBOPASS = 0x1DC,
        [ "Shadow Tag", "Anticipation", "Illusion"],     #   PK477_DUSKNOIR = 0x1DD,
        [ "Snow Cloak", "Snow Warning", "Illusion"],     #    PK478_FROSLASS = 0x1DE,
        [ "Illusion", "Plus", "Shadow Tag"],     #    PK479_ROTOM = 0x1DF,
        [ "Stench", "Stench", "Stench"],     # PK480_UXIE = 0x1E
        [ "Stench", "Stench", "Stench"],     # PK481_MESPRIT = 0x1E
        [ "Stench", "Stench", "Stench"],     # PK482_AZELF = 0x1E2,
        [ "Stench", "Stench", "Stench"],     #   PK483_DIALGA = 0x1E3,
        [ "Stench", "Stench", "Stench"],     #   PK484_PALKIA = 0x1E4,
        [ "Stench", "Stench", "Stench"],     #   PK485_HEATRAN = 0x1E5,
        [ "Stench", "Stench", "Stench"],     #    PK486_REGIGIGAS = 0x1E6,
        [ "Stench", "Stench", "Stench"],     #    PK487_GIRATINA = 0x1E7,
        [ "Stench", "Stench", "Stench"],     #   PK488_CRESSELIA = 0x1E8,
        [ "Stench", "Stench", "Stench"],     #    PK489_PHIONE = 0x1E9,
        [ "Stench", "Stench", "Stench"],     #    PK490_MANAPHY = 0x1EA,
        [ "Stench", "Stench", "Stench"],     #   PK491_DARKRAI = 0x1EB,
        [ "Stench", "Stench", "Stench"],     # PK492_SHAYMIN = 0x1EC,
        [ "Stench", "Stench", "Stench"],     #  PK493_ARCEUS = 0x1ED,

		#
		# UNOVA
		#
        [ "Contrary", "Contrary", "Contrary"],     # PK494_VICTINI = 0x1EE,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK495_SNIVY = 0x1EF,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK496_SERVINE = 0x1F
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK497_SERPERIOR = 0x1F
        [ "Drought", "Drought", "Drought"],     # PK498_TEPIG = 0x1F2,
        [ "Drought", "Drought", "Drought"],     # PK499_PIGNITE = 0x1F3,
        [ "Drought", "Drought", "Drought"],     # PK500_EMBOAR = 0x1F4,
        [ "Drizzle", "Quick Draw", "Defiant"],     # PK501_OSHAWOTT = 0x1F5,
        [ "Drizzle", "Quick Draw", "Defiant"],     # PK502_DEWOTT = 0x1F6,
        [ "Drizzle", "Quick Draw", "Defiant"],     # PK503_SAMUROTT = 0x1F7,
        [ "Anticipation", "Stakeout", "Stakeout"],     # PK504_PATRAT = 0x1F8,
        [ "Anticipation", "Stakeout", "Stakeout"],     # PK505_WATCHOG = 0x1F9,
        [ "Slush Rush", "Scrappy", "Sand Rush"],     # PK506_LILLIPUP = 0x1FA,
        [ "Slush Rush", "Scrappy", "Sand Rush"],     # PK507_HERDIER = 0x1FB,
        [ "Slush Rush", "Scrappy", "Sand Rush"],     # PK508_STOUTLAND = 0x1FC,
        [ "Moody", "Prankster", "Sniper"],     # PK509_PURRLOIN = 0x1FD,
        [ "Moody", "Prankster", "Sniper"],     # PK510_LIEPARD = 0x1FE,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK511_PANSAGE = 0x1FF,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK512_SIMISAGE = 0x20
        [ "Drought", "Drought", "Drought"],     # PK513_PANSEAR = 0x20
        [ "Drought", "Drought", "Drought"],     # PK514_SIMISEAR = 0x202,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK515_PANPOUR = 0x203,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK516_SIMIPOUR = 0x204,
        [ "Trace", "Bad Dreams", "Illusion"],     # PK517_MUNNA = 0x205,
        [ "Trace", "Bad Dreams", "Illusion"],     # PK518_MUSHARNA = 0x206,
        [ "Sniper", "Sniper", "Sniper"],     # PK519_PIDOVE = 0x207,
        [ "Sniper", "Sniper", "Sniper"],     # PK520_TRANQUILL = 0x208,
        [ "Sniper", "Sniper", "Sniper"],     # PK521_UNFEZANT = 0x209,
        [ "Plus", "Minus", "Minus"], # PK522_BLITZLE = 0x20A,
        [ "Plus", "Minus", "Minus"], # PK523_ZEBSTRIKA = 0x20B,
        [ "Sand Stream", "Drought", "Aftermath"],     # PK524_ROGGENROLA = 0x20C,
        [ "Sand Stream", "Drought", "Aftermath"],     # PK525_BOLDORE = 0x20D,
        [ "Sand Stream", "Drought", "Aftermath"],     # PK526_GIGALITH = 0x20E,
        [ "Moody", "Simple", "Simple"],     # PK527_WOOBAT = 0x20F,
        [ "Moody", "Simple", "Simple"],     # PK528_SWOOBAT = 0x21[ "Stench", "Stench", "Stench"],
        [ "Sand Veil", "Sand Stream", "Sand Rush"],     # PK[ "Stench", "Stench", "Stench"],9_DRILBUR = 0x21
        [ "Sand Veil", "Sand Stream", "Sand Rush"],     # PK530_EXCADRILL = 0x212,
        [ "Stench", "Stench", "Stench"],     # PK531_AUDINO = 0x213,
        [ "Stench", "Stench", "Stench"],     # PK532_TIMBURR = 0x214,
        [ "Stench", "Stench", "Stench"],     # PK533_GURDURR = 0x215,
        [ "Stench", "Stench", "Stench"],     # PK534_CONKELDURR = 0x216,
        [ "Anticipation", "Poison Touch", "Poison Touch"],     # PK535_TYMPOLE = 0x217,
        [ "Anticipation", "Poison Touch", "Poison Touch"],     # PK536_PALPITOAD = 0x218,
        [ "Anticipation", "Poison Touch", "Poison Touch"],     # PK537_SEISMITOAD = 0x219,
        [ "Anticipation", "Strong Body", "Strong Body"],    # PK538_THROH = 0x21A,
        [ "Anticipation", "Strong Body", "Strong Body"],     # PK539_SAWK = 0x21B,
        [ "Anticipation", "Chlorophyll", "Arena Trap"],     # PK540_SEWADDLE = 0x21C,
        [ "Anticipation", "Chlorophyll", "Arena Trap"],     # PK541_SWADLOON = 0x21D,
        [ "Anticipation", "Chlorophyll", "Arena Trap"],     # PK542_LEAVANNY = 0x21E,
        [ "Stench", "Stench", "Stench"],     # PK543_VENIPEDE = 0x21F,
        [ "Stench", "Stench", "Stench"],     # PK544_WHIRLIPEDE = 0x22[ "Stench", "Stench", "Stench"],
        [ "Stench", "Stench", "Stench"],     # PK54[ "Stench", "Stench", "Stench"],SCOLIPEDE = 0x22
        [ "Stench", "Stench", "Stench"],     # PK546_COTTONEE = 0x222,
        [ "Stench", "Stench", "Stench"],     # PK547_WHIMSICOTT = 0x223,
        [ "Stench", "Stench", "Stench"],     #  PK548_PETILIL = 0x224,
        [ "Stench", "Stench", "Stench"],     # PK549_LILLIGANT = 0x225,
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK550_BASCULIN = 0x226,
        [ "Stakeout", "Sand Stream", "Anger Point"],     # PK551_SANDILE = 0x227,
        [ "Stakeout", "Sand Stream", "Anger Point"],     # PK552_KROKOROK = 0x228,
        [ "Stakeout", "Sand Stream", "Anger Point"],     # PK553_KROOKODILE = 0x229,
        [ "Drought", "Run Away", "Run Away"],     # PK554_DARUMAKA = 0x22A,
        [ "Drought", "Zen Mode", "Zen Mode"],     # PK555_DARMANITAN = 0x22B,
        [ "Sand Veil", "Chlorophyll", "Sand Stream"],     # PK556_MARACTUS = 0x22C,
        [ "Sand Stream", "Weak Armor", "Sturdy"],     # PK557_DWEBBLE = 0x22D,
        [ "Sand Stream", "Weak Armor", "Sturdy"],     # PK558_CRUSTLE = 0x22E,
        [ "Quick Draw", "Moxie", "Moxie"],     # PK559_SCRAGGY = 0x22F,
        [ "Quick Draw", "Moxie", "Moxie"],     # PK560_SCRAFTY = 0x23[ "Stench", "Stench", "Stench"],
        [ "Illusion", "Sand Veil", "Sand Veil"],     # PK5[ "Stench", "Stench", "Stench"],_SIGILYPH = 0x23
        [ "Sand Stream", "Illusion", "Shadow Tag"],     # PK562_YAMASK = 0x232,
        [ "Sand Stream", "Illusion", "Shadow Tag"],     # PK563_COFAGRIGUS = 0x233,
        [ "Sand Stream", "Drizzle", "Sturdy"],     # PK564_TIRTOUGA = 0x234,
        [ "Sand Stream", "Drizzle", "Sturdy"],     # PK565_CARRACOSTA = 0x235,
        [ "Intimidate", "Berserk", "Hustle"],     # PK566_ARCHEN = 0x236,
        [ "Intimidate", "Berserk", "Hustle"],     # PK567_ARCHEOPS = 0x237,
        [ "Stench", "Aftermath", "Aftermath"],     # PK568_TRUBBISH = 0x238,
        [ "Stench", "Aftermath", "Aftermath"],     # PK569_GARBODOR = 0x239,
        [ "Stakeout", "Illusion", "Illusion"],     # PK570_ZORUA = 0x23A,
        [ "Stakeout", "Illusion", "Illusion"],     # PK571_ZOROARK = 0x23B,
        [ "Prankster", "Prankster", "Prankster"],     # PK572_MINCCINO = 0x23C,
        [ "Prankster", "Prankster", "Prankster"],     # PK573_CINCCINO = 0x23D,
        [ "Shadow Tag", "Illusion", "Anticipation"],     # PK574_GOTHITA = 0x23E,
        [ "Shadow Tag", "Illusion", "Anticipation"],     # PK575_GOTHORITA = 0x23F,
        [ "Shadow Tag", "Illusion", "Anticipation"],     # PK576[ "Stench", "Stench", "Stench"],OTHITELLE = 0x24
        [ "Stench", "Stench", "Stench"],     # PK[ "Stench", "Stench", "Stench"],7_SOLOSIS = 0x24
        [ "Stench", "Stench", "Stench"],     # PK578_DUOSION = 0x242,
        [ "Stench", "Stench", "Stench"],     # PK579_REUNICLUS = 0x243,
        [ "Drizzle", "Snow Cloak", "Snow Cloak"],     #  PK580_DUCKLETT = 0x244,
        [ "Snow Warning", "Snow Cloak", "Snow Cloak"],     #  PK581_SWANNA = 0x245,
        [ "Snow Warning", "Snow Cloak", "Aftermath"],     #  PK582_VANILLITE = 0x246,
        [ "Snow Warning", "Snow Cloak", "Aftermath"],     #  PK583_VANILLISH = 0x247,
        [ "Snow Warning", "Snow Cloak", "Aftermath"],     #  PK584_VANILLUXE = 0x248,
        [ "Stench", "Stench", "Stench"],     #  PK585_DEERLING = 0x249,
        [ "Stench", "Stench", "Stench"],     #   PK586_SAWSBUCK = 0x24A,
        [ "Plus", "Minus", "Minus"],     # PK587_EMOLGA = 0x24B,
        [ "Anticipation", "Anticipation", "Anticipation"],     #  PK588_KARRABLAST = 0x24C,
        [ "Anticipation", "Anticipation", "Anticipation"],     #  PK589_ESCAVALIER = 0x24D,
        [ "Stakeout", "Effect Spore", "Effect Spore"],     # PK590_FOONGUS = 0x24E,
        [ "Stakeout", "Effect Spore", "Effect Spore"],     # PK591_AMOONGUSS = 0x24F,
        [ "Drizzle", "Shadow Tag", "Shadow Tag"],     #  PK5[ "Stench", "Stench", "Stench"],_FRILLISH = 0x25
        [ "Drizzle", "Shadow Tag", "Shadow Tag"],     #   PK593_JELLICENT = 0x25[ "Stench", "Stench", "Stench"],
        [ "Drizzle", "Drizzle", "Drizzle"],     # PK594_ALOMOMOLA = 0x252,
        [ "Arena Trap", "Stakeout", "Plus"],     # PK595_JOLTIK = 0x253,
        [ "Arena Trap", "Stakeout", "Plus"],     # PK596_GALVANTULA = 0x254,
        [ "Aftermath", "Anticipation", "Anticipation"],     # PK597_FERROSEED = 0x255,
        [ "Aftermath", "Anticipation", "Anticipation"],     # PK598_FERROTHORN = 0x256,
        [ "Levitate", "Plus", "Minus"],     # PK599_KLINK = 0x257,
        [ "Levitate", "Plus", "Minus"],     # PK600_KLANG = 0x258,
        [ "Levitate", "Plus", "Minus"],     # PK601_KLINKLANG = 0x259,
        [ "Stakeout", "Plus", "Minus"],     # PK602_TYNAMO = 0x25A,
        [ "Stakeout", "Plus", "Minus"],     # PK603_EELEKTRIK = 0x25B,
        [ "Stakeout", "Plus", "Minus"],     # PK604_EELEKTROSS = 0x25C,
        [ "Illusion", "Trace", "Minus"],     # PK605_ELGYEM = 0x25D,
        [ "Illusion", "Trace", "Minus"],     # PK606_BEHEEYEM = 0x25E,
        [ "Illusion", "Shadow Tag", "Drought"],     #  PK607_LITWICK = 0x25F,
        [ "Illusion", "Shadow Tag", "Drought"],     #  PK[ "Stench", "Stench", "Stench"],8_LAMPENT = 0x26
        [ "Illusion", "Shadow Tag", "Drought"],     #  PK609_CHANDELURE = 0x26[ "Stench", "Stench", "Stench"],
        [ "Tenacity", "Sturdy", "Anger Point"],     # PK610_AXEW = 0x262,
        [ "Tenacity", "Sturdy", "Anger Point"],     #  PK611_FRAXURE = 0x263,
        [ "Tenacity", "Sturdy", "Anger Point"],     #  PK612_HAXORUS = 0x264,
        [ "Slush Rush", "Snow Warning", "Snow Cloak"],     # PK613_CUBCHOO = 0x265,
        [ "Slush Rush", "Snow Warning", "Snow Cloak"],     # PK614_BEARTIC = 0x266,
        [ "Aftermath", "Snow Warning", "Snow Cloak"],     # PK615_CRYOGONAL = 0x267,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK616_SHELMET = 0x268,
        [ "Anticipation", "Anticipation", "Anticipation"],     #   PK617_ACCELGOR = 0x269,
        [ "Sand Veil", "Sand Stream", "Sand Stream"],     # PK618_STUNFISK = 0x26A,
        [ "Anticipation", "Strong Body", "Strong Body"],     # PK619_MIENFOO = 0x26B,
        [ "Anticipation", "Strong Body", "Strong Body"],     # PK620_MIENSHAO = 0x26C,
        [ "Strong Body", "Solid Rock", "Solid Rock"],     # PK621_DRUDDIGON = 0x26D,
        [ "Sand Stream", "Iron Fist", "Aftermath"],     # PK622_GOLETT = 0x26E,
        [ "Sand Stream", "Iron Fist", "Aftermath"],     # PK623_GOLURK = 0x26F,
        [ "Speed Boost", "Stakeout", "Stakeout"],     #  PK6[ "Stench", "Stench", "Stench"],_PAWNIARD = 0x27
        [ "Speed Boost", "Stakeout", "Stakeout"],     # PK625_BISHARP = 0x27[ "Stench", "Stench", "Stench"],
        [ "Stench", "Stench", "Stench"],     # PK626_BOUFFALANT = 0x272,
        [ "Stench", "Stench", "Stench"],     # PK627_RUFFLET = 0x273,
        [ "Stench", "Stench", "Stench"],     # PK628_BRAVIARY = 0x274,
        [ "Stakeout", "Stakeout", "Stakeout"],     # PK629_VULLABY = 0x275,
        [ "Stakeout", "Stakeout", "Stakeout"],     # PK630_MANDIBUZZ = 0x276,
        [ "Arena Trap", "Drought", "Stakeout"],     #  PK631_HEATMOR = 0x277,
        [ "Stakeout", "Arena Trap", "Heatproof"],     # PK632_DURANT = 0x278,
        [ "Moody", "Moody", "Moody"],     # PK633_DEINO = 0x279,
        [ "Moody", "Moody", "Moody"],     # PK634_ZWEILOUS = 0x27A,
        [ "Moody", "Moody", "Moody"],     # PK635_HYDREIGON = 0x27B,
        [ "Drought", "Drought", "Drought"],     #  PK636_LARVESTA = 0x27C,
        [ "Drought", "Drought", "Drought"],     #  PK637_VOLCARONA = 0x27D,
        [ "Anticipation", "Anticipation", "Anticipation"],     #  PK638_COBALION = 0x27E,
        [ "Anticipation", "Anticipation", "Anticipation"],     #  PK639_TERRAKION = 0x27F,
        [ "Anticipation", "Anticipation", "Anticipation"],     #   PK6[ "Stench", "Stench", "Stench"],_VIRIZION = 0x28
        [ "Stench", "Stench", "Stench"],     #   PK641_TORNADUS = 0x28
        [ "Stench", "Stench", "Stench"],     #   PK642_THUNDURUS = 0x282,
        [ "Stench", "Stench", "Stench"],     # PK643_RESHIRAM = 0x283,
        [ "Stench", "Stench", "Stench"],     #   PK644_ZEKROM = 0x284,
        [ "Stench", "Stench", "Stench"],     # PK645_LANDORUS = 0x285,
        [ "Stench", "Stench", "Stench"],     # PK646_KYUREM = 0x286,
        [ "Anticipation", "Anticipation", "Anticipation"],     # PK647_KELDEO = 0x287,
        [ "Stench", "Stench", "Stench"],     # PK648_MELOETTA = 0x288,
        [ "Stench", "Stench", "Stench"],     # PK649_GENESECT = 0x289,
        [ "Stench", "Stench", "Stench"],     # MONSNO_MAX = 0x28A,
    ]


	def self.aiAbilities 
		@aiAbilities
	end
end


# "Abomasnow":{"UU Barack Aboma (Swords Dance)":{"level":100,"ability":"Soundproof","item":"Abomasite","nature":"Adamant","evs":{"hp":76,"at":252,"sp":180},"moves":["Swords Dance","Wood Hammer","Ice Shard","Earthquake"]}




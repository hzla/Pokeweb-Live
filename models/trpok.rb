class Trpok < Pokenarc
	def self.get_all
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
		p data
		super
	end

	def self.get_poks_for count, trainer_poks
		poks = []
		(0..100).each do |n|
			if trainer_poks["species_id_#{n}"]
				poks << trainer_poks["species_id_#{n}"].gsub(". ", "-").downcase
			end
		end
		poks
	end

	def self.fill_lvl_up_moves lvl, trainer, pok_index, apply=true

		file_path = "#{$rom_name}/json/trpok/#{trainer}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})

		pok_id = trpok["raw"]["species_id_#{pok_index}"] % 1024


		learnset_path = "#{$rom_name}/json/learnsets/#{pok_id}.json"
		learnset = JSON.parse(File.open(learnset_path, "r"){|f| f.read})

		moves = []

		(0..19).to_a.reverse.each do |n|
			lvl_learned = learnset["readable"]["lvl_learned_#{n}"]
			p lvl_learned
			p learnset["readable"]["move_id_#{n}"]
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

		if apply
			File.open(file_path, "w") { |f| f.write trpok.to_json}
		end
		
		moves.map {|m| m[1].name_titleize}

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

		convert_pid_to_nature(pid, natures)
		
	end

	def self.get_abilities_for tr_id

		file_path = "#{$rom_name}/json/trpok/#{tr_id}.json"
		raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
		poks = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]


		poks_array = []

		(0..(poks["count"] - 1)).each do |i|			
			pok_id = raw["species_id_#{i}"]
			file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
			personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		
			ability_id = poks["ability_#{i}"]
			ability_id += 1 if ability_id < 1
			ability = personal["ability_#{ability_id}"]
			poks_array << ability
		end

		poks_array
	end

	def self.g4_get_nature_for(file_name, sub_index, desired_iv=255)
		# p file_name
		# if file_name.to_i > 1024
		# 	file_name = file_name % 1024
		# end

		# $rom_name = "projects/renplat"

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
		ability = ability_slot
		species = pok_id


		gender_file = ""
		if SessionSettings.base_rom == "HGSS"
			gender_file = "texts/hgss_genders.txt"
		else
			gender_file = "texts/plat_genders.txt"
		end

		gender_table = File.read(gender_file).split("\n")
		gender = gender_table[trainer_class] == "01" ? "female" : "male"

		# if personal["gender"] < 127
		# 	gender = "male"
		# end

		# if personal["gender"] > 127
		# 	gender = "female"
		# end

		# if personal["gender"] >= 254
		# 	gender = "female"
		# end

		p gender_file

		# prng(77, )

		p [level, species, difficulty, trainer_id, trainer_class, gender, ability]
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
			mid_bytes = "0000"
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


	def self.convert_pid_to_nature pid, natures
		nature = natures[(pid >> 8) % 25]
	end

	def self.get_pid(trainer_id, trainer_class, pok_id, pok_iv, pok_lvl, ability_gender, personal_gender, trainer_gender, ability_slot)

		seed = trainer_id + pok_id + pok_iv + pok_lvl

		trainer_class.times do 
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


	def self.export_all_showdown use_format=true, gen=5
		data = []
		sets = {}
		@@tr_name_counts = {}
		tr_count = Dir.entries("#{$rom_name}/json/trpok/").length
		rival_count = -1

		settings = SessionSettings.calc_settings

		(0..tr_count).each do |n|
			ai = nil
			begin
				file_path = "#{$rom_name}/json/trdata/#{n}.json"
				full_trdata = JSON.parse(File.open(file_path, "r"){|f| f.read})
				trdata = full_trdata["readable"]
				ai = full_trdata["raw"]["ais"] || full_trdata["raw"]["ai"]

				if trdata["name"].downcase.include?("rival") 
					rival_count += 1
				end
			rescue
				break
				binding.pry
			end
			
			# 
			battle_field = gen == 5 ? '_1' : '' 


			if (settings["ai_values"] == "all" or settings["ai_values"].include?(ai)) && settings["has_moves"].include?(trdata["has_moves"]) && settings["has_items"].include?(trdata["has_items"]) && settings["battle_types"].include?(trdata["battle_type#{battle_field}"])
				data << export_showdown(n, trdata, settings["min_ivs"], rival_count, gen)
			end

		end
		
		return data if !use_format

		sets["data"] = data.flatten
		File.write("public/dist/sets.json", JSON.dump(sets))
		# File.write("public/dist/formatted_sets.json", JSON.dump(sets))

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

	def self.rp_replacements
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

	def self.export_showdown tr_id, trdata, min_ivs, rival_set=0, gen=5
		if $gen = 4
			move_names = File.read("texts/rp_moves.txt").split("\n")
		end
		file_path = "#{$rom_name}/json/trpok/#{tr_id}.json"
		raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
		poks = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]

		trnames = File.read("#{$rom_name}/texts/tr_names.txt").split("\n")
		trclasses = File.read("#{$rom_name}/texts/tr_classes.txt").split("\n")

		trdata["class"] = trclasses[trdata["class_id"]]
		trdata["name"] = trnames[tr_id]

		# if trdata["name"] == "Zackary"
		# 	p trdata["class"]
		# end


		trdata["class"] = "" if !trdata["class"]

		trname_info = "#{trdata["class"]} #{trdata["name"]}"

		if @@tr_name_counts[trname_info]
			@@tr_name_counts[trname_info] += 1
		else
			@@tr_name_counts[trname_info] = 1
		end

		poks_array = []
	
		

		(0..(poks["count"] - 1)).each do |i|
			next if poks["ivs_#{i}"] < min_ivs
			species = poks["species_id_#{i}"].downcase.titleize

			trname_count = @@tr_name_counts[trname_info]

			show_count = (trname_count > 1 || trdata["name"] == "Grunt" || trdata["name"] == "Shadow" )
			
			level = poks["level_#{i}"]
			tr_name = "Lvl #{level} #{trdata["class"].gsub("⒆⒇", "PKMN").gsub("[PK][MN]", "Pkmn")} #{trdata["name"]}#{trname_count if show_count } "
			tr_name += " - #{trdata["location"]}" if trdata["location"]


			

			if tr_name.downcase.include?('rival')
				# binding.pry
				tr_name += " - Starter #{(rival_set % 3) + 1}"
				
			end
			
			pok_id = raw["species_id_#{i}"]

			if pok_id >= 1024
				form = pok_id / 1024
				pok_id = pok_id % 1024

				if form > 0 && !(["Deerling","Sawsbuck","Gastrodon","Shellos","Arceus"].include?(species))
					species_name = species
					begin
						species += "-#{RomInfo.form_info[species_name][form - 1]}"
					rescue
					
					end
				end
				p species
			end

			file_path = "#{$rom_name}/json/personal/#{pok_id}.json"
			personal = JSON.parse(File.open(file_path, "r"){|f| f.read})["readable"]
			
			if gen == 5

				form = poks["form_#{i}"]

				if form > 0 && !(["Deerling","Sawsbuck","Gastrodon","Shellos","Arceus"].include?(species))
					species_name = species
					begin
						species += "-#{RomInfo.form_info[species_name][form - 1]}"
					rescue
					
					end
				end
			end

			ability_id = poks["ability_#{i}"]

			if gen == 5
				ability_id += 1 if ability_id < 1
			else
				ability_id = poks["ability_#{i}"] == 0 ? 1 : 2
			end
			
			ability = personal["ability_#{ability_id}"]

			item = poks["item_id_#{i}"]

			if gen == 5
				nature = get_nature_for(tr_id, i, poks["ivs_#{i}"])
			else
				nature = g4_get_nature_for(tr_id, i, poks["ivs_#{i}"])
			end

			iv = poks["ivs_#{i}"] * 31 / 255

			moves = []
			(1..4).each do |n|
				if poks["move_#{n}_#{i}"]
					move = sub_showdown(poks["move_#{n}_#{i}"].move_titleize)
					if rp_replacements[move]
						move = rp_replacements[move]
					end
					moves << move 
				else
					moves << ""
				end
			end

			pok = {}

			pok[species] = {}

			pok[species][tr_name] =  {}

			pok[species][tr_name]["level"] = level
			pok[species][tr_name]["tr_id"] = tr_id
			pok[species][tr_name]["ai"] = trdata["ai"]		

			if gen == 5
				pok[species][tr_name]["battle_type"] = trdata["battle_type_1"]
				pok[species][tr_name]["reward_item"] = trdata["reward_item"]
				pok[species][tr_name]["form"] = form
			else
				pok[species][tr_name]["battle_type"] = trdata["battle_type"]
				pok[species][tr_name]["reward_item"] = ""
				pok[species][tr_name]["form"] = form || ""
			end
			
			pok[species][tr_name]["item"] = item.titleize
			pok[species][tr_name]["ivs"] = {"hp": iv,"at": iv,"df": iv,"sa": iv,"sd": iv,"sp": iv}
			pok[species][tr_name]["nature"] = nature
			pok[species][tr_name]["moves"] = moves
			pok[species][tr_name]["sub_index"] = i
			pok[species][tr_name]["ability"] = ability.titleize.gsub("Lightningrod", "Lightning Rod").gsub("Compoundeyes", "Compound Eyes")





			
			pok[species][tr_name]["evs"] = {"df" => 0}

			poks_array << pok





		end
		poks_array


		
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
		    "Hi Jump Kick": "High Jump Kick"
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
end


# "Abomasnow":{"UU Barack Aboma (Swords Dance)":{"level":100,"ability":"Soundproof","item":"Abomasite","nature":"Adamant","evs":{"hp":76,"at":252,"sp":180},"moves":["Swords Dance","Wood Hammer","Ice Shard","Earthquake"]}




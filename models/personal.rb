class Personal

	def self.poke_data
		files = Dir["#{$rom_name}/json/personal/*.json"]
		file_count = files.length

		data = []

		(0..file_count - 1).each do |n|
			file_path = "#{$rom_name}/json/personal/#{n}.json"
			data << get_data_for(file_path)
		end
		data
	end

	def self.export_showdown
		poks = poke_data[1..-1]

		showdown = {}

		poks[28]["name"] = "Nidoran-F"
		poks[31]["name"] = "Nidoran-M"
		poks[82]["name"] = "Farfetch’d"
		poks[684]["name"] = "Deoxys-Attack"
		poks[685]["name"] = "Deoxys-Defense"
		poks[686]["name"] = "Deoxys-Speed"
		poks[689]["name"] = "Shaymin-Sky"	
		poks[690]["name"] = "Giratina-Origin"
		poks[691]["name"] = "Rotom-Heat"
		poks[692]["name"] = "Rotom-Wash"
		poks[693]["name"] = "Rotom-Frost"
		poks[694]["name"] = "Rotom-Fan"
		poks[695]["name"] = "Rotom-Mow"
		poks[696]["name"] = "Castform-Sunny"
		poks[697]["name"] = "Castform-Rainy"
		poks[698]["name"] = "Castform-Snowy"
		poks[699]["name"] = "Basculin-Blue-Striped"
		poks[700]["name"] = "Darmanitan-Zen"
		poks[701]["name"] = "Meloetta-Pirouette"
		poks[702]["name"] = "Kyurem-White"
		poks[703]["name"] = "Kyurem-Black"
		poks[704]["name"] = "Keldeo-Resolute"
		poks[705]["name"] = "Tornadus-Therian"
		poks[706]["name"] = "Thundurus-Therian"
		poks[707]["name"] = "Landorus-Therian"


		poks.each do |pok|
			next if !pok
			showdown_name = pok["name"].name_titleize
			showdown[showdown_name] = {}
			if pok["type_1"] == pok["type_2"]
				showdown[showdown_name]["types"] = [pok["type_1"]]
			else
				showdown[showdown_name]["types"] = [pok["type_1"], pok["type_2"]]
			end

			showdown[showdown_name]["bs"] = {"hp"=> pok["base_hp"], "at" => pok["base_atk"], "df" => pok["base_def"], "sa" => pok["base_spatk"], "sd" => pok["base_spdef"], "sp" => pok["base_speed"]}
		end
		File.write("public/dist/poks.json", JSON.dump(showdown))
	end

	def self.unavailable_sprite_indexes
		personals = poke_data
		taken_slots = []

		(0..27).each do |n|
			taken_slots << [n, "Unown"]
		end

		poke_data.each do |pok|
			if pok && pok["form"] != 0
				slot = pok["form"]
				num_forms = pok["num_forms"]
				
				(0..num_forms - 2).each do |form|
					taken_slots << [(slot + form), pok["name"]]
				end
			end
		end
		taken_slots.sort_by {|p| p[0]}
	end

	def self.get_data_for(file_name)
		pok_id = file_name.split('/')[-1].split('.')[0]

		personal_data = JSON.parse(File.open(file_name, "r"){|f| f.read})["readable"]
		
		return if !personal_data
		learnset_data_path = "#{$rom_name}/json/learnsets/#{pok_id}.json"
		learnset_data = JSON.parse(File.open(learnset_data_path, "r"){|f| f.read})["readable"]

		personal_data["learnset"] = learnset_data
		personal_data		
	end

	def self.write_batch_data data
		data["file_names"].each do |file|
			data["file_name"] = file
			write_data(data)
		end
	end

	def self.write_data(data, batch=false)
		if batch
			write_batch_data data
		end
		@@upcases = []

		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		file_path = "#{$rom_name}/json/personal/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r"){|f| f.read})
		# binding.pry
		if data["int"]
			changed_value = changed_value.to_i
		elsif data["field"].split("_")[0] == "ability"
			changed_value = changed_value.upcase
		else
			changed_value = changed_value.titleize if changed_value.is_a? String
		end

		if field_to_change == "tutors"
			tutor_list = data["value"].reverse.join("").to_i(2)
			json_data["readable"]["tutors"] = tutor_list
			File.open(file_path, "w") { |f| f.write json_data.to_json }
			return
		end

		if field_to_change == "tms"
			tm_list = data["value"]
			tm_1 = tm_list[0..31].reverse.join("").to_i(2) 
			tm_2 = tm_list[32..63].reverse.join("").to_i(2) 
			tm_3 = tm_list[64..95].reverse.join("").to_i(2) 
			tm_4 = tm_list[96..110].reverse.join("").to_i(2)

			json_data["readable"]["tm_1-32"] = tm_1
			json_data["readable"]["tm_33-64"] = tm_2
			json_data["readable"]["tm_65-95+hm_1"] = tm_3
			json_data["readable"]["hm_2-6"] = tm_4
			File.open(file_path, "w") { |f| f.write json_data.to_json }
			return
		end

		json_data["readable"][field_to_change] = changed_value

		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end

	def self.base_stat_fields
		# title to display, field_name in json
		[["HP", "base_hp"],["Attack", "base_atk"],["Defense", "base_def"],["Special Attack", "base_spatk"],["Special Defense", "base_spdef"],["Speed", "base_speed"]]
	end

	def self.misc_integer_fields
		# title to display, field_name in json
		[["Catch Rate", "catchrate"],["Exp Yield", "base_exp"],["Gender", "gender"],["Hatch Rate", "hatch_cycle"],["Happiness", "base_happy"], ["# of Forms", "num_forms"], ["Form Personal ID", "form_id", "int-65535"], ["Form Sprite Offset", "form", "int-65535", "iv-label"], ["Form Sprite IDs", "form_sprites", "array" ]]
	end

	def self.text_fields
		# title to display, field_name in json, autofill_bank
		[['50% Held Item', 'item_1', 'items' ],['5% Held Item', 'item_2', 'items' ],['1% Held Item', 'item_3', 'items' ],['Egg Group 1', 'egg_group_1', 'egg_groups' ],['Egg Group 2', 'egg_group_2', 'egg_groups' ],['Growth Rate', 'exp_rate', 'growth_rates' ]]	
	end

	def self.ev_yield_fields
		# title to display, field_name in json
		[["HP", "hp_yield"],["Attack", "atk_yield"],["Defense", "def_yield"],["Sp Attack", "spatk_yield"],["Sp Defense", "spdef_yield"],["Speed", "speed_yield"]]
	end

	def self.get_tm_list(personal_data)
		tms_1 = personal_data["tm_1-32"].to_s(2).rjust(32, '0').reverse
		tms_2 = personal_data["tm_33-64"].to_s(2).rjust(32, '0').reverse
		tms_3 = personal_data["tm_65-95+hm_1"].to_s(2).rjust(32, '0').reverse[0..-2] #65-95
		hms_1 = personal_data["tm_65-95+hm_1"].to_s(2).rjust(32, '0').reverse[-1]
		hms_2 = personal_data["hm_2-6"].to_s(2).rjust(5, '0').reverse


		tms = tms_1 + tms_2 + tms_3
		hms = hms_1 + hms_2
		{tms: tms.split(""), hms: hms.split("")}
	end

	def self.get_tutor_list(personal_data)
		personal_data["tutors"].to_s(2).rjust(7, '0').reverse.split("")
	end

	def self.tutor_moves
		["Grass Pledge", "Fire Pledge", "Water Pledge", "Frenzy Plant", "Blast Burn", "Hydro Cannon", "Draco Meteor" ]
	end
end
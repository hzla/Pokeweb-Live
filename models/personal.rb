class Personal

	def self.poke_data
		files = Dir["#{$rom_name}/json/personal/*.json"]
		file_count = files.length

		data = []

		(0..file_count - 1).each do |n|
			file_path = "#{$rom_name}/json/personal/#{n}.json"
			data << get_data_for(file_path)
		end

		data[29]["name"] = "Nidoran-F"
		data[32]["name"] = "Nidoran-M"
		data[83]["name"] = "Farfetch’d"

		if SessionSettings.base_rom == "BW2"
			data[685]["name"] = "Deoxys-Attack"
			data[686]["name"] = "Deoxys-Defense"
			data[687]["name"] = "Deoxys-Speed"
			data[688]["name"] = "Wormadan-Sandy"
			data[689]["name"] = "Womadan-Trash"
			data[690]["name"] = "Shaymin-Sky"	
			data[691]["name"] = "Giratina-Origin"
			data[692]["name"] = "Rotom-Heat"
			data[693]["name"] = "Rotom-Wash"
			data[694]["name"] = "Rotom-Frost"
			data[695]["name"] = "Rotom-Fan"
			data[696]["name"] = "Rotom-Mow"
			data[697]["name"] = "Castform-Sunny"
			data[698]["name"] = "Castform-Rainy"
			data[699]["name"] = "Castform-Snowy"
			data[700]["name"] = "Basculin-Blue-Striped"
			data[701]["name"] = "Darmanitan-Zen"
			data[702]["name"] = "Meloetta-Pirouette"
			data[703]["name"] = "Kyurem-White"
			data[704]["name"] = "Kyurem-Black"
			data[705]["name"] = "Keldeo-Resolute"
			data[706]["name"] = "Tornadus-Therian"
			data[707]["name"] = "Thundurus-Therian"
			data[708]["name"] = "Landorus-Therian"
		else
			data[650]["name"] = "Deoxys-Attack"
			data[651]["name"] = "Deoxys-Defense"
			data[652]["name"] = "Deoxys-Speed"
			data[655]["name"] = "Shaymin-Sky"	
			data[656]["name"] = "Giratina-Origin"
			data[657]["name"] = "Rotom-Heat"
			data[658]["name"] = "Rotom-Wash"
			data[659]["name"] = "Rotom-Frost"
			data[660]["name"] = "Rotom-Fan"
			data[661]["name"] = "Rotom-Mow"
			data[662]["name"] = "Castform-Sunny"
			data[663]["name"] = "Castform-Rainy"
			data[664]["name"] = "Castform-Snowy"
			data[665]["name"] = "Basculin-Blue-Striped"
			data[666]["name"] = "Darmanitan-Zen"
			data[667]["name"] = "Meloetta-Pirouette"
		end
		data
	end

	def self.export_showdown
		poks = poke_data[1..-1]

		showdown = {}


		



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
		open("public/dist/poks.js", "w") do |f| 
			f.puts "var pwPoks ="
			f.puts JSON.dump(showdown)
		end
		showdown
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


	#DEV USE ONLY
	def self.remove_setup_tms
		poke_data[1..708].each do |pok|
			tm_list = get_tm_list(pok)[:tms] + get_tm_list(pok)[:hms]
			[1,4,7,8,11,37,69,75,83,90].each do |n|
				tm_list[n - 1] = 0
			end
			data = {}
			data["file_name"] = pok["index"]
			data["field"] = "tms"
			data["value"] = tm_list
			data["narc"] = "personal"
			write_data(data)

			command = "python python/personal_writer.py update #{pok["index"]} personal"
			pid = spawn command
			Process.detach(pid)
		end
		"success"
	end


	#DEV USE ONLY
	def self.fix
		$rom_name = "to_copy"
		b2k_poks = poke_data
		$rom_name = "to_fix"
		bb2_poks = poke_data
		
		bb2_poks.each_with_index do |pok, i|
			data_to_copy = b2k_poks[i]
			next if i == 0
			break if i > 708
			file_path = "#{$rom_name}/json/personal/#{i}.json"
			file = JSON.parse(File.open(file_path){|f| f.read})

			file["readable"]["tm_1-32"]  = data_to_copy["tm_1-32"]  
			file["readable"]["tm_33-64"] = data_to_copy["tm_33-64"] 
			file["readable"]["tm_65-95+hm_1"] = data_to_copy["tm_65-95+hm_1"] 
			file["readable"]["hm_2-6"]   = data_to_copy["hm_2-6"]
			File.open(file_path, "w") { |f| f.write file.to_json }
		end
	end
end





# {"file_name"=>"186", "field"=>"tms", "value"=>["1", "0", "0", "0", "0", "1", "1", "0", "0", "1", "0", "0", "1", "1", "1", "0", "1", "1", "0", "0", "1", "0", "0", "0", "0", "1", "1", "1", "1", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "0", "1", "1", "0", "0", "0", "1", "0", "1", "1", "0", "0", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "1", "0", "0", "0", "1", "1", "1", "1"], "narc"=>"personal"}
class Trpok < Pokenarc



	def self.get_all
		@@narc_name = "trpok"
		super
	end

	def self.write_data data, batch=false
		@@narc_name = "trpok"
		@@upcases = ["species", "move"]
		super
	end

	def self.get_poks_for count, trainer_poks
		poks = []
		(0..count-1).each do |n|
			if trainer_poks["species_id_#{n}"]
				poks << trainer_poks["species_id_#{n}"].gsub(". ", "-").downcase
			end
		end
		poks
	end

	def self.fill_lvl_up_moves lvl, trainer, pok_index

		file_path = "#{$rom_name}/json/trpok/#{trainer}.json"
		trpok = JSON.parse(File.open(file_path, "r"){|f| f.read})

		pok_id = trpok["raw"]["species_id_#{pok_index}"]


		learnset_path = "#{$rom_name}/json/learnsets/#{pok_id}.json"
		learnset = JSON.parse(File.open(learnset_path, "r"){|f| f.read})

		moves = []

		(0..19).to_a.reverse.each do |n|
			lvl_learned = learnset["raw"]["lvl_learned_#{n}"]
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

		File.open(file_path, "w") { |f| f.write trpok.to_json }
		
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

		
		json_data["readable"].each do |field, value|
			if field.split("_")[-1] == "_#{n}"
				json_data["readable"].delete field
			end
		end
		
		json_data["readable"]["count"] -= 1
		File.open(file_path, "w") { |f| f.write json_data.to_json }
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

		nature_info = [[],[], "Trainer #{trainer_id}'s #{pok_name}"]

		255.downto(0).each do |n|
			pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, false, ability_slot)

			nature_info[0] << "♀ TR: With #{n} IVs: #{convert_pid_to_nature(pid, natures)}"
		end

		255.downto(0).each do |n|
			pid = get_pid(trainer_id, trainer_class, pok_id, n, pok_lvl, ability_gender, personal_gender, true, ability_slot)

			nature_info[1] << "♂ TR: With #{n} IVs: #{convert_pid_to_nature(pid, natures)}"
		end

		nature_info[3] = trpok["ivs_#{sub_index}"]



		nature_info
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
end


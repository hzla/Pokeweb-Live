class Trdata < Pokenarc


	def self.write_data data, batch=false
		@@narc_name = "trdata"
		@@upcases = []
		super
	end

	def self.get_all
		@@narc_name = "trdata"
		super
	end


	def self.get_all_mods
		@@narc_name = "trdata"
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
			
			
			file_path = "#{$rom_name}/json/trpok/#{pok['id']}.json"
			raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
			raw["level_0"] || 0
		


		end

		collection = collection.filter do |n|
			file_path = "#{$rom_name}/json/trpok/#{n['id']}.json"
			raw = JSON.parse(File.open(file_path, "r"){|f| f.read})["raw"]
			raw["ivs_0"] and raw["ivs_0"] > 250
		end

		collection
	end



	def self.names
		if SessionSettings.base_rom == "BW"
			file_name = "#{$rom_name}/message_texts/texts.json"
			names = JSON.parse(File.open(file_name, "r"){|f| f.read})[190]

			# File.open('Reference_Files/trainer_names.txt', "r").read.split("\n")
		else
			file_name = "#{$rom_name}/message_texts/texts.json"
			names = JSON.parse(File.open(file_name, "r"){|f| f.read})[382]
		end
	end

	def self.class_names
		File.open("#{$rom_name}/texts/tr_classes.txt", "r").read.split("\n")	
	end

	def self.sprite_name_for(trainer, names, i)
		sprite_name = trainer["class"].downcase.gsub(" ", "_").gsub("pkmn", "pokemon").gsub("__", "_")

		class_prefix = sprite_name.split("_")[0]
		if class_prefix == "leader" || class_prefix == "elite" || class_prefix == "champion" ||class_prefix == "subway"
			sprite_name = names[i]
		end

		"trainer_sprites/#{sprite_name}.png"
	end

	def self.ais
		["Prioritize Effectiveness",
		"Evaluate Attacks",
		"Expert",
		"Prioritize Status",
		"Risky Attacks",
		"Prioritize Damage",
		"Partner",
		"Double Battle",
		"Prioritize Healing",
		"Utilize Weather",
		"Harassment",
		"Roaming Pokemon",
		"Safari Zone",
		"Catching Demo"]
	end

	def self.has_items? trainer
		"checked" if trainer["has_items"] > 0
	end

	def self.has_moves? trainer
		"checked" if trainer["has_moves"] > 0
	end


	def self.export_showdown
		
	end

	def self.get_locations
		overworlds = Overworld.get_all

		tr_count = files = Dir["#{$rom_name}/json/trdata/*.json"]
		file_count = files.length


	

		overworlds.each_with_index do |overworld, i|
			npc_count = overworld["npc_count"]

			(0..npc_count-1).each do |n|
				script_id = overworld["npc_#{n}_script_id"]
				if (script_id > 3000 and script_id < (3000 + file_count)) or (script_id > 5000 and script_id < (5000 + file_count))

					file_path = "#{$rom_name}/json/trdata/#{script_id % 1000}.json"
					json_data = JSON.parse(File.open(file_path, "r") {|f| f.read})

					location = Header.find_location_by_map_id(i)

					json_data["readable"]["location"] = location
					File.open(file_path, "w") { |f| f.write json_data.to_json }
					p script_id
					p location
				end
			end



		end

	end

end


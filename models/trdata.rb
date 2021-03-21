class Trdata


	def self.get_data(file_name)
		JSON.parse(File.open(file_name, "r").read)["readable"]
	end

	def self.names
		File.open('Reference_Files/trainer_names.txt', "r").read.split("\n")
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
	def self.get_all
		trainers = []
		files = Dir["#{$rom_name}/json/trdata/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			json = JSON.parse(File.open("#{$rom_name}/json/trdata/#{n}.json", "r").read)
			tr_data = json["readable"]

			trainers[n] = tr_data
		end
		trainers
	end

	def self.has_items? trainer
		"checked" if trainer["has_items"] > 0
	end

	def self.has_moves? trainer
		"checked" if trainer["has_moves"] > 0
	end


	def self.write_data data
		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		file_path = "#{$rom_name}/json/trdata/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r").read)

		if data["int"]
			changed_value = changed_value.to_i
		end

		if data["field"] == "class"
			class_data = changed_value.split(" (")
			changed_value = class_data[0]
			
			new_class_id = class_data[1].split(")")[0]
			json_data["readable"]["class_id"] = new_class_id
		end



		json_data["readable"][field_to_change] = changed_value

		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end


end


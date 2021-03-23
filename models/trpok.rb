class Trpok


	def self.get_all
		trainers = []
		files = Dir["#{$rom_name}/json/trpok/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			json = JSON.parse(File.open("#{$rom_name}/json/trpok/#{n}.json", "r"){|f| f.read})
			tr_data = json["readable"]

			trainers[n] = tr_data
		end
		trainers
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

	def self.write_data data
		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		if data["int"]
			changed_value = changed_value.to_i
		elsif field_to_change.include?("species") || field_to_change.include?("move")
			changed_value = changed_value.upcase
		end

		file_path = "#{$rom_name}/json/trpok/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r"){|f| f.read})

		json_data["readable"][field_to_change] = changed_value

		File.open(file_path, "w") { |f| f.write json_data.to_json }
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
end


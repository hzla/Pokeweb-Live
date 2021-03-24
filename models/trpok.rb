class Trpok < Pokenarc


	def self.get_all
		@@narc_name = "trpok"
		super
	end

	def self.write_data data
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


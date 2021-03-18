class Encounter

	def self.get_data(file_name)
		JSON.parse(File.open(file_name, "r").read)["readable"]
	end

	def self.get_all
		files = Dir["#{$rom_name}/json/encounters/*.json"].sort_by{ |name| [name[/\d+/].to_i, name] }
		files = files.map do |pok|
			get_data pok
		end
		expand_encounter_info(files, Header.get_all)

	end

	def self.write_data data
		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		if data["int"]
			changed_value = changed_value.to_i
		else
			changed_value = changed_value.upcase
		end

		file_path = "#{$rom_name}/json/encounters/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r").read)

		json_data["readable"][field_to_change] = changed_value

		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end

	def self.expand_encounter_info(encounter_data, header_data)
		header_count = header_data["count"]
		encounter_count = encounter_data.length

		(1..header_count).each do |n|
			header = header_data[n.to_s]
			encounter_id = header["encounter_id"]

			if encounter_id <= encounter_count
				if encounter_data[encounter_id]["locations"]
					encounter_data[encounter_id]["locations"].push("#{header["location_name"]} (#{n})")
				else
					encounter_data[encounter_id]["locations"] = ["#{header["location_name"]} (#{n})"]
				end
			end
		end

		encounter_data.each_with_index do |enc, i|
			wilds = []
			["grass", "grass_doubles", "grass_special"].each do |enc_type|
				(0..11).each do |n|
					wilds << enc["#{enc_type}_slot_#{n}"].gsub(/[^0-9A-Za-z]/, '').downcase
				end
			end
			["surf", "surf_special", "super_rod" , "super_rod_special"].each do |enc_type|
				(0..4).each do |n|
					wilds << enc["#{enc_type}_slot_#{n}"].gsub(". ", "-").downcase
				end
			end
			encounter_data[i]["wilds"] = wilds.reject(&:empty?).uniq
		end
		encounter_data
	end

	def self.grass_fields
		["grass", "grass_doubles", "grass_special"]
	end

	def self.water_fields
		["surf", "surf_special", "super_rod" , "super_rod_special"]
	end

	def self.grass_percent_for(n)
		[20,20,10,10,10,10,5,5,4,4,1,1][n]
	end

	def self.water_percent_for(n)
		[60, 30, 5, 4, 1][n]
	end
end


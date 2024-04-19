class Encounter < Pokenarc


	def self.get_all
		@@narc_name = "encounters"
		data = super
		expand_encounter_info(data, Header.get_all)

	end

	def self.get_all
		@@narc_name = "encounters"
		data = super
		if $gen == 4
			hgss_expand_encounter_info(data, Header.get_all)
		else
			expand_encounter_info(data, Header.get_all)
		end

	end

	def self.get_data file_name, type="readable"
		@@narc_name = "encounters"
		super
	end

	def self.hgss_expand_encounter_info(encounter_data, header_data)
		encounter_count = encounter_data.length
		header_count = header_data["count"]


		(1..539).each do |n|
			header = header_data[n.to_s]
			encounter_id = header["encounter"]

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
			
			hgss_grass_fields.each do |enc_type|
				p enc_type
				(0..11).each do |n|
					wilds << enc["#{enc_type}_#{n}_species_id"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
				end
			end
			extra_fields.each_with_index do |enc_type, j|
				p enc_type
				(0..extra_field_counts[j] - 1).each do |n|
					wilds << enc["#{enc_type}_#{n}_species_id"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
				end
			end

			encounter_data[i]["wilds"] = wilds.reject(&:empty?).uniq
			encounter_data[i]["wilds"].delete("-----")
		end
		encounter_data
	end

	def self.hgss_grass_fields
		return ["morning", "day", "night"] if SessionSettings.base_rom == "HGSS"
		["day"]
	end

	def self.hgss_water_fields
		return ["surf", "surf_special", "super_rod" , "super_rod_special"] if SessionSettings.base_rom == "HGSS"
		 ["surf", "old_rod", "good_rod" , "super_rod"]
	end

	def self.extra_fields
		return ["surf", "rock_smash", "old_rod", "good_rod", "super_rod", "hoenn", "sinnoh"] if SessionSettings.base_rom == "HGSS"
		["surf", "old_rod", "good_rod", "super_rod", "radar"]
	end

	def self.extra_field_counts
		return [5,2,5,5,5,2,2] if SessionSettings.base_rom == "HGSS"
		[5,5,5,5,4]
	end

	def self.update_locations
		locations = File.read("#{$rom_name}/texts/enc_locations.txt").split("\n")


		(0..136).each do |n|
			file_path = "#{$rom_name}/json/encounters/#{n}.json"
			json_data = JSON.parse(File.open(file_path, "r") {|f| f.read})

			json_data["readable"]["locations"] = [locations[n]]

			File.open(file_path, "w") { |f| f.write json_data.to_json }

			p n
		end
	end

	def self.search encs, location
		location = location.downcase.gsub(" ", "")
		encs.each_with_index do |enc, i|
			next if !enc["locations"]
			enc_loc = enc["locations"][0].split(" (")[0].gsub(" ","").downcase

			return i if location == enc_loc
		end
		return 0
	end


	def self.write_data data, batch=false
		@@narc_name = "encounters"
		@@upcases = "all"
		super
	end

	def self.get_max_level id
		enc =  get_data("#{$rom_name}/json/encounters/#{id}.json")
		max = 0
		(0..11).each do |n|
			if enc["spring_grass_doubles_slot_#{n}_max_level"] > max
				max = enc["spring_grass_doubles_slot_#{n}_max_level"]
			end
		end

		(0..11).each do |n|
			if enc["spring_grass_slot_#{n}_max_level"] > max
				max = enc["spring_grass_slot_#{n}_max_level"]
			end
		end

		(0..11).each do |n|
			if enc["spring_grass_special_slot_#{n}_max_level"] > max
				max = enc["spring_grass_special_slot_#{n}_max_level"]
			end
		end

		return max if max != 0

		(0..4).each do |n|
			if enc["spring_surf_slot_#{n}_max_level"] > max
				max = enc["spring_surf_slot_#{n}_max_level"]
			end
		end

		max
	end

	# def self.level_sorted
	# 	data = get_all
	# 	get_all.sort_by do |enc|
	# 		get_max_level(enc["index"])
	# 	end
	# end

	def self.g4_get_max_level id
		enc =  get_data("#{$rom_name}/json/encounters/#{id}.json")
		max = 0

		(0..11).each do |n|
			if enc["walking_#{n}_level"] > max
				max = enc["walking_#{n}_level"]
			end
		end

		return max if max != 0

		(0..4).each do |n|
			if enc["surf_#{n}_max_lvl"] > max
				max = enc["surf_#{n}_max_lvl"]
			end
		end
		max
	end




	def self.level_sorted gen=5
		data = get_all
		get_all.sort_by do |enc|
			if $gen == 5
				get_max_level(enc["index"])
			else
				g4_get_max_level(enc["index"])
			end
		end
	end

	def self.copy_season_to_all id, copied_season
		enc_path = "#{$rom_name}/json/encounters/#{id}.json"
		enc_data = get_data(enc_path, "all")
		
		enc = enc_data.clone
		

		["readable", "raw"].each do |type|
			enc_data[type].each do |k, v|
				(["spring", "summer", "fall", "winter"] - [copied_season]).each do |season|
					if k.include? season
						enc[type][k] = enc[type][k.gsub(season, copied_season)]
					end
				end
			end
		end

		File.open(enc_path, "w") { |f| f.write enc.to_json }
		"200 OK"
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
			unformatted_wilds = []
			
			seasons.each do |season|
				grass_fields.each do |enc_type|
					(0..11).each do |n|
						wilds << enc["#{season}_#{enc_type}_slot_#{n}"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
						unformatted_wilds << enc["#{season}_#{enc_type}_slot_#{n}"].name_titleize
					end
				end
				water_fields.each do |enc_type|
					(0..4).each do |n|
						wilds << enc["#{season}_#{enc_type}_slot_#{n}"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
						unformatted_wilds << enc["#{season}_#{enc_type}_slot_#{n}"].name_titleize
					end
				end
			end
			encounter_data[i]["wilds"] = wilds.reject(&:empty?).uniq
			encounter_data[i]["nf-wilds"] = unformatted_wilds.reject(&:empty?).uniq
			encounter_data[i]["index"] = i
		end
		encounter_data
	end

	def self.seasons
		["spring", "summer", "fall", "winter"]
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

	def self.extra_percent_for(n)
		[60, 30, 5, 4, 1][n]
	end

	def self.output_documentation
	end
end


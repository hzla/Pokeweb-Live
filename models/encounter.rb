class Encounter < Pokenarc


	def self.get_all
		@@narc_name = "encounters"
		data = super
		expand_encounter_info(data, Header.get_all)
	end

	def self.get_data file_name, type="readable"
		@@narc_name = "encounters"
		super
	end

	def self.get_evo species_name, lvl, evo_data, names, mons
		return "" if species_name == ""
		species_index = names.index(species_name.downcase.gsub(" ", ""))
		evo = evo_data[species_index]

		target = nil

		if !evo["method_0"] or evo["method_0"] == "None"
			return species_name
		else
			target = evo["target_0"].downcase.gsub(" ", "")
		end

		# If the level to evolve is below the specified level
		p evo["method_0"]
		if evo["method_0"].include?("Level ") and !evo["method_0"].include?("with Item") and !evo["method_0"].include?("With Party") and evo["param_0"] <= lvl	
			return get_evo(target, lvl, evo_data, names, mons)
		end

		# Force evo for happiness
		if evo["method_0"] == "Max Happiness"
			return get_evo(target, lvl, evo_data, names, mons)
		end

		# Force item evo after level 20
		if evo["method_0"].include?("Item Use")
			if lvl <= 20
				return species_name 
			else
				return get_evo(target, lvl, evo_data, names, mons)
			end
		end

		if evo["method_0"] == "After Learning Specific Move"
			move = evo["param_0"]
			learnset = mons[species_index]["learnset"]
			lvl_learned = 100

			(0..24).each do |slot|
				if !learnset["move_id_#{slot}"]
					p slot
					break
				end
				if learnset["move_id_#{slot}"] == move
					lvl_learned = learnset["lvl_learned_#{slot}"]
				end
			end

			if lvl >= lvl_learned
				return get_evo(target, lvl, evo_data, names, mons)
			end
		end

		species_name
	end


	def self.export_showdown

		evos = Evolution.get_all
		names = RomInfo.pokemon_names.map {|s| s.downcase.gsub(" ", "")}
		mons = Personal.poke_data


		encs = get_all.map do |enc|
			sd_enc = {}
			
			sd_enc["gr"] = []
			sd_enc["grd"] = []

			sd_enc["srf"] = []
			sd_enc["srfsp"] = []

			sd_enc["rod"] = []
			sd_enc["rodsp"] = []


			# get grass encounters
			(0..11).each do |n|
				lvl = enc["spring_grass_slot_#{n}_max_level"]
				sd_enc["gr"] << enc["spring_grass_slot_#{n}"]

				evolved = get_evo(enc["spring_grass_slot_#{n}"], lvl, evos, names, mons)

				p enc["spring_grass_slot_#{n}"]
				p "evolve to: #{evolved} at lvl #{lvl}"	
				break


				sd_enc["grd"] << enc["spring_grass_doubles_slot_#{n}"]
			end
			# get water encounters
			(0..4).each do |n|
				sd_enc["srf"] << enc["spring_surf_slot_#{n}"]
				sd_enc["srfsp"] << enc["spring_surf_special_slot_#{n}"]

				sd_enc["rod"] << enc["spring_super_rod_slot_#{n}"]
				sd_enc["rodsp"] << enc["spring_super_rod_special_slot_#{n}"]
			end

			# get levels
			sd_enc["gr_cap"] = enc["spring_grass_slot_11_max_level"]
			sd_enc["srf_cap"] = enc["spring_surf_slot_4_max_level"]
			sd_enc["rod_cap"] = enc["spring_super_rod_slot_4_max_level"]

			sd_enc["loc"] = enc["locations"][0].split("(")[0].strip

			sd_enc
		end

		File.write("./encs.json", JSON.pretty_generate(encs))

		return "Success"
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

	def self.level_sorted
		data = get_all
		get_all.sort_by do |enc|
			get_max_level(enc["index"])
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
			
			seasons.each do |season|
				grass_fields.each do |enc_type|
					(0..11).each do |n|
						wilds << enc["#{season}_#{enc_type}_slot_#{n}"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
					end
				end
				water_fields.each do |enc_type|
					(0..4).each do |n|
						wilds << enc["#{season}_#{enc_type}_slot_#{n}"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
					end
				end
			end
			encounter_data[i]["wilds"] = wilds.reject(&:empty?).uniq
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

	def self.output_documentation
	end
end


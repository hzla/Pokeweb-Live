require 'json'

encs = File.read("enc.txt").split("\n")

pok_names = File.read("projects/renplat/texts/pokedex.txt").split("\n")



current_enc = {"raw" => {}, "readable" => {}}
enc_count = 0

encs.each_with_index do |line, i|
	if line == "====\r"
		File.write("../encounters/#{enc_count}.json", current_enc.to_json)
		current_enc = {"raw" => {}, "readable" => {}}
		enc_count += 1
		p enc_count
		next
	end

	field = line.split(": ")[0]
	values = line.split(": ")[1][1..-3]

	if values
		values = values.split(",")
	end



	if field == "morningPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["morning_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["morning_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end

	if field == "radarPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["radar_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["radar_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end

	if field == "walkingPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["day_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["day_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end

	if field == "nightPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["night_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["night_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end

	if field == "hoennMusicPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["hoenn_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["hoenn_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end



	if field == "rockSmashPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["rock_smash_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["rock_smash_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end

	if field == "goodRodPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["good_rod_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["good_rod_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end
	if field == "oldRodPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["old_rod_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["old_rod_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end
	if field == "surfPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["super_rod_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["super_rod_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end
	if field == "surfPokemon"
		values.each_with_index do |pok, n|
			current_enc["raw"]["surf_#{n}_species_id"] = pok.to_i
			current_enc["readable"]["surf_#{n}_species_id"] = pok_names[pok.to_i]
		end
	end


	if field == "rockSmashMinLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["rock_smash_#{n}_min_lvl"] = lvl.to_i
			current_enc["readable"]["rock_smash_#{n}_min_lvl"] = lvl.to_i
		end
	end

	if field == "rockSmashMaxLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["rock_smash_#{n}_max_lvl"] = lvl.to_i
			current_enc["readable"]["rock_smash_#{n}_max_lvl"] = lvl.to_i
		end
	end

	if field == "goodRodMinLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["good_rod_#{n}_min_lvl"] = lvl.to_i
			current_enc["readable"]["good_rod_#{n}_min_lvl"] = lvl.to_i
		end
	end

	if field == "goodRodMaxLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["good_rod_#{n}_max_lvl"] = lvl.to_i
			current_enc["readable"]["good_rod_#{n}_max_lvl"] = lvl.to_i
		end
	end

	if field == "oldRodMinLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["old_rod_#{n}_min_lvl"] = lvl.to_i
			current_enc["readable"]["old_rod_#{n}_min_lvl"] = lvl.to_i
		end
	end

	if field == "oldRodMaxLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["old_rod_#{n}_max_lvl"] = lvl.to_i
			current_enc["readable"]["old_rod_#{n}_max_lvl"] = lvl.to_i
		end
	end

	if field == "superRodMinLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["super_rod_#{n}_min_lvl"] = lvl.to_i
			current_enc["readable"]["super_rod_#{n}_min_lvl"] = lvl.to_i
		end
	end

	if field == "superRodMaxLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["super_rod_#{n}_max_lvl"] = lvl.to_i
			current_enc["readable"]["super_rod_#{n}_max_lvl"] = lvl.to_i
		end
	end

	if field == "walkingLevels"
		values.each_with_index do |lvl, n|
			current_enc["raw"]["walking_#{n}_level"] = lvl.to_i
			current_enc["readable"]["walking_#{n}_level"] = lvl.to_i
		end
	end
end

















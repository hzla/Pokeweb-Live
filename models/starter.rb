class Starter

	def self.write_data data
		starter_index = data["field"].split("_")[-1].to_i
		current_starters = SessionSettings.get("starters")
		current_starters[starter_index] = data["value"].upcase
		SessionSettings.set "starters", current_starters
		change_starter_script
	end

	def self.change_overlay_starters 
		starter_selections = SessionSettings.get("starters").map do |starter|
			RomInfo.raw_pokemon_names.index(starter)
		end

		overlay = File.open("#{$rom_name}/overlay316.bin", "rb")
		unpacked_overlay = overlay.read.unpack("S*")
		overlay.seek 0


		if SessionSettings.get("starter_overlay_offset")
			offset = SessionSettings.get("starter_overlay_offset")

			(0..2).each do |n|
				unpacked_overlay[offset + n] = starter_selections[n]
			end
		else #first time editing
			unpacked_overlay.each_with_index do |uint16, i|
				if uint16 == 495 && unpacked_overlay[i + 1] == 498 && unpacked_overlay[i + 2] == 501
					(0..2).each do |n|
						unpacked_overlay[i + n] = starter_selections[n]
					end
					SessionSettings.set "starter_overlay_offset", i
					break
				end
			end
			
		end

		edited_overlay = unpacked_overlay.pack("S*")
		File.binwrite("#{$rom_name}/overlay316.bin", edited_overlay)
	end

	def self.change_starter_script old_starters=[495,498,501]
		
		starter_selections = SessionSettings.get("starters").map do |starter|
			RomInfo.raw_pokemon_names.index(starter)
		end

		p starter_selections

		script = File.open("#{$rom_name}/scripts/854.bin", "rb")

		unpacked_script = script.read.unpack("S*")
		script.seek 0

		found_indices = [[],[],[]]

		occs = []

		

		# if starters have been edited before, use the offsets stored from the first edit
		if SessionSettings.get("starter_script_offsets")
			offsets = SessionSettings.get("starter_script_offsets")

			offsets.each_with_index do |starter_offsets, i|
				starter_offsets.each do |offset|
					unpacked_script[offset] = starter_selections[i]
				end
			end
		else #first time editting
			unpacked_script.each_with_index do |uint16, i|
				if old_starters.index(uint16)
					#replace starter
					unpacked_script[i] = starter_selections[old_starters.index(uint16)]

					#save index where old starter was found
					found_indices[old_starters.index(uint16)] << i
				end
			end
			SessionSettings.set "starter_script_offsets", found_indices
		end

		edited_script = unpacked_script.pack("S*")
		File.binwrite("#{$rom_name}/scripts/854.bin", edited_script)
		change_overlay_starters
	end


	def self.get_index_of_occurences to_search, string, replacement
		occs = []
		(0..to_search.length-1).each do |n|
			if to_search[n..n+3] == string
				occs << n
				to_search[n..n+3] = replacement
			end
		end

		occs
	end

end
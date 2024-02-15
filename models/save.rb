class Save


	def self.read_rad_red(save_data, static_level=100)
		save_index_a_offset = 0xffc
		save_block_b_offset = 0x00E000
		trainer_id_offset = 0xa
		save_index_b_offset = save_block_b_offset + save_index_a_offset

		all_moves = File.read("./Reference_Files/save_constants/moves_rad_red.txt").split("\n")
		all_mons = File.read("./Reference_Files/save_constants/mons_rad_red.txt").split("\n")
		abils = JSON.parse(File.read('./Reference_Files/save_constants/rr_abils.json'))

		save = save_data

		save_index_a = save[save_index_a_offset..save_index_a_offset + 1].unpack("S")[0]
		save_index_b = save[save_index_b_offset..save_index_b_offset + 1].unpack("S")[0]
		block_offset = 0

		if save_index_b > save_index_a
			block_offset = save_block_b_offset
		end

		save = save[block_offset..block_offset + 57343]

		save_index = [save_index_a, save_index_b].max

		rotation = save_index % 14
		total_offset = rotation * 4096




		new_trainer_id_offset = total_offset + trainer_id_offset
		trainer_id = save[new_trainer_id_offset..new_trainer_id_offset + 3].unpack("V")[0]
		box_offset = (20480 + 4 + total_offset) % 57344
		party_offset = (total_offset + 4096 + 0x38) % 57344

		box_data = ""

		party_data = save[party_offset..party_offset + 599]
		box_data += party_data

		box_data += save[box_offset..box_offset + 33599]



		party_count = save[party_offset-4].unpack('C')[0]


		(0..8).each do |n|
			box_start = ((n * 4096) + box_offset) % 57344
			pc_box = save[box_start..box_start + 4095]
			box_data += pc_box
		end



		magic_string = box_data[18..19]

		mon_count = 0

		box_suboffset = 0
		import_data = ""

		# p magic_string.unpack("v")[0]

		n = 0
		while n < box_data.length
			break if n > 34200
			data = box_data[n..n+1]
			if data != magic_string
				n += 2
				next
			else

				if mon_count < party_count #for party pokemon
					showdown_data = box_data[n+14..n+43]
				else
					showdown_data = box_data[n+10..n+39]
				end

				

				pid = box_data[n-18..n-15].unpack('V')[0]
				nature = RomInfo.natures[pid % 25]
				ability_slot = pid % 2 == 0 ? 0 : 1
				

				ability_slot = 2 if showdown_data[-1].unpack('C')[0] == 191 # dream ability if last bit is 1
				species_id = showdown_data[0..1].unpack('v')[0]

				if !all_mons[species_id] || all_mons[species_id] == "-----" #false positive for mon detection
					p [species_id, n]
					n += 2
					next
				end		

				p all_mons[species_id]
				ability = abils[all_mons[species_id]][ability_slot]
				
				moves_binary =  showdown_data[-19..-14].unpack('b*')[0]

				moves = []
				(0..3).each do |n|
					move_id = moves_binary[n*10..((n+1) * 10 - 1)].reverse.to_i(2)
					moves << all_moves[move_id]
				end

				p all_mons[species_id]
				
				set = {}

				import_data += all_mons[species_id].strip + "\n"
				import_data += "Level: #{static_level}\n"
				import_data += "#{nature} Nature\n"
						
				import_data += "Ability: #{ability}\n"
				moves.each do |m|
					import_data += "- #{m}\n"
				end
				import_data += "\n"
				mon_count += 1
				n += 32
			end
		end

		import_data
	end




	def self.read(save_data, static_level=100, game="inc_em") #INCLEMENT EMERALD/POKEMERALD
		if game == "rad_red"
			return read_rad_red(save_data, static_level)
		end

		save_index_a_offset = 0xffc
		save_block_b_offset = 0x00E000
		trainer_id_offset = 0xa
		save_index_b_offset = save_block_b_offset + save_index_a_offset

		all_moves = File.read("./Reference_Files/save_constants/moves.txt").split("\n")
		all_mons = File.read("./Reference_Files/save_constants/mons.txt").split("\n")



		# if save_index odd should be at save_block B otherwise A


		# save_path = "./IE.sav"
		save = save_data


		save_index_a = save[save_index_a_offset..save_index_a_offset + 1].unpack("S")[0]
		save_index_b = save[save_index_b_offset..save_index_b_offset + 1].unpack("S")[0]
		block_offset = 0

		if save_index_b > save_index_a
			block_offset = save_block_b_offset
		end

		save = save[block_offset..block_offset + 57343]


		#comment this out later
		# block_offset = 0


		#change this to the larger of the two save indexes later
		save_index = [save_index_a, save_index_b].max
		# save_index = save_index_a

		rotation = (save_index % 14)
		total_offset = rotation * 4096


		new_trainer_id_offset = total_offset + trainer_id_offset
		trainer_id = save[new_trainer_id_offset..new_trainer_id_offset + 3].unpack("V")[0]
		box_offset = (20480 + 4 + total_offset) % 57344
		party_offset = (total_offset + 4096 + 0x238) % 57344




		box_data = ""
		box_data = save[box_offset..box_offset + 33599]

		party_data = save[party_offset..party_offset + 599]

		box_data += party_data





		(0..8).each do |n|
			box_start = ((n * 4096) + box_offset) % 57344
			pc_box = save[box_start..box_start + 4095]
			box_data += pc_box
		end



		trainer_string = save[new_trainer_id_offset..new_trainer_id_offset + 3]

		mon_count = 0

		box_suboffset = 0
		import_data = ""

		# p trainer_string.unpack("V")[0]

		n = 0
		while n < box_data.length
			break if n > 34200
			data = box_data[n..n+3]
			if data != trainer_string
				n += 4
				next
			else

				mon_data = box_data[n-4..n+75]

				begin
					pid = mon_data[0..3].unpack("V")[0]
					tid = mon_data[4..7].unpack("V")[0]
				rescue
					# binding.pry
				end
				sub_order = order_formats[pid % 24]

				key = tid ^ pid

				showdown_data = mon_data[32..-1]

				#decrypt with key

				decrypted = []
				(0..11).each do |m|
					start = m * 4
					block = showdown_data[start..start + 3].unpack("V")[0]
					decrypted << (block ^ key)
				end

				growth_index = sub_order.index(1)
				moves_index = sub_order.index(2)
				misc_index = sub_order.index(4)



				species_id = [decrypted[growth_index * 3]].pack('V').unpack('vv')[0]

				if species_id > 899
					species_id += 7
				end

				exp = decrypted[growth_index * 3 + 1]
				lvl = static_level
				nature_byte = [decrypted[misc_index * 3]].pack('V').unpack('vv')[1]
				nature = RomInfo.natures[(nature_byte & 31744) >> 10]

				
				move1 = all_moves[[decrypted[moves_index * 3]].pack('V').unpack('vv')[0]]
				move2 = all_moves[[decrypted[moves_index * 3]].pack('V').unpack('vv')[1]]
				move3 = all_moves[[decrypted[moves_index * 3 + 1]].pack('V').unpack('vv')[0]]
				move4 = all_moves[[decrypted[moves_index * 3 + 1]].pack('V').unpack('vv')[1]]

				ivs = [decrypted[misc_index * 3 + 1]][0]
				iv_stats = ["HP", "Atk", "Def", "Spe", "SpA", "SpD"]
				spread = {}

				iv_stats.each_with_index do |stat, i|
					spread[stat] = middle_bits_from_index(ivs, i * 5, 5)
				end
				ability_slot = (decrypted[misc_index * 3 + 2] & 96) >> 5

				moves = [move1, move2, move3, move4]
				
				set = {}
				
				begin

					import_data += all_mons[species_id].strip + "\n"
				rescue
					p "Error: Species ID #{species_id}"
					import_data += "Unknown\n"
					# binding.pry
				end
				import_data += "Level: #{lvl}\n"
				import_data += "#{nature} Nature\n"
				
				import_data += "IVs: "
				iv_stats.each do |stat|
					import_data += "#{spread[stat]} #{stat} / "
				end
				import_data = import_data[0..-4]
				import_data += "\n"
				
				import_data += "Ability: #{ability_slot}\n"
				moves.each do |m|
					import_data += "- #{m}\n"
				end
				import_data += "\n"
				mon_count += 1
				n += 44
			end


		end
		import_data
	end

	def self.order_formats
		[[1,2,3,4],			
		[1,2,4,3],			
		[1,3,2,4],			
		[1,3,4,2],			
		[1,4,2,3],			
		[1,4,3,2],			
		[2,1,3,4],
		[2,1,4,3],
		[2,3,1,4],
		[2,3,4,1],
		[2,4,1,3],
		[2,4,3,1],
		[3,1,2,4],
		[3,1,4,2],
		[3,2,1,4],
		[3,2,4,1],
		[3,4,1,2],
		[3,4,2,1],
		[4,1,2,3],
		[4,1,3,2],
		[4,2,1,3],
		[4,2,3,1],
		[4,3,1,2],
		[4,3,2,1]]
	end

	def self.middle_bits_from_index(number, m, n)
	  # Create a mask to extract 'n' bits
	  mask = (1 << n) - 1

	  # Shift the mask to align it with the desired starting bit and extract those bits
	  result = (number >> m) & mask

	  result
	end




end
class Action

# skip 161,162,163
	
	def self.output_moves
		moves = Move.get_all
		vanilla_moves = Move.get_all "documentation/vanilla"
		
		p vanilla_moves.length
		open('documentation/moves.txt', 'w') do |f|
			moves.each_with_index do |move, i|
				if move != vanilla_moves[i]
					move = move[1]
					vanilla_move = vanilla_moves[i][1]

					f.puts "==================="
					f.puts move["name"].move_titleize
					f.puts "==================="

					
					f.puts "(Old)"
					f.puts "#{vanilla_move["power"]}  BP || #{vanilla_move["accuracy"]} ACC || #{vanilla_move["category"]} || #{vanilla_move["type"]} || #{vanilla_move["pp"]} PP"

					f.puts "Effect: #{vanilla_move["effect"]}"
					f.puts

		
					f.puts "(New)"
					f.puts "#{move["power"]}  BP || #{move["accuracy"]} ACC || #{move["category"]} || #{move["type"]} || #{move["pp"]} PP"

					f.puts "Effect: #{move["effect"]}"
					f.puts
				end
			end
		end
		"200 OK"
	end

	def self.output_docs
		poks = Personal.poke_data
		vanilla_poks = Personal.poke_data "documentation/vanilla"
		evolutions = Evolution.get_all


		open('documentation/pokedex.txt', 'w') do |f|
		  	poks.each_with_index do |pok, i|
		  		next if i == 0

		  		if pok && pok["base_hp"]
			  		f.puts "==================="
			  		f.puts "#{i} - #{pok["name"].name_titleize}"
			  		f.puts "==================="
			  		
			  		if format_types(pok) != format_types(vanilla_poks[i])
			  			f.puts "Old: " + format_types(vanilla_poks[i])
			  			f.puts "New: " + format_types(pok)
			  		else
			  			f.puts format_types(pok)
			  		end
			  		f.puts

			  		if format_abilities(pok) != format_abilities(vanilla_poks[i])
			  			f.puts "Old: " + format_abilities(vanilla_poks[i])
			  			f.puts "New: " + format_abilities(pok)
			  		else
			  			f.puts format_abilities(pok)
			  		end
			  		
			  		formatted_stats = format_stats(pok)
			  		formatted_vanilla_stats = format_stats(vanilla_poks[i])
			  		
			  		f.puts
			  		if formatted_stats != formatted_vanilla_stats	
			  			f.puts "Old: " + formatted_vanilla_stats
			  			f.puts "New: " + formatted_stats
			  		else
			  			f.puts formatted_stats
			  		end

			  		f.puts

			  		evo = evolutions[i]

			  		(0..6).each do |n|
			  			if evo["target_#{n}"] != ""
			  				target = evo["target_#{n}"]
			  				meth = evo["method_#{n}"]
			  				param = evo["param_#{n}"]
			  				f.puts "Evolves to #{target.name_titleize} by #{meth} / #{param}"
			  			end
			  		end
			 
			  		f.puts 
			  		f.puts "Level Up:"
			  		learnset = pok["learnset"]
			  		n = 0
			  		until !learnset["move_id_#{n}"]
			  			f.puts "#{learnset["lvl_learned_#{n}"]} - #{learnset["move_id_#{n}"].move_titleize}"
			  			n += 1
			  		end
			  		f.puts 
			  		f.puts
			  	end
			end
		end
		"success"	
	end

	def self.output_encs
		encs = Encounter.level_sorted

		open('documentation/encounters.txt', 'w') do |f|
			encs.each do |enc|
				if enc["locations"] and !enc["locations"].empty?
					f.puts "=================="
					f.puts enc["locations"].join(" / ").gsub(/\(.*\)/, "")
					f.puts "=================="
					f.puts
				end

			end
		end
		"200 OK"
	end

	def self.format_stats pok
		stats = [pok["base_hp"], pok["base_atk"],  pok["base_def"], pok["base_spatk"], pok["base_spdef"], pok["base_speed"]]
		bst = stats.inject(&:+)
		formatted = ""

		["hp", "atk", "def", "spatk", "spdef", "speed"].each do |stat|
			formatted += "#{stat.downcase} #{pok["base_#{stat}"]}/ "
		end
		formatted += "(#{bst}) BST"   
	end

	def self.format_abilities pok
		[pok["ability_1"], pok["ability_2"], pok["ability_3"]].join(" / ").name_titleize
	end

	def self.format_types pok
		[pok["type_1"], pok["type_2"]].uniq.join(" ").name_titleize
	end

	def self.rand_teams
		# determine gym and e4 types

		$last_used_pool = {}
		types = ["Normal", "Fire", "Water", "Electric", "Grass", "Ice",
             "Fighting", "Poison", "Ground", "Flying", "Psychic",
             "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel"].sample(12)

        File.open("randomizer/randomized_gym_types.json", "w") { |f| f.write types.to_json }

        target_gym_viabilities = load_file('gym_viabilities')
        base_rom_level_caps = load_file('base_rom_level_caps')

        tr_count = Trdata.get_all.length
        levels = base_rom_level_caps.map {|n| n["gym"]}
        level_grouped_trainers = Trpok.level_grouped levels

        rival1_tr_ids = [161,162,163]

        multi_battles = [588,589,590, 342,356,732,733,363,364,365,360,361,362]

        blacklist = {}

        target_gym_viabilities[0..7].each do |gym|
        	(gym["tr_id"] + gym["gym_tr_ids"]).each do |n|
        		blacklist[n] = true
        	end
        end

        (target_gym_viabilities[8]["e1"] + target_gym_viabilities[8]["e2"] + target_gym_viabilities[8]["e3"] + target_gym_viabilities[8]["e4"] + target_gym_viabilities[8]["champ"] + rival1_tr_ids).each do |n|
        	blacklist[n] = true
       	end 

       	 multi_battle_list = {}
       	 multi_battles.each do |n|
       	 	multi_battle_list[n] = true
       	 end
       	
       	p blacklist
       	p multi_battle_list

       	level_grouped_trainers.each_with_index do |group, i|
       		group_count = group.length 
       		


       		#pre gym 1 trainers start at -80bst from gym 1, all other start at -50
       		bst_increment = (i == 0 ? (80 / ([group_count, 1].max)) : (50 / ([group_count, 1].max)))
       		prev_gym_lvl = (i == 0 ? 5.0 : target_gym_viabilities[i-1]["lvl"])
       		gym_lvl = target_gym_viabilities[i]["lvl"]

       		lvl_increment = (gym_lvl.to_f - prev_gym_lvl) / tr_count
       		
       		group_count = group.length
       		
       		# for each gym split
       		group.each_with_index do |trpok, j|
       			p "randomizing trainer #{j}, gym #{i}"


        			#avoid gym trainers/leader and rival1   
       			# weaker trainers before gym 1
       			below_gym = (i == 0 ? 80 : 50)
       			pok_count = (i == 0 ? rand(2) + 3 : rand(3) + 4)

       			if multi_battle_list[trpok["index"]]
       				pok_count = 3
       			end
   		
   				#create non gym trainers

   				if !blacklist[trpok["index"]]
   					range_low = (target_gym_viabilities[i]['range'][0] - below_gym) + (bst_increment * j)
   					range_high = (target_gym_viabilities[i]['range'][1] - below_gym) + (bst_increment * j)

 

   					# pokemon trainer class gets stronger pokemon
   					if trpok["class"].downcase.include?("trainer")
   						range_low = (target_gym_viabilities[i]['range'][0] - 10) 
   						range_high = (target_gym_viabilities[i]['range'][1] - 10) 
   					end

   					team = Randomizer.create_team [range_low, range_high], pok_count, "all", (prev_gym_lvl + lvl_increment).round 
   					Randomizer.apply_team team, trpok["index"], (prev_gym_lvl + lvl_increment).round
   				end
       		end

			#create gym trainers
			target_gym_viabilities[i]["gym_tr_ids"].each do |tr_id|
				range_low = (target_gym_viabilities[i]['range'][0] - 15) 
				range_high = (target_gym_viabilities[i]['range'][1] - 15) 
				lvl = gym_lvl - (rand(3) + 1)
				pok_count = (i == 0 ? 5 : 6)
				p "Randomizing gym #{i} trainers #{types[i]}"
				team = Randomizer.create_team [range_low, range_high], pok_count, [types[i]], lvl
				# Randomizer.apply_team team, tr_id, lvl
			end

			#create gym leader
			target_gym_viabilities[i]["tr_id"].each do |tr_id|
				
				range_low = (target_gym_viabilities[i]['range'][0]) 
				range_high = (target_gym_viabilities[i]['range'][1]) 

				pok_count = 6

				p "Randomizing gym #{i} leader #{types[i]}"
				team = Randomizer.create_team [range_low, range_high], pok_count, [types[i]], (gym_lvl)
				Randomizer.apply_team team, tr_id, gym_lvl 
			end
       	end

       	elite_4 = target_gym_viabilities[8]

       	# create elite 4
       	(1..4).each do |n|
       		tr_ids = elite_4["e#{n}"]

       		tr_ids.each do |tr_id|
       			range_low = elite_4["range"][0] 
   				range_high = elite_4["range"][1]
   				pok_count = 6
   				lvl = elite_4["lvl"]
   				begin
	   				team = Randomizer.create_team([range_low, range_high], pok_count, [types[n + 7]], lvl)
	   				Randomizer.apply_team team, tr_id, lvl
	   			rescue
	   				p "retrying"
	   				retry
	   			end
       		end
       	end

       	# create champion
       	tr_ids = elite_4["champ"]

       	tr_ids.each do |tr_id|
   			range_low = elite_4["range"][0] 
			range_high = elite_4["range"][1]
			pok_count = 6
			lvl = elite_4["lvl"]
			begin
				team = Randomizer.create_team [range_low, range_high], pok_count, "all", lvl
				Randomizer.apply_team team, tr_id, lvl
			rescue
				p "retrying"
				retry
			end
   		end


	end


	def self.rand_encs
		old_gym_caps = load_file('base_rom_level_caps') 
		target_gym_viabilities = load_file('gym_viabilities')
		gym_types = load_file('randomized_gym_types')

		all_types = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark"]

		headers = Header.get_all
		ai_advantage_low = 50 #adjusts how weak the low end of your encounters are compared to ai trainers
		ai_advantage_high = 50 #adjusts how weak the high end of your encounters are compared to ai trainers

		gym_ids = RomInfo.pokemon_center_headers[1]
		other_ids = [444,461,414,408] #flocessy, lentimas, lacunosa, undella
		
		encounter_count = Encounter.get_all.length

		gym_ids.each_with_index do |gym, i|
			p "randomizing gym #{i}"
			lvl = target_gym_viabilities[i]["lvl"] - 6
			range = target_gym_viabilities[i]["range"]
			range 

			rand_enc = Randomizer.create_encounter [range[0] - ai_advantage_low, range[1] - ai_advantage_high ], [1, lvl].max, [gym_types[i]]
			Randomizer.apply_encounter rand_enc, 136 + i
			
			headers[gym.to_s]["unknown_4"] = 192 
			headers[gym.to_s]["encounter_id"] = 136 + i			
		end

		remaining_types = all_types - gym_types

		other_ids.each_with_index do |city, i|

			headers[city.to_s]["unknown_4"] = 192
			headers[city.to_s]["encounter_id"] = 144 + i
			lvl = nil
			range = nil
			type = nil
			if i < 1
				lvl = target_gym_viabilities[0]["lvl"] - 6
				range = target_gym_viabilities[0]["range"]
				type = Randomizer.get_type_info([gym_types[0]] * 2)[0].sample
				p type
			else
				lvl = target_gym_viabilities[6]["lvl"] - 6
				range = target_gym_viabilities[6]["range"]
				type = remaining_types.shuffle!.pop
			end

			rand_enc = Randomizer.create_encounter [range[0] - ai_advantage_low, range[1] - ai_advantage_high], [1, lvl].max, [type]
			Randomizer.apply_encounter rand_enc, 144 + i
		end

		File.write("#{$rom_name}/json/headers/headers.json", JSON.pretty_generate(headers))

		(0..135).each do |n|
			p "randomizing enc file #{n}"
			lvl =  Encounter.get_max_level n
			next_gym_lvl = nil
			next_gym_range = nil

			target_gym_viabilities.each do |gym|
				if lvl <= gym['lvl']
					next_gym_lvl = gym['lvl']
					next_gym_range = gym['range']
					break
				end
			end

			next_gym_lvl = target_gym_viabilities[-1]['lvl'] if !next_gym_lvl
			next_gym_range = target_gym_viabilities[-1]['range'] if !next_gym_range

			rand_enc = Randomizer.create_encounter [next_gym_range[0] - ai_advantage_low, next_gym_range[1] - ai_advantage_high], [1, next_gym_lvl - 6].max

			Randomizer.apply_encounter rand_enc, n
		end
	end




	def self.load_file file_name
		JSON.parse(File.read("randomizer/#{file_name}.json"))
	end



end
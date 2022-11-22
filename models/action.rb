class Action

# skip 161,162,163

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

        blacklist = {}

        target_gym_viabilities[0..7].each do |gym|
        	(gym["tr_id"] + gym["gym_tr_ids"]).each do |n|
        		blacklist[n] = true
        	end
        end

        (target_gym_viabilities[8]["e1"] + target_gym_viabilities[8]["e2"] + target_gym_viabilities[8]["e3"] + target_gym_viabilities[8]["e4"] + target_gym_viabilities[8]["champ"] + rival1_tr_ids).each do |n|
        	blacklist[n] = true

       	end  
       	
       	p blacklist
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


		encounter_count = Encounter.get_all.length

		(0..encounter_count - 1).each do |n|
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

			p "lvl #{next_gym_lvl - 6}"
			p next_gym_range
			rand_enc = Randomizer.create_encounter [next_gym_range[0] - 30, next_gym_range[1] - 30], [1, next_gym_lvl - 6].max

			Randomizer.apply_encounter rand_enc, n
		end
	end



	def self.load_file file_name
		JSON.parse(File.read("randomizer/#{file_name}.json"))
	end



end
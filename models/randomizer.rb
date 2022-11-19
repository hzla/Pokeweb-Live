class Randomizer

	def self.create_personal
	 	data = Personal.poke_data
	 	data = add_evolution_data(data)
	 	File.write("randomizer/poks.json", JSON.pretty_generate(data))

	 	viabilities = []

	 	data.each do |pok|
	 		viability = {}
	 		
	 		if pok
		 		viability["name"] = pok["name"]
		 		viability["index"] = pok["index"]
		 		viability["via_player"] = 1.0

		 		viability["via_player"]
		 		viability["via_ai"] = 1.0
		 		(1..8).each do |n|
					viability["via_player_gym_#{n}"] = 1.0
				end

		 		#remove pokestudios
		 		if pok["name"].gsub(" ", "") == ""
		 			viability["via_player"] = 0
		 			viability["via_ai"] = 0
		 			(1..8).each do |n|
						viability["via_player_gym_#{n}"] = 0
					end
		 		end

		 		viability["types"] = [pok["type_1"], pok["type_2"]]
		 		bst_data = modified_bst(pok)
		 		viability["modified_bst"] = bst_data[0]
		 		viability["modified_bst_physical"] = bst_data[1]
		 		viability["modified_bst_special"] = bst_data[2]
		 		viability["can_be_mixed"] = bst_data[3]
		 		viabilities << viability
		 	end
	 	end

	 	File.write("randomizer/pok_viabilities.json", JSON.pretty_generate(viabilities))
	 	
	end

	def self.create_abilities
		abilities = {}
		File.readlines('randomizer/abilities.txt').each do |line|
			abilities[line.gsub("\n", "")] = {"via_player": 1.0, "via_ai":1.0}
		end
		File.write("randomizer/ability_viabilities.json", JSON.pretty_generate(abilities))
	end

	def self.create_moves
		moves = Move.get_all
		moves.each_with_index do |move, i|
			moves[i][1]["viability"] = 1.0 
		end
		File.write("randomizer/move_viabilities.json", JSON.pretty_generate(moves))
	end



	def self.create_team v_range, pok_count, types="all"
		poks = []
		main_pool = ai_viability_pool(v_range, types)
		File.write("randomizer/pool.json", JSON.pretty_generate(main_pool))

		p main_pool.map {|n| n["name"]}
		#choose lead pok from main pool
		lead_pok = main_pool.shuffle!.pop
		poks << lead_pok

		lead_types = lead_pok["types"]
		type_info = get_type_info lead_types

		#get list of types that are SE against types that are SE against lead pok
		complentary_types = type_info[1] 


		until poks.uniq.length == pok_count
			if types == "all"
				#get a complementary typed pokemon from all pokemon
				# p complentary_types
				next_pool = ai_viability_pool(v_range, complentary_types)
			else
				#get a comp type pokemon from the main pool
				# complentary_types = [complentary_types.shuffle.pop]
				blacklist = poks.map do |pok|
					pok["index"]
				end
				next_pool = ai_viability_subpool(main_pool, complentary_types, blacklist)
			end

			next_pok = next_pool.shuffle!.pop

			#if no pokemon could be found, choose another random pokemon from main pool
			if !next_pok
				p "could not find complimentary"
				next_pok = main_pool.shuffle!.pop 
	
			end
			
			poks << next_pok

			next_type_info = get_type_info(next_pok["types"]) 
			complentary_types = [next_type_info[1].shuffle.pop]

		end
		File.write("randomizer/team.json", JSON.pretty_generate(poks))
		poks
		# poks.map {|n| n["name"]}
	end

	def self.ai_viability_subpool pool, types, blacklist=nil
		subpool = []
		pool.each do |pok|
			
			pok["types"].each do |type|
				if types.include?(type) && !blacklist.include?(pok["index"])
					subpool << pok
					break
				end
			end
		end
		subpool
	end


	def self.load_file file_name
		JSON.parse(File.read("randomizer/#{file_name}.json"))
	end



	def self.create_moveset pok, target_viability, lvl, move_category
		all_poks = load_file('poks')
		
		# calculate how much damage an offensive move should have
		
		target_bp = (0.571429 * lvl + 54.2857).floor
		bst_importance_skew = 100 # how important bst is at low levels vs high
		bst_importance = 0.5 # how much bst difference should affect move bp difference

		move_bp_modifier = 1 - (((pok["modified_bst_#{move_category}"] - bst_importance_skew) - (target_viability - bst_importance_skew)) / (pok["modified_bst_#{move_category}"] - bst_importance_skew)).to_f * bst_importance
		#poks offensive moves should be around this bp
		pok_target_bp = move_bp_modifier * target_bp



		types = pok["types"]
		all_moves = load_file('move_viabilities') 
		pok = all_poks[pok["index"]] #expand pok data
		learnset_moves = []
		learnset_data = pok["learnset"]
		

		#get learnset status moves
		(0..24).each do |n|
			if learnset_data["move_id_#{n}_index"]
				move = all_moves[learnset_data["move_id_#{n}_index"]][1]
				if move["category"] == "Status"
					learnset_moves << all_moves[learnset_data["move_id_#{n}_index"]]
				end
			else
				break
			end
		end

		#get tm status moves
		# all_tms = Tm.get_data["raw"]
		# learnset_tm_list = Personal.get_tm_list pok

		# learnset_tm_list[:tms].each_with_index do |tm, i|
		# 	if tm == 1
		# 		tm_data = all_moves[all_tms[i]][1]
		# 		learnset_moves << tm_data
		# 	end
		# end

		learnset_moves = learnset_moves.last(2)
		p (learnset_moves.map{|n| n[1]["name"]})


		#create move pool of offensive stab moves within accetable bp range
		stab_movepool = []
		all_moves.select do |move|
			move = move[1]
			stab = types.include?(move["type"])
			category_match = (move["category"].downcase == move_category.downcase)
			bp_in_range = (move["power"] > (pok_target_bp - 10)) && (move["power"] < (pok_target_bp + 10))
		
			if stab && category_match && bp_in_range
				stab_movepool << move 

			end
		end

		#create move pool of coverage moves with complimentary types
		complimentary_types = get_type_info(types)[1].uniq
		coverage_movepool = []
		all_moves.select do |move|
			move = move[1]
			coverage = complimentary_types.include?(move["type"])
			category_match = (move["category"].downcase == move_category.downcase)
			bp_in_range = (move["power"] > (pok_target_bp - 10)) && (move["power"] < (pok_target_bp + 10))
		
			if coverage && category_match && bp_in_range
				coverage_movepool << move 
			end
		end

		moveset = []
		# STEP 1: Choose a stab move
		stab_move1 = stab_movepool.shuffle!.pop 
		stab_move1_type = stab_move1["type"]
		moveset << stab_move1
		p "stab 1 added"
		empty_stab = false

		# STEP 2: 60% chance to choose a second stab move if there is a 2nd type 
		remaining_types = types.uniq
		remaining_types.delete stab_move1["type"]
		if remaining_types
			empty_stab = true
			if rand(100) > 60
				stab_move2_type = nil
				stab_move2 = nil
				until stab_move2_type == remaining_types[0] || stab_movepool.empty?
					stab_move2 = stab_movepool.shuffle!.pop
					stab_move2_type = stab_move2["type"] 

				end
				if stab_move2
					moveset << stab_move2 
					empty_stab = false
					p "stabmove 2 added"
				end

			end
		end

		# STEP 3: 50% chance to choose a late status move from learnset 

		if rand(100) > 50
			if learnset_moves
				moveset << learnset_moves.shuffle!.pop[1]
				p "status 1 added"
			end
		end

		# STEP 4: 50% second status move / 50% coverage move
		cov_move_1 = nil
		cov_move_1_type = nil
		if rand(100) > 50
			if learnset_moves
				moveset << learnset_moves.last[1]
				p "status 2 added"
			end

		else
			cov_move_1 = coverage_movepool.shuffle!.pop
			cov_move_1_type = cov_move_1["type"]
			moveset << coverage_movepool.shuffle!.pop
			p "cov 1 added"
		end


		# STEP 5: if still room 50% coverage move / 50% 2nd stab move if second type 

		if moveset.length < 4
			if rand(100) > 80 && empty_stab
				stab_move2_type = nil
				stab_move2 = nil
				until stab_move2_type == remaining_types[0] || stab_movepool.empty?
					stab_move2 = stab_movepool.shuffle!.pop
					stab_move2_type = stab_move2["type"] 
					p "stab 2 added"
				end

			else
				moveset << coverage_movepool.shuffle!.pop
				p "cov 2 added"
			end
		end

		# Step 6: coverage move if still room

		if moveset.length < 4
			moveset << coverage_movepool.shuffle!.pop
			p "cov 3 added"
		end


		p moveset.map {|n| n["name"]}


	end

	 # a = Randomizer.create_team([320,440],6,["Fire","Rock"])[-1]
	 # Randomizer.create_moveset a, 400, 40, "physical"


	def self.ai_viability_pool v_range, types="all", blacklist=nil
		poks = load_file('pok_viabilities')
		pool = []
		poks.each do |pok|
			correct_type = true
			
			#check if correct type
			if types != "all"
				correct_type = false
				pok["types"].each do |type|
					if types.include?(type)
						correct_type = true
						break
					end
				end
				next if !correct_type
			end

			#check if in viability range
			
			range_data = in_v_range?(v_range, pok)
			if range_data[0] || range_data[1]
				pok["physical_ok"] = range_data[0]
				pok["special_ok"] = range_data[1]
				pool << pok
			end
		end
		pool
	end


	def self.in_v_range? v_range,pok
		range_data = []
		
		if pok["modified_bst_physical"] * pok["via_ai"] >= v_range[0] && pok["modified_bst_physical"] * pok["via_ai"] <= v_range[1]
			range_data[0] = true
		end

		if pok["modified_bst_special"] * pok["via_ai"] >= v_range[0] && pok["modified_bst_special"] * pok["via_ai"] <= v_range[1]
			range_data[1] = true
		end
		range_data
	end

	def self.modified_bst pok

		return 0 if !pok || !pok["base_hp"]

		bst = pok["base_hp"] + pok["base_speed"] * 1.2 + pok["base_def"] * 0.8 + pok["base_spdef"] * 0.8 
		offense = 0
		can_be_mixed = false
		if ((( pok["base_spatk"] - (pok["base_spatk"] - pok["base_atk"]).abs) / pok["base_spatk"].to_f) > 0.8)
			can_be_mixed = true
			offense = (pok["base_spatk"] + pok["base_atk"]) / 2
		else
			offense = [pok["base_spatk"], pok["base_atk"]].max
		end

		bst_physical = bst + pok["base_atk"]
		bst_special = bst + pok["base_spatk"]

		[bst + offense, bst_physical, bst_special, can_be_mixed]
	end

	def self.add_evolution_data poke_data
		lvl_evo_method_ids = [4,9,10,11,12,13,14,15,23,24]
		evo_at = nil
		evo_target = nil
		Evolution.get_all(true).each_with_index do |evo, i|
			(0..6).each do |n|
				if lvl_evo_method_ids.include?(evo["method_#{n}"])
					evo_at = evo["param_#{n}"]
					evo_target = evo["target_#{n}"]
					poke_data[i]["evo_at"] = evo_at
					poke_data[i]["evo_target"] = evo_target
				else
				end
			end
		end
		poke_data
	end


	def self.get_type_info pok_types
		pok_types[1] = "None" if pok_types[1] == pok_types[0]

		type_name = ["Normal", "Fire", "Water", "Electric", "Grass", "Ice",
             "Fighting", "Poison", "Ground", "Flying", "Psychic",
             "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy","None"]

    	result = []
		types = [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0.5, 0, 1, 1, 0.5, 1,1],
                    [1, 0.5, 0.5, 1, 2, 2, 1, 1, 1, 1, 1, 2, 0.5, 1, 0.5, 1, 2, 1,1],
                    [1, 2, 0.5, 1, 0.5, 1, 1, 1, 2, 1, 1, 1, 2, 1, 0.5, 1, 1, 1,1],
                    [1, 1, 2, 0.5, 0.5, 1, 1, 1, 0, 2, 1, 1, 1, 1, 0.5, 1, 1, 1,1],
                    [1, 0.5, 2, 1, 0.5, 1, 1, 0.5, 2, 0.5, 1, 0.5, 2, 1, 0.5, 1, 0.5, 1,1],
                    [1, 0.5, 0.5, 1, 2, 0.5, 1, 1, 2, 2, 1, 1, 1, 1, 2, 1, 0.5, 1,1],
                    [2, 1, 1, 1, 1, 2, 1, 0.5, 1, 0.5, 0.5, 0.5, 2, 0, 1, 2, 2, 0.5,1],
                    [1, 1, 1, 1, 2, 1, 1, 0.5, 0.5, 1, 1, 1, 0.5, 0.5, 1, 1, 0, 2,1],
                    [1, 2, 1, 2, 0.5, 1, 1, 2, 1, 0, 1, 0.5, 2, 1, 1, 1, 2, 1,1],
                    [1, 1, 1, 0.5, 2, 1, 2, 1, 1, 1, 1, 2, 0.5, 1, 1, 1, 0.5, 1,1],
                    [1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 0.5, 1, 1, 1, 1, 0, 0.5, 1,1],
                    [1, 0.5, 1, 1, 2, 1, 0.5, 0.5, 1, 0.5, 2, 1, 1, 0.5, 1, 2, 0.5, 0.5,1],
                    [1, 2, 1, 1, 1, 2, 0.5, 1, 0.5, 2, 1, 2, 1, 1, 1, 1, 0.5, 1,1],
                    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1, 0.5, 1, 1,1],
                    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 0.5, 0,1],
                    [1, 1, 1, 1, 1, 1, 0.5, 1, 1, 1, 2, 1, 1, 2, 1, 0.5, 1, 0.5,1],
                    [1, 0.5, 0.5, 0.5, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 0.5, 2,1],
                    [1, 0.5, 1, 1, 1, 1, 2, 0.5, 1, 1, 1, 1, 1, 1, 2, 2, 0.5, 1,1],
                	[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]]

        type1 = type_name.index(pok_types[0])
        type2 = type_name.index(pok_types[1])

        (0..17).each do |i|
        	result[i] = types[i][type1] * types[i][type2]
        end

        weak_to = []

        result.each_with_index do |n, i|
        	if n > 1
        		weak_to << type_name[i]
        	end
        end

        complentary_types = []

        weak_to.each do |weakness|
        	damages = types.transpose[type_name.index(weakness)]
        	damages.each_with_index do |typing, i|
        		if typing > 1
        			complentary_types << type_name[i]
        		end
        	end 
        end

        [weak_to, complentary_types]
	end
end




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
		main_pool = create_ai_viability_pool(v_range, types)
		File.write("randomizer/pool.json", JSON.pretty_generate(main_pool))
		#choose lead pok from main pool
		lead_pok = main_pool.shuffle!.pop
		poks << lead_pok

		lead_types = lead_pok["types"]
		type_info = get_type_info lead_types

		#get list of types that are SE against types that are SE against lead pok
		complentary_types = type_info[1] 


		until poks.length == pok_count
			if types == "all"
				#get a complementary typed pokemon from all pokemon
				# p complentary_types
				next_pool = create_ai_viability_pool(v_range, complentary_types)
			else
				#get a comp type pokemon from the main pool
				# complentary_types = [complentary_types.shuffle.pop]
				next_pool = create_ai_viability_subpool(main_pool, complentary_types)
			end

			next_pok = next_pool.shuffle!.pop

			#if no pokemon could be found, choose another random pokemon from main pool
			if !next_pok
				next_pok = main_pool.shuffle!.pop 
	
			end
			
			poks << next_pok

			next_type_info = get_type_info(next_pok["types"]) 
			complentary_types = [next_type_info[1].shuffle.pop]

		end
		File.write("randomizer/team.json", JSON.pretty_generate(poks))
		poks
	end

	def self.create_ai_viability_subpool pool, types
		subpool = []
		pool.each do |pok|
			
			pok["types"].each do |type|
				if types.include?(type)
					subpool << pok
					break
				end
			end
		end
		subpool
	end


	def self.create_moveset pok, v_range, lvl
		target_bps = {0 => 50, 20 => 60, 30 => 65, 40 => 70, 50 => 80, 60 => 90 }
		target_bp = target_bps[lvl.round(-1)]

		#look th 
	end


	def self.create_ai_viability_pool v_range, types="all"
		poks = JSON.parse(File.read('randomizer/pok_viabilities.json'))
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




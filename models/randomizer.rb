class Randomizer


	def self.setup
		create_personal
		create_abilities
		create_moves
		update_move_ban_list
		smogon_indexed_moves
		create_items
		p "Setup Successful"
	end

	def self.update_move_ban_list
		moves = load_file "move_viabilities"
		File.readlines('randomizer/ai_move_banlist.txt').each do |line|
		    move_id = line.split(" ")[0].to_i
		    moves[move_id][1]["viability"] = 0
		end
		File.write("randomizer/move_viabilities.json", JSON.pretty_generate(moves))
		smogon_indexed_moves
		p "updated move ban list"

	end

	def self.create_personal
	 	data = Personal.poke_data
	 	File.write("randomizer/poks.json", JSON.pretty_generate(data))
	 	data = add_evolution_data(data)
	 	File.write("randomizer/poks.json", JSON.pretty_generate(data))

	 	via_info = load_file('pokedex')

	 	viabilities = []

	 	data.each_with_index do |pok, i|
	 		viability = {}
	 		if pok
		 		viability["name"] = pok["name"]
		 		
		 		viability["index"] = pok["index"]

		 		
		 		if via_info[i]
			 		viability["via_player"] = via_info[i]["via_player"]
			 		viability["via_ai"] = via_info[i]["via_ai"]
			 	else
			 		viability["via_player"] = 0
			 		viability["via_ai"] = 0
			 	end


		 		viability["form"] = 0


		 	# 	(1..8).each do |n|
				# 	viability["via_player_gym_#{n}"] = 1.0
				# end



		 		#remove pokestudios
		 		if pok["name"].gsub(" ", "") == "" || pok["name"].split(" ").last.downcase == "egg"
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

	 	

	 	indexed = {}
	 	viabilities.each do |v|
	 		indexed[v["name"]] = v
	 	end

	 	File.write("randomizer/name_indexed_pok_viabilities.json", JSON.pretty_generate(indexed))
	 	viabilities = add_form_data(viabilities)	

	 	File.write("randomizer/pok_viabilities.json", JSON.pretty_generate(viabilities))
	end


	def self.add_form_data poks
		name_indexed_forms = load_file('name_indexed_pok_viabilities')
		first_form_index = 685
		form_counts = {}
		forms =	["Deoxys-Attack",
			"Deoxys-Defense",
			"Deoxys-Speed",
			"Wormadam-Sandy",
			"Wormadam-Trash",
			"Shaymin-Sky"	,
			"Giratina-Origin",
			"Rotom-Heat",
			"Rotom-Wash",
			"Rotom-Frost",
			"Rotom-Fan",
			"Rotom-Mow",
			"Castform-Sunny",
			"Castform-Rainy",
			"Castform-Snowy",
			"Basculin-Blue-Striped",
			"Darmanitan-Zen",
			"Meloetta-Pirouette",
			"Kyurem-White",
			"Kyurem-Black",
			"Keldeo-Resolute",
			"Tornadus-Therian",
			"Thundurus-Therian",
			"Landorus-Therian"]

		(first_form_index..first_form_index + 23).each do |n|
			form_name = forms[n - first_form_index]
			base_form_name = form_name.split("-", 2)[0].upcase
			
			base_pok = name_indexed_forms[base_form_name]


			pok = name_indexed_forms[form_name]

			poks[n]["base_form"] = base_pok["index"]

			if form_counts[base_form_name]
				form_counts[base_form_name] += 1
			else
				form_counts[base_form_name] = 1
			end

			poks[n]["form_index"] = form_counts[base_form_name]
		end

		poks
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

	def self.smogon_indexed_moves
		moves = load_file('move_viabilities')
		indexed = {}
		moves.each_with_index do |move, i|
			smogon_id = move[1]["name"].smogonlize
			indexed[smogon_id] = move[1]
		end
		File.write("randomizer/smogon_indexed_move_viabilities.json", JSON.pretty_generate(indexed))
		indexed
	end

	def self.create_items
		items = Item.get_all
		items[0]["name"] = "nothing"
		indexed = {}
		items.each_with_index do |item, i|
			smogon_id = item["name"].smogonlize
			item["index"] = i
			indexed[smogon_id] = item
		end
		File.write("randomizer/smogon_indexed_item_viabilities.json", JSON.pretty_generate(indexed))
	end

	def self.get_trainer_item pok, smogon=true
		default_pool = ["Sitrus Berry", "Bright Powder", "Choice Scarf", "Eject Button", "Expert Belt", "Focus Sash", "Focus Band", "King's Rock", "Leftovers", "Life Orb",	"Quick Claw", "Razor Claw", "Rocky Helmet" ]
		species = pok["name"].name_titleize
		item = nil

		if smogon && (rand(100) > 10)
			smogon_data = load_file('smogon')['data'][species]
			if smogon_data
				smogon_items = smogon_data["Items"]

				#sometimes use default pool if smogon doesn't have enough variety
				if smogon_items.to_a.length < 3
					if rand(100) < 50
						item = default_pool.shuffle.pop.smogonlize
					else
						item = weighted_rand(smogon_items) 
					end
				else
					item = weighted_rand(smogon_items) 
				end
			else
				item = default_pool.shuffle.pop.smogonlize
			end
		else
			default_pool.shuffle.pop.smogonlize
		end
		item
	end


	def self.weighted_rand options
		total = 0
		expanded_options = options.to_a
		options.to_a.each_with_index do |option, i|
			# return option
			expanded_options[i][2] = total * 100
			total += (option[1].round(2) * 100).to_i
		end
		rand_number = rand(total * 100)

		chosen = nil
		expanded_options.reverse.each do |option|
			if rand_number > option[2]
				chosen = option[0]
				break
			end
		end
		chosen
	end



	def self.create_team v_range, pok_count, types="all", lvl=50
		poks = []
		# types = ["Normal", "Fire", "Water", "Electric", "Grass", "Ice",
  #            "Fighting", "Poison", "Ground", "Flying", "Psychic",
  #            "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"] if types == "all"
		
		#cache old pools
		key = (v_range.map(&:to_s) + [types]).flatten.join("")

		main_pool = nil
		if $last_used_pool[key]
			main_pool = $last_used_pool[key]
		else
			main_pool = ai_viability_pool(v_range, types)
		end
		$last_used_pool = {}
		$last_used_pool[key] = main_pool

		File.write("randomizer/pool.json", JSON.pretty_generate(main_pool))

		until main_pool.length > 5
			v_range[0] -= 20 
			main_pool = ai_viability_pool(v_range, types)
		end


		#choose lead pok from main pool
		lead_pok = main_pool.shuffle!.pop
		poks << lead_pok

		lead_types = nil
		type_info = nil
		begin
			lead_types = lead_pok["types"]
			type_info = get_type_info lead_types
		rescue
			binding.pry
		end

		#get list of types that are SE against types that are SE against lead pok
		complentary_types = type_info[1] 


		until poks.length == pok_count
			if types == "all"
				#get a complementary typed pokemon from all pokemon
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
				next_pok = main_pool.shuffle!.pop 
	
			end

			# if main pool is still empty, expand to all types
			if !next_pok
				types = ["Normal", "Fire", "Water", "Electric", "Grass", "Ice",
             "Fighting", "Poison", "Ground", "Flying", "Psychic",
             "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel", "Fairy"]
            	 main_pool = ai_viability_pool(v_range, types)
				next_pok = main_pool.shuffle!.pop 
	
			end
			
			poks << next_pok

			begin
				next_type_info = get_type_info(next_pok["types"]) 
			rescue
				binding.pry
			end
			complentary_types = [next_type_info[1].sample]

		end

		poks.each_with_index do |pok, i|
			poks[i]["item"] = get_trainer_item(pok)
			target_viability = (v_range[0] + v_range[1]) / 2

			move_cats = []
			move_cats << "Special" if pok["special_ok"]
			move_cats << "Physical" if pok["physical_ok"]
			category = move_cats.shuffle.pop

			poks[i]["moves"] = create_moveset(pok, target_viability, lvl, category )
		end

		# File.write("randomizer/team.json", JSON.pretty_generate(poks))
		"output to randomizer/team.json"

		poks
	end

	# team = Randomizer.create_team [370,375], 2, ["Water","Fire"], 21
	# Randomizer.apply_team(team, 157, 21)

	def self.apply_team poks, tr_id, lvl 
		trdata = JSON.parse(File.read(("#{$rom_name}/json/trdata/#{tr_id}.json")))
		trpok =  JSON.parse(File.read(("#{$rom_name}/json/trpok/#{tr_id}.json")))
		items = load_file('smogon_indexed_item_viabilities')
		readable = apply_team_readable poks, tr_id, lvl, trdata, trpok, items
		raw = apply_team_raw poks, tr_id, lvl, trdata, trpok, items

		trdata["readable"] = readable[0]
		trdata["raw"] = raw[0]

		trpok["readable"] = readable[1]
		trpok["raw"] = raw[1]

		File.open("#{$rom_name}/json/trdata/#{tr_id}.json", "w") { |f| f.write trdata.to_json }
		File.open("#{$rom_name}/json/trpok/#{tr_id}.json", "w") { |f| f.write trpok.to_json }
	end


	def self.apply_team_readable poks, tr_id, lvl, trdata, trpok, items
		trdata = trdata["readable"]
		trpok =  trpok["readable"]
		items = load_file('smogon_indexed_item_viabilities')
		# turn moves, items, expert ai on
		
		trdata["template"] = 3
		trdata["has_items"] = 1
		trdata["has_moves"] = 1
		trdata["Prioritize Effectiveness"] = 1
		trdata["Evaluate Attacks"] = 1
		trdata["Expert"] = 1
		trdata["ai"] = trdata["Double Battle"] == 1 ? 135 : 7

		#wipe old data
		trpok.each do |field, value|
			if field.split("_")[-1].is_integer?
				trpok.delete field
			end
		end

		#add new team
		poks.each_with_index do |pok, i|
			trpok["ivs_#{i}"] = 255
			trpok["ability_#{i}"] = rand(3)
			trpok["level_#{i}"] = lvl
			trpok["padding_#{i}"] = 0

			if pok["base_form"]
				trpok["species_id_#{i}"] = pok["name"].split("-", 2)[0].upcase
				trpok["form_#{i}"] = pok["form_index"]
			else
				trpok["species_id_#{i}"] = pok["name"]
				trpok["form_#{i}"] = 0
			end


			
			trpok["gender_#{i}"] = "Default"

			

			if pok["item"]
				trpok["item_id_#{i}"] = items[pok["item"]]["name"] 
			else
				trpok["item_id_#{i}"] = "Sitrus Berry"
			end

			(1..(pok["moves"].length)).each do |m|
				trpok["move_#{m}_#{i}"] = pok["moves"][m - 1][0]
			end
		end

		trpok["count"] = poks.length
		trdata["num_pokemon"] = poks.length

		[trdata, trpok]

		
 	end

 	def self.apply_team_raw poks, tr_id, lvl, trdata, trpok, items
		trdata = trdata["raw"]
		all_trpok = trpok
		trpok =  trpok["raw"]

		items = load_file('smogon_indexed_item_viabilities')
		# turn moves, items, expert ai on
		
		trdata["template"] = 3
		trdata["has_items"] = 1
		trdata["has_moves"] = 1
		trdata["Prioritize Effectiveness"] = 1
		trdata["Evaluate Attacks"] = 1
		trdata["Expert"] = 1
		trdata["ai"] = trdata["Double Battle"] == 1 ? 135 : 7

		#wipe old data
		trpok.each do |field, value|
			if field.split("_")[-1].is_integer?
				trpok.delete field
			end
		end

		#add new team
		poks.each_with_index do |pok, i|
			trpok["ivs_#{i}"] = 255
			trpok["ability_#{i}"] = rand(3) * 16
			trpok["level_#{i}"] = lvl
			trpok["padding_#{i}"] = 0
			if pok["base_form"]
				trpok["species_id_#{i}"] = pok["base_form"]
				trpok["form_#{i}"] = pok["form_index"]
			else
				trpok["species_id_#{i}"] = pok["index"]
				trpok["form_#{i}"] = 0
			end

			if pok["item"]
				trpok["item_id_#{i}"] = items[pok["item"]]["index"] 
			else
				trpok["item_id_#{i}"] = 158
			end

			(1..(pok["moves"].length )).each do |m|
				trpok["move_#{m}_#{i}"] = pok["moves"][m - 1][1]
			end
		end
		trpok["count"] = poks.length
		trdata["num_pokemon"] = poks.length

		[trdata, trpok]

		
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

		move_bp_modifier = 1 - (((pok["modified_bst_#{move_category.downcase}"] - bst_importance_skew) - (target_viability - bst_importance_skew)) / (pok["modified_bst_#{move_category.downcase}"] - bst_importance_skew)).to_f * bst_importance
		#poks offensive moves should be around this bp
		pok_target_bp = move_bp_modifier * target_bp



		types = pok["types"]
		all_moves = load_file('move_viabilities') 
		pok = all_poks[pok["index"]] #expand pok data
		learnset_moves = []
		learnset_data = pok["learnset"]
		
		# return all_moves.sample(4).map {|n| [n[1]["name"], n[1]["index"]]}

		#get learnset status moves
		(0..24).each do |n|
			if learnset_data["move_id_#{n}_index"]
				move = all_moves[learnset_data["move_id_#{n}_index"]][1]
				if move["category"] == "Status" && move["viability"] > 0
					
					#dont let physical/special sets use stat raising moves for the wrong stat			
					if move["magnitude_1"] > 0
						if move_category.downcase == "special" 
							next if move["stat_1"] == "Attack"
						else
							next if move["stat_1"] == "Special Attack"
						end
					end
					
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
		all_learnset_moves = learnset_moves
		learnset_moves = learnset_moves.last(2)

		#create move pool of offensive stab moves within accetable bp range
		stab_movepool = []
		all_moves.select do |move|
			move = move[1]
			stab = types.include?(move["type"])
			category_match = (move["category"].downcase == move_category.downcase)
			bp_in_range = (move["power"] > (pok_target_bp - 20)) && (move["power"] < (pok_target_bp + 20))

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
		
		if stab_move1

			stab_move1_type = stab_move1["type"]
			moveset << stab_move1
			
		end
		empty_stab = false

		# STEP 2: 60% chance to choose a second stab move if there is a 2nd type 
		remaining_types = types.uniq
		remaining_types.delete stab_move1["type"] if stab_move1
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
				end

			end
		end

		# STEP 3: 50% chance to choose a late status move from learnset 

		if rand(100) > 50
			if learnset_moves
				ls_move = learnset_moves.shuffle!.pop
				
				moveset << ls_move[1] if ls_move
			end
		end

		# STEP 4: 50% second status move / 50% coverage move
		cov_move_1 = nil
		cov_move_1_type = nil
		if rand(100) > 50
			if learnset_moves && learnset_moves.last
				moveset << learnset_moves.last[1]
			end

		else
			
			cov_move_1 = coverage_movepool.shuffle!.pop
			
			if cov_move_1
				cov_move_1_type = cov_move_1["type"]
				moveset << cov_move_1
			else
				moveset << stab_movepool.shuffle!.pop
			end
		end


		# STEP 5: if still room 50% coverage move / 50% 2nd stab move if second type 

		if moveset.length < 4
			if rand(100) > 80 && empty_stab
				stab_move2_type = nil
				stab_move2 = nil
				until stab_move2_type == remaining_types[0] || stab_movepool.empty?
					
					stab_move2 = stab_movepool.shuffle!.pop
					stab_move2_type = stab_move2["type"] 
				end

			else
				moveset << coverage_movepool.shuffle!.pop
			end
		end

		# Step 6: coverage move if still room

		if moveset.length < 4
			moveset << coverage_movepool.shuffle!.pop
		end

		

		# Step 7: coverage move if still room
		until moveset.length == 4 || coverage_movepool.empty?
			moveset << coverage_movepool.shuffle!.pop
		end

		# Step 8: status move from complete learnset pool if room
		if moveset.length < 4
			moveset << all_learnset_moves.shuffle!.pop[1]
		end

		moveset = moveset.compact
		begin 
			moveset.map {|n| [n["name"], n["index"]]}
		rescue
			binding.pry
		end


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

	def self.in_enc_v_range? v_range, pok
		in_range = false
		
		begin
			if pok["modified_bst"] * pok["via_player"] >= v_range[0] && pok["modified_bst"] * pok["via_player"] <= v_range[1]
				in_range = true
			end
		rescue
			binding.pry
		end
		in_range
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
		poks = load_file('poks')
		Evolution.get_all(true).each_with_index do |evo, i|
			(0..6).each do |n|
				if lvl_evo_method_ids.include?(evo["method_#{n}"])
					evo_at = evo["param_#{n}"]
					evo_target = evo["target_#{n}"]
					poke_data[i]["evo_at"] = evo_at
					poke_data[i]["evo_target"] = evo_target
					poke_data[i]["evo_modified_bst"] = modified_bst(poks[evo_target])[0]
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



	def self.encounter_pool v_range, lvl, types
		poks = load_file('pok_viabilities')
		expanded_poks = load_file('poks')
		pool = []

		#apply bst changes from evos to 

		expanded_poks.each_with_index do |pok, i|
			break if !pok
			if pok["evo_at"] && pok["evo_at"] <= lvl
				next_pok = expanded_poks[pok["evo_target"]]
				if next_pok["evo_at"] && next_pok["evo_at"] <= lvl
					poks[i]["modified_bst"] = expanded_poks[pok["evo_target"]]["evo_modified_bst"]
				else
					poks[i]["modified_bst"] = expanded_poks[i]["evo_modified_bst"]
				end
			else
			end
		end


		
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
			in_range = in_enc_v_range?(v_range, pok)
			if in_range 
				pool << pok
			end
		end
		pool.sort_by {|pok| pok["modified_bst"]}
	end


	def self.create_encounter v_range, lvl, types="all"
		pool = encounter_pool(v_range, lvl, types)
		count = pool.length
		encounters = {}

		upper_pool = pool[(count / 5 * 4)..-1]
		mid_pool = pool[(count / 5)...(count/5 * 4)]
		low_pool = pool[0...(count / 5)]

		encounters["upper"] = upper_pool.sample(6)
		encounters["mid"] = mid_pool.sample(12)
		encounters["low"] = low_pool.sample(6)
		encounters["lvl"] = lvl

		File.write("randomizer/encounter.json", JSON.pretty_generate(encounters))
		"output to randomizer/encounter.json"
		encounters
	end

	def self.create_gym_types
		["Normal", "Fire", "Water", "Electric", "Grass", "Ice",
             "Fighting", "Poison", "Ground", "Flying", "Psychic",
             "Bug", "Rock", "Ghost", "Dragon", "Dark", "Steel"].sample(8)
	end


	def self.apply_encounter encounters, enc_id
		enc_data = JSON.parse(File.read(("#{$rom_name}/json/encounters/#{enc_id}.json")))
		lvl = encounters["lvl"]
		lvls = [lvl] * 6 + [lvl + 1] * 4 + [lvl + 2] * 2
		water_lvls = [lvl] * 2 + [lvl+1] + [lvl+2]
		["spring", "summer", "fall", "winter"].each do |season|
			['grass', 'grass_doubles', 'grass_special'].each do |enc_type| 

				(0..5).each do |n|
					pool_index = n
					pool_index += 6 if enc_type == 'grass_special'
					encounter = encounters["mid"][pool_index]
					if !encounter
						encounter = encounters["mid"].sample
					end

					if encounter['base_form']

						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name'].split("-", 2)[0].upcase
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']
					else
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['index']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = 0

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name']
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = 0
					end

					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

				end

				[6,8,10].each do |n|
					pool_index = (n - 6) / 2
					pool_index += 3 if enc_type == 'grass_special'
					encounter = encounters["low"][pool_index]
					if !encounter
						encounter = encounters["low"].sample
					end

					if encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name'].split("-", 2)[0].upcase
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']
					else
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['index']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = 0

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name']
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = 0
					end

					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]
				end

				[7,9,11].each do |n|
					pool_index = (n - 7) / 2
					pool_index += 3 if enc_type == 'grass_special'
					encounter = encounters["upper"][pool_index]
					if !encounter
						encounter = encounters["upper"].sample
					end

					if encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name'].split("-", 2)[0].upcase
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']
					else
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['index']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = 0

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name']
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = 0
					end

					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]					
				end
			end

			["surf", "surf_special", "super_rod", "super_rod_special"].each do |enc_type|
				(0..1).each do |n|
					pool_index = n
					pool_index += 2 if enc_type.split("_") == 'special'
					encounter = encounters["mid"][pool_index]
					if !encounter
						encounter = encounters["mid"].sample
					end

					if encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name'].split("-", 2)[0].upcase
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']
					else
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['index']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = 0

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name']
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = 0
					end

					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

				end

				[2,4].each do |n|
					pool_index = (n - 2) / 2
					pool_index += 2 if enc_type.split("_") == 'special'
					encounter = encounters["low"][pool_index]
					if !encounter
						encounter = encounters["low"].sample
					end

					if encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name'].split("-", 2)[0].upcase
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']
					else
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['index']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = 0

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name']
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = 0
					end

					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]
				end

				[3].each do |n|
					pool_index = (n - 3) / 2
					pool_index += 2 if enc_type.split("_") == 'special'
					encounter = encounters["upper"][pool_index]
					if !encounter
						encounter = encounters["upper"].sample
					end

					if encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['base_form']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name'].split("-", 2)[0].upcase
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = encounter['form_index']
					else
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}"] = encounter['index']
						enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_form"] = 0

						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}"] = encounter['name']
						enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_form"] = 0
					end

					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['raw']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]

					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_min_level"] = lvls[n]
					enc_data['readable']["#{season}_#{enc_type}_slot_#{n}_max_level"] = lvls[n]					
				end
			end
		end


		File.open("#{$rom_name}/json/encounters/#{enc_id}.json", "w") { |f| f.write enc_data.to_json }
		"200 OK"
	end
end

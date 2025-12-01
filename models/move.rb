require 'json'
class Move < Pokenarc

	def self.get_all directory=nil
		moves = {}
		directory = $rom_name if !directory
		Dir["#{directory}/json/moves/*.json"].each do |move|

			all = JSON.parse(File.open(move, "r"){|f| f.read})
			move_data = all["readable"]


			move_data["effect_code"] = all["raw"]["effect"]
			move_id = move_data["index"]

			moves[move_id] = move_data
		end
		moves = moves.to_a.sort_by {|mov| mov[0] }
		
		# if RomInfo.original_move_count && RomInfo.original_move_count < moves.length
		# 	num_moves = RomInfo.original_move_count - 1
		# 	moves = moves[0..900]
		# end
		moves
	end

	def self.effects
		JSON.parse(File.open("#{$rom_name}/json/arm9/move_effects_table.json", "r"){|f| f.read})
	end

	def self.effect_mappings
		JSON.parse(File.open("#{$rom_name}/json/arm9/effect_mappings.json", "r"){|f| f.read})
	end

	def self.info
		$rom_name = 'projects/b2test'
		moves = get_all
		cmds = {}
		(1..559).each do |id|
			
			begin
				file = File.open("projects/b2test/move_scripts/#{id}.txt").readlines
			rescue
				next 
			end
			p id
			mv_name = moves[id][1]["name"]

			file.each_with_index do |line, i|
				cmd = line.match(/CMD_\S+/)
				if cmd
					cmd_id = "CMD_" + cmd[0].split("_")[1]
					cmds[cmd_id] ||= {}
					cmds[cmd_id][mv_name] ||= {}
					cmds[cmd_id][mv_name]["Line #{i}"] = line.strip
				end
			end
		end

		File.write("Reference_Files/move_anim_info.json", JSON.pretty_generate(cmds))
	end

	def self.export_dex 
		moves = get_all[1..-1]

		
		message_texts = JSON.parse File.read("#{$rom_name}/message_texts/texts.json")
		if SessionSettings.base_rom == "BW2"
            move_descs = message_texts[402].map {|entry| entry[1].gsub('\\n', " ")}
        end

		showdown = {}
		moves.each_with_index do |move, i|
			showdown_name = sub_showdown(move[1]["name"].move_titleize)

			showdown[showdown_name] = {}
			showdown[showdown_name]["t"] = move[1]["type"].titleize
			showdown[showdown_name]["bp"] = move[1]["power"]
			showdown[showdown_name]["cat"] = move[1]["category"]
			showdown[showdown_name]["pp"] = move[1]["pp"]
			showdown[showdown_name]["acc"] = move[1]["accuracy"]
			showdown[showdown_name]["prio"] = move[1]["priority"]


			showdown[showdown_name]["desc"] = move_descs[i + 1]


			showdown[showdown_name]["e_id"] = move[1]["effect_code"] || 0
			if move[1]["target"] == "All adjacent opponents" 
				showdown[showdown_name]["tar"] = "allAdjacentFoes"
			end

			if move[1]["target"] == "All excluding user" 
				showdown[showdown_name]["tar"] = "allAdjacent"
			end
			if move[1]["min_hits"] > 0
				showdown[showdown_name]["multihit"] = [move[1]["min_hits"],move[1]["max_hits"]]
			end

			if move[1]["recoil"] > 0 and move[1]["recoil"] < 100
				showdown[showdown_name]["recoil"] = [move[1]["recoil"], 100]
			end

			if move[1]["effect_category"].downcase.include?("stat")
				showdown[showdown_name]["sf"] = true
			end

			if move[1]["punch_move"] == 1
				showdown[showdown_name]["flags"] ||= {}
				showdown[showdown_name]["flags"]["punch"] = true
			end

			if move[1]["sound_move"] == 1
				showdown[showdown_name]["flags"] ||= {}
				showdown[showdown_name]["flags"]["sound"] = true
			end
		end

		File.write("./exports/moves.json", showdown.to_json)

		showdown
	end


	def self.export_showdown 
		moves = get_all[1..-1]

		if export_dex
			message_texts = JSON.parse File.read("#{$rom_name}/message_texts/texts.json")
			if SessionSettings.base_rom == "BW2"
	            move_descs = message_texts[402].map {|entry| entry[1].gsub('\\n', " ")}
	        end
		end

		showdown = {}
		moves.each_with_index do |move, i|
			showdown_name = sub_showdown(move[1]["name"].move_titleize)

			showdown[showdown_name] = {}
			showdown[showdown_name]["type"] = move[1]["type"].titleize
			showdown[showdown_name]["basePower"] = move[1]["power"]
			showdown[showdown_name]["category"] = move[1]["category"]
			showdown[showdown_name]["pp"] = move[1]["pp"]
			showdown[showdown_name]["accuracy"] = move[1]["accuracy"]
			showdown[showdown_name]["priority"] = move[1]["priority"]

			showdown[showdown_name]["e_id"] = move[1]["effect_code"] || 0
			if move[1]["target"] == "All adjacent opponents" 
				showdown[showdown_name]["target"] = "allAdjacentFoes"
			end

			if move[1]["target"] == "All excluding user" 
				showdown[showdown_name]["target"] = "allAdjacent"
			end
			if move[1]["min_hits"] > 0
				showdown[showdown_name]["multihit"] = [move[1]["min_hits"],move[1]["max_hits"]]
			end

			if move[1]["recoil"] > 0 and move[1]["recoil"] < 100
				showdown[showdown_name]["recoil"] = [move[1]["recoil"], 100]
			end

			if move[1]["effect_category"].downcase.include?("stat")
				showdown[showdown_name]["sf"] = true
			end

			if move[1]["punch_move"] == 1
				showdown[showdown_name]["flags"] ||= {}
				showdown[showdown_name]["flags"]["punch"] = true
			end

			if move[1]["sound_move"] == 1
				showdown[showdown_name]["flags"] ||= {}
				showdown[showdown_name]["flags"]["sound"] = true
			end
		end

		"success"
	end

	def self.write_data data, batch=false
		@@narc_name = "moves"
		@@upcases = []

		if data["file_name"] == "effects"
			field = data["field"].split("hc_effect_")[1]
			move_effects = effects


			move_effects["readable"][field] = data["value"].upcase

			File.write("#{$rom_name}/json/arm9/move_effects_table.json", move_effects.to_json)
			return
		end

		super
	end

	def self.get_names_from(moves)
		names = moves.map do |m|
			m[1]["name"].move_titleize
		end
	end

	def self.get_showdown_names_from(moves)
		names = moves.map do |m|
			move_name = m[1]["name"].move_titleize
			showdown_subs[move_name.to_sym] ? showdown_subs[move_name.to_sym] : move_name
		end
	end

	def self.misc_int_fields
		[{ "field_name" => "pp", "label" => "PP", "type" => "int-255"},
			{ "field_name" => "priority", "label" => "Priority", "type" => "int-255"},
			{ "field_name" => "crit", "label" => "+Crit", "type" => "int-15"},
			{ "field_name" => "flinch", "label" => "Flinch %", "type" => "int-100"},
			{ "field_name" => "recoil", "label" => "Recoil %", "type" => "int-255"},
			{ "field_name" => "healing", "label" => "Heal %", "type" => "int-100"},
			{ "field_name" => "animation", "label" => "Animation ID", "type" => "int-#{RomInfo.original_move_count - 1}"}
		]
	end

	def self.stat_modifier_fields
		fields = []

		(1..3).each do |n|
			fields << { "field_name" => "stat_#{n}", "label" => "Stat Mod", "autofill" => "stats" }
			fields << { "field_name" => "magnitude_#{n}", "label" => "Amount", "type" => "int-6"}
			fields << { "field_name" => "stat_chance_#{n}", "label" => "Proc %", "type" => "int-100"}
		end
		fields
	end

	def self.effect_fields
		[{ "field_name" => "effect_category", "label" => "Effect Category", "autofill" => "effect_cats"},
			{ "field_name" => "result_effect", "label" => "Add. Effects", "autofill" => "result_effects"},
			{ "field_name" => "effect_chance", "label" => "Add. Effect Proc %", "type" => "int-100"},
			{ "field_name" => "status", "label" => "Status Type", "autofill" => "status_types"},
			{ "field_name" => "target", "label" => "Target", "autofill"=> "targets"},
			{ "field_name" => "min_turns", "label" => "Min Effect Turns", "type"=> "int-255"},
			{ "field_name" => "max_turns", "label" => "Max Effect Turns", "type"=> "int-255"},
			{ "field_name" => "min_hits", "label" => "Min Hits", "type"=> "int-255"},
			{ "field_name" => "max_hits", "label" => "Max Hits", "type"=> "int-255"}
		]
	end

	def self.props
		["contact","requires_charge","recharge_turn","blocked_by_protect","reflected_by_magic_coat","stolen_by_snatch","copied_by_mirror_move","punch_move","sound_move","grounded_by_gravity","defrosts_targets","hits_non-adjacent_opponents","healing_move","hits_through_substitute"]
	end

	def self.showdown_subs
		{
		    "Bubblebeam": "Bubble Beam",
		    "Doubleslap": "Double Slap",
		    "Solarbeam": "Solar Beam",
		    "Sonicboom": "Sonic Boom",
		    "Poisonpowder": "Poison Powder",
		    "Thunderpunch": "Thunder Punch",
		    "Thundershock": "Thunder Shock",
		    "Ancientpower": "Ancient Power",
		    "Extremespeed": "Extreme Speed",
		    "Dragonbreath": "Dragon Breath",
		    "Dynamicpunch": "Dynamic Punch",
		    "Grasswhistle": "Grass Whistle",
		    "Featherdance": "Feather Dance",
		    "Faint Attack": "Feint Attack",
		    "Smellingsalt": "Smelling Salts",
		    "Roar Of Time": "Roar of Time",
		    "U-Turn": "U-turn",
		    "V-Create": "V-create",
		    "Sand-Attack": "Sand Attack",
		    "Selfdestruct": "Self-Destruct",
		    "Softboiled": "Soft-Boiled",
		    "Vicegrip": "Vise Grip",
		    "Hi Jump Kick": "High Jump Kick",
		}
	end

	def self.sub_showdown(move)
		subs = showdown_subs
		if showdown_subs[move.to_sym]
			return showdown_subs[move.to_sym]
		else
			return move
		end
	end

end



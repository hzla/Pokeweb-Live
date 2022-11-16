require 'json'
class Move < Pokenarc

	def self.get_all
		moves = {}
		Dir["#{$rom_name}/json/moves/*.json"].each do |move|
			move_data = JSON.parse(File.open(move, "r"){|f| f.read})["readable"]

			move_id = move_data["index"]
			moves[move_id] = move_data
		end
		moves.to_a.sort_by {|mov| mov[0] }
	end

	def self.export_showdown
		moves = get_all[1..-1]

		showdown = {}
		moves.each do |move|
			showdown_name = sub_showdown(move[1]["name"].move_titleize)

			showdown[showdown_name] = {}
			showdown[showdown_name]["type"] = move[1]["type"].titleize
			showdown[showdown_name]["basePower"] = move[1]["power"]
			showdown[showdown_name]["category"] = move[1]["category"]
			if move[1]["min_hits"] > 0
				showdown[showdown_name]["multihit"] = [move[1]["min_hits"],move[1]["max_hits"]]
			end
		end
		File.write("public/dist/moves.json", JSON.dump(showdown))
		open("public/dist/moves.js", "w") do |f| 
			f.puts "var pwMoves ="
			f.puts JSON.dump(showdown)
		end
	end

	def self.write_data data, batch=false
		@@narc_name = "moves"
		@@upcases = []
		super
	end

	def self.get_names_from(moves)
		names = moves.map do |m|
			m[1]["name"].move_titleize
		end
	end

	def self.misc_int_fields
		[{ "field_name" => "pp", "label" => "PP", "type" => "int-255"},
			{ "field_name" => "priority", "label" => "Priority", "type" => "int-255"},
			{ "field_name" => "crit", "label" => "+Crit", "type" => "int-15"},
			{ "field_name" => "flinch", "label" => "Flinch %", "type" => "int-100"},
			{ "field_name" => "recoil", "label" => "Recoil %", "type" => "int-100"},
			{ "field_name" => "healing", "label" => "Heal %", "type" => "int-100"}
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



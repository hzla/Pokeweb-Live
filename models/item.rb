class Item < Pokenarc


	def self.get_all
		@@narc_name = "items"
		super
	end


	def self.write_data data, batch=false
		@@narc_name = "items"
		@@upcases = []
		super
	end

	def self.get_showdown_names_from items
		names = items.map do |m|
			item_name = Trpok.item_titlize(m["name"])
		end
	end

	def self.expanded_fields
		col_1 = [[255, "item_type"], [255, "gain_values"], [255, "item_group"], [255, "battle_item_group"], [65535, "type_attribute"], [255, "name_order_id"], [1, "nature_gift_power"], [1, "battle_happiness"], [1, "ow_happiness"], [1, "hold_happiness"]]

		col_2 = [[255, "hp_atk_boost" ], [255, "def_spatk_boost"], [255, "spd_spdef_boost"], [255, "acc_crit_pp_boost"], [255, "hp_ev_gain"], [255, "atk_ev_gain"], [255, "def_ev_gain"], [255, "spd_ev_gain"], [255, "spatk_ev_gain"], [255, "spdef_ev_gain"], [255, "hp_gain"], [255, "pp_gain"]]

		col_3 = [[255, "battle_flags"], [255,"berry_flags"], [255,"held_flags"], [255,"usability_flag"], [255,"consumable_flag"], [255,"status_removal_flag"], [255,"unknown_flag_1"]]
		[col_1,col_2,col_3]
	end

	def self.locations
		loc_list = File.read("#{$rom_name}/texts/item_locations.txt").split("\n")
		locations = {}

		loc_list.each do |line|
			item_name = line.split("=>")[0].strip.downcase.gsub(" ", "")
			loc = line.split("=>")[1].strip

			locations[item_name] = loc
		end

		locations
	end

	def self.export_dex
		message_texts = JSON.parse File.read("#{$rom_name}/message_texts/texts.json")
		items = get_all
		trainers = Trdata.get_all

		dex_items = {}
		item_descs = message_texts[63].map {|entry| entry[1]}
		item_names = message_texts[64].map {|entry| entry[1]}



		item_names.each_with_index do |item, i|
			item_data = {}

			item_id = item.downcase.gsub(" ","").gsub("-", "").gsub(".", "").gsub("'", "")

			item_data["name"] = item
			item_data["desc"] = item_descs[i].gsub("\n", " ")

			item_data["location"] = items[i]["location"] ? items[i]["location"].join(", ") : ""
			dex_items[item_id] = item_data
		end

		trainers.each do |tr|

			if tr["reward_item"] && tr["reward_item"] != "None"
				item_id = tr["reward_item"].downcase.gsub(" ","").gsub("-", "").gsub(".", "").gsub("'", "")
				if dex_items[item_id]
					tr_name = tr["name"]

					if dex_items[item_id]["rewards"]
						dex_items[item_id]["rewards"] += ", Rewarded after beating #{tr["class"]} #{tr_name}" if !dex_items[item_id]["rewards"].include?("Rewarded after beating #{tr["class"]} #{tr_name}")
					else
						dex_items[item_id]["rewards"] = "Rewarded after beating #{tr["class"]} #{tr_name}" 
					end
				end
			end
		end

		File.write("./exports/items.json", JSON.pretty_generate(dex_items))
		dex_items
	end

	def self.get_locations search_ground=false
		overworlds = Overworld.get_all
		items = get_all
		item_scripts = script_to_item

		if search_ground
			overworlds.each_with_index do |overworld, i|
				npc_count = overworld["npc_count"]

				(0..npc_count-1).each do |n|
					script_id = overworld["npc_#{n}_script_id"]
					if (script_id > 7000 and script_id <= 7400)

						p "now looking up script #{script_id} item #{items[script_to_item[script_id]]["name"]}"

						file_path = "#{$rom_name}/json/items/#{script_to_item[script_id]}.json"
						json_data = JSON.parse(File.open(file_path, "r") {|f| f.read})

						location = Header.find_location_by_map_id(i)
						p "found at #{location[0]}"
						json_data["readable"]["location"] ||= []
						json_data["readable"]["location"] << location[0]
						File.open(file_path, "w") { |f| f.write json_data.to_json }
					end
				end
			end
		end
	end

	def self.script_to_item
		items = get_all

		`dotnet tools/beaterscript/BeaterScript.dll -d #{$rom_name}/scripts/1240.bin BW2 #{$rom_name}/scripts/1240.txt`
		# system command

		scripts = File.readlines("#{$rom_name}/scripts/1240.txt")

		item_scripts = {}
		script_id = 0

		scripts.each do |line|
			if line.start_with?("Script")
				script_id = line.split("Script")[1].split(":")[0].to_i
			end

			if line.include?("StoreInVar 32780, ")
				item_id = line.split("StoreInVar 32780, ")[1].strip.to_i
				item_scripts[7000 + script_id] = item_id
			end
		end

		item_scripts
	end




end




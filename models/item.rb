class Item


	def self.get_all
		collection = []
		files = Dir["#{$rom_name}/json/items/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			json = JSON.parse(File.open("#{$rom_name}/json/items/#{n}.json", "r:ISO8859-1").read)
			entry = json["readable"]

			collection[n] = entry
		end
		collection
	end


	def self.write_data data
		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		if data["int"]
			changed_value = changed_value.to_i
		end

		file_path = "#{$rom_name}/json/items/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r").read)

		json_data["readable"][field_to_change] = changed_value

		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end


	def self.expanded_fields
		col_1 = [[255, "item_type"], [255, "gain_values"], [255, "item_group"], [255, "battle_item_group"], [65535, "type_attribute"], [255, "name_order_id"], [1, "nature_gift_power"], [1, "battle_happiness"], [1, "ow_happiness"], [1, "hold_happiness"]]

		col_2 = [[255, "hp_atk_boost" ], [255, "def_spatk_boost"], [255, "spd_spdef_boost"], [255, "acc_crit_pp_boost"], [255, "hp_ev_gain"], [255, "atk_ev_gain"], [255, "def_ev_gain"], [255, "spd_ev_gain"], [255, "spatk_ev_gain"], [255, "spdef_ev_gain"], [255, "hp_gain"], [255, "pp_gain"]]

		col_3 = [[255, "battle_flags"], [255,"berry_flags"], [255,"held_flags"], [255,"usability_flag"], [255,"consumable_flag"], [255,"status_removal_flag"], [255,"unknown_flag_1"]]
		[col_1,col_2,col_3]
	end


end




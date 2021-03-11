require 'json'
	

class Personal

	def self.poke_data
		files = Dir["#{$rom_name}/json/personal/*.json"].sort_by{ |name| [name[/\d+/].to_i, name] }
		files.map do |pok|
			get_data_for pok
		end
	end

	def self.get_data_for(file_name)
		pok_id = file_name.split('/')[-1].split('.')[0]

		personal_data = JSON.parse(File.open(file_name, "r").read)["readable"]
		
		return if !personal_data
		learnset_data_path = "#{$rom_name}/json/learnsets/#{pok_id}.json"
		learnset_data = JSON.parse(File.open(learnset_data_path, "r").read)["readable"]

		personal_data["learnset"] = learnset_data
		personal_data		
	end

	def self.write_data(data)
		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		if data["int"]
			changed_value = changed_value.to_i
		end

		file_path = "#{$rom_name}/json/personal/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r").read)

		json_data["readable"][field_to_change] = changed_value

		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end

	def self.base_stat_fields
		# title to display, field_name in json
		[["HP", "base_hp"],["Attack", "base_atk"],["Defense", "base_def"],["Special Attack", "base_spatk"],["Special Defense", "base_spdef"],["Speed", "base_speed"]]
	end

	def self.misc_integer_fields
		# title to display, field_name in json
		[["Catch Rate", "catchrate"],["Exp Yield", "base_exp"],["Gender", "gender"],["Hatch Rate", "hatch_cycle"],["Happiness", "base_happy"]]
	end

	def self.text_fields
		# title to display, field_name in json, autofill_bank
		[['50% Held Item', 'item_1', 'items' ],['5% Held Item', 'item_2', 'items' ],['1% Held Item', 'item_3', 'items' ],['Egg Group 1', 'egg_group_1', 'egg_groups' ],['Egg Group 2', 'egg_group_2', 'egg_groups' ],['Growth Rate', 'exp_rate', 'growth_rates' ]]	
	end

	def self.ev_yield_fields
		# title to display, field_name in json
		[["HP", "hp_yield"],["Attack", "atk_yield"],["Defense", "def_yield"],["Sp Attack", "spatk_yield"],["Sp Defense", "spdef_yield"],["Speed", "speed_yield"]]
	end
end
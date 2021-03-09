require 'json'
	

class Personal

	def self.get_data(file_name)
		JSON.parse(File.open(file_name, "r").read)["readable"]
	end

	def self.write_data(data)
		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

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


class SessionSettings

	def self.rom_name

		if File.exist?('session_settings.json')
			JSON.parse(File.open("session_settings.json", "r").read)["rom_name"]
		else
			nil
		end
	end
end

class RomInfo

	def self.types
		["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water","Grass","Electric","Psychic","Ice","Dragon","Dark"].map do |type|

			type.upcase
		end
	end

	def self.abilities
		File.open("#{$rom_name}/texts/abilities.txt").read.split("\n").map do |ab|
			ab.titleize
		end
	end

	def self.items
		# encoding for latin text ISO8859-1
		File.open("#{$rom_name}/texts/items.txt", encoding: "ISO8859-1").read.split("\n")
	end

	def self.egg_groups
		["~","Monster","Water 1","Bug","Flying","Field","Fairy","Grass","Human-Like","Water 3","Mineral","Amorphous","Water 2","Ditto","Dragon","Undiscovered"]
	end

	def self.growth_rates
		["Medium Fast","Erratic","Fluctuating","Medium Slow","Fast","Slow"]
	end
end

class String
  def titleize
  	if self == ""
  		return "-"
  	end
    gsub("-", " ").split(/([ _-])/).map(&:capitalize).join
  end

  def squish!
    gsub!("\n", '')
    self
  end
end
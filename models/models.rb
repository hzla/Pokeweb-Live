
## todo create a readable class to hold all the reading logic that other models will inherit


class SessionSettings

	def self.rom_name
		if File.exist?('session_settings.json')
			contents = File.open("session_settings.json", "r").read
			return JSON.parse(contents)["rom_name"] if contents != ""
		else
			nil
		end
		nil
	end

	def self.reset
		settings = File.open("session_settings.json", "w").write("")
	end
end

class RomInfo

	def self.pokemon_names
		file_path = "#{$rom_name}/texts/pokedex.txt"
		data = File.open(file_path, "r:ISO8859-1").read.split("\n").map do |p|
			p.name_titleize
		end
	end

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

	def self.evo_methods
		File.open("Reference_Files/evo_methods.txt").read.split("\n")
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

	def self.status_types
		["None","Visible","Temporary","Infatuation", "Trapped"]
	end

	def self.targets 
		["Any adjacent","Random (User/ Adjacent ally)","Random adjacent ally","Any adjacent opponent","All excluding user","All adjacent opponents","User's party","User","Entire Field","Random adjacent opponent","Field Itself","Opponent's side of field","User's side of field","User (Selects target automatically)"]
	end

	def self.stats
		["None", "Attack", "Defense", "Special Attack", "Special Defense", "Speed", "Accuracy", "Evasion", "All" ]
	end

	def self.effects
		File.open("Reference_Files/effects.txt").read.split("\n")
	end

	def self.result_effects
		File.open("Reference_Files/result_effects.txt").read.split("\n")
	end

	def self.class_names
		names =[]
		File.open("#{$rom_name}/texts/tr_classes.txt").read.split("\n").each_with_index do |n, i|
			names << "#{n} (#{i})"
		end
		names
	end

	def self.effect_cats
		["No Special Effect", "Status Inflicting","Target Stat Changing","Healing","Chance to Inflict Status","Raising Target's Stat along Attack", "Lowering Target's Stat along Attack","Raise user stats","Lifesteal","OHKO","Weather","Safeguard", "Force Switch Out", "Unique Effect"]
	end

	def self.battle_types
		["Singles", "Doubles", "Triples", "Rotation"]
	end

	def self.genders
		["Default", "Female", "Male"]
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
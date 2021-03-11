
## todo create a readable class to hold all the reading logic that other models will inherit


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
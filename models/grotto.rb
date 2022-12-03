class Grotto < Pokenarc

	def self.get_all
		@@narc_name = "grottos"
		super
	end


	def self.write_data data, batch=false
		@@narc_name = "grottos"
		@@upcases = ["pok"]

		p data
		p "/////////"
		if data["field"].include?("odds")
			write_odds data
		else
			super
		end
	end

	def self.write_odds data
		odds_path = "#{$rom_name}/json/arm9/grotto_odds.json"
		odds = JSON.parse(File.open(odds_path, "r"){|f| f.read})
		odds["readable"][data["field"]] = data["value"].to_i

		File.open(odds_path, "w") { |f| f.write odds.to_json }
	end

	def self.odds_data
		odds_path = "#{$rom_name}/json/arm9/grotto_odds.json"
		odds = JSON.parse(File.open(odds_path, "r"){|f| f.read})

	end

	def self.remaining_odd odds_data, n
		remaining = 100
		odds_data.each do |k,v|
			if k.split("_").last == n.to_s
				remaining -= v
			end
		end
		remaining
	end




	def self.wilds grotto
		wilds = []

		["black", "white"].each do |version|
			["rare", "uncommon", "common"].each do |rarity|
				(0..3).each do |n|
					wilds << grotto["#{version}_#{rarity}_pok_#{n}"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
				end

			end
		end
		wilds.uniq
	end

	def self.encounter_rates
		[15,4,1]
	end

	def self.item_rates
		[25,10,4,1]
	end

end


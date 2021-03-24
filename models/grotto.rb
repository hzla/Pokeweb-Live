class Grotto < Pokenarc

	def self.get_all
		@@narc_name = "grottos"
		super
	end


	def self.write_data data
		@@narc_name = "grottos"
		@@upcases = ["pok"]
		super
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


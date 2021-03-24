class Mart < Pokenarc

	def self.get_all
		@@narc_name = "marts"
		super
	end


	def self.write_data data, batch=false
		@@narc_name = "marts"
		super
	end

	def self.inventory(mart)
		inv = []
		(0..19).each do |n|
			inv << mart["item_#{n}"]
		end
		inv = inv.compact.uniq
		inv.delete("None")
		inv.join(", ")
	end


end




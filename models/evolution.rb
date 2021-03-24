class Evolution < Pokenarc
	

	def self.get_all
		@@narc_name = "evolutions"
		super
	end


	def self.write_data data
		@@narc_name = "evolutions"
		super
	end


end




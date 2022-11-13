class Evolution < Pokenarc
	

	def self.get_all
		@@narc_name = "evolutions"
		super
	end


	def self.write_data data, batch=false
		@@narc_name = "evolutions"
		@@upcases = []
		super
	end


end




class Evolution < Pokenarc
	

	def self.get_all use_raw=false
		@@narc_name = "evolutions"
		super(use_raw)
	end


	def self.write_data data, batch=false
		@@narc_name = "evolutions"
		@@upcases = []
		super
	end


end




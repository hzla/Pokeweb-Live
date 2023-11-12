class Learnset < Pokenarc


	def self.write_data(data, batch=false)
		@@narc_name = "learnsets"
		@@upcases = "all"
		super
	end

	def self.get_all
		@@narc_name = "learnsets"
		super
	end
end
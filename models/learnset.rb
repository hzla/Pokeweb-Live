class Learnset < Pokenarc


	def self.write_data(data)
		@@narc_name = "learnsets"
		@@upcases = "all"
		super
	end
end
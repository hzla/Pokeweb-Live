class Overworld < Pokenarc

	def self.get_all
		@@narc_name = "overworlds"
		super
	end


	def self.write_data data, batch=false
		@@narc_name = "overworlds"
		@@upcases = []
		super
	end

	# def self.get_data(file_name)
	# 	@@narc_name = "overworlds"
	# 	# JSON.parse(File.open(file_name, "r"){|f| f.read})["readable"]
	# 	super
	# end

	def self.get_bounding_box(overworld)
		npc_count = overworld["npc_count"]

		x_cords = []
		y_cords = []

		(0..npc_count - 1).each do |n|
			x_cords << overworld["npc_#{n}_x_cord"]
			y_cords << overworld["npc_#{n}_y_cord"]
		end

		[[x_cords.min, y_cords.min], [x_cords.max, y_cords.max]]
	end

end



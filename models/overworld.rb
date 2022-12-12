class Overworld < Pokenarc

	def self.get_all 
		@@narc_name = "overworlds"
		super
	end

	def self.sprite_hash
		JSON.parse(File.open('Reference_Files/sprite_hash.json', "r"){|f| f.read})
	end

	def self.png_id sprite_id
		sprite_hash[sprite_id.to_s]
	end

	def self.write_data data, batch=false
		@@narc_name = "overworlds"
		@@upcases = []
		super(data, false, "raw")
	end

	def self.npc_fields
		[ 'overworld_id',
		 'overworld_sprite',
		 'movement_permissions',
		 'movement_permissions_2',
		 'overworld_flag',
		 'script_id',
		 'direction',
		 'sight',
		 'unknown_1',
		 'unknown_2',
		 'horizontal_leash',
		 'vertical_leash',
		 'unknown_3',
		 'unknown_4',
		 'x_cord',
		 'y_cord',
		 'unknown_5',
		 'z_cord']
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



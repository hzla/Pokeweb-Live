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

	def self.get_maps id
		headers = Header.get_all


		#search headers for overworld_id
		n = 1
		header = nil
		until header or n > headers["count"]
			header = headers[n.to_s]["overworlds_id"] == id ? headers[n.to_s] : nil
			n += 1
		end

		# get matrix and matrix cordinates from header
		matrix = MapMatrix.get_data header["matrix_id"]
		cords = MapMatrix.get_cords header["matrix_id"]

		# binding.pry

		# for non matrix 0
		if matrix["headers"].uniq == [0]		
			height = matrix["height"]
			width = matrix["width"]

			x = 0
			y= 0

			all_maps = []
			matrix["maps"].each_with_index do |map_id, i|
				map = Map.get_data map_id
				
				if i % width == 0 && i > 0
					x = 0
					y += 32
				end
				map_data = [map_id, [x,y, map["width"], map["height"]]]
				x += 32
				all_maps <<  map_data
			end
			return {"maps" => all_maps, "translate" => [0,0]}
		end
		

		# search matrix for matching headers
		matching_headers = []
		matrix["headers"].each_with_index do |h, i|
			if h == (n - 2)
				matching_headers << i
			end
		end
		
		# binding.pry
		# convert headers to map/cord pairs
		all_map_cords = []
		matching_maps = matching_headers.map do |h|
			map = matrix["maps"][h]
			map_cords = cords[h]
			all_map_cords << map_cords
			[map, map_cords]
		end

		location = headers[matching_headers[0].to_s]["location_name"]

		{"maps" => matching_maps.uniq, "translate" => get_translate(all_map_cords), "headers" => matching_headers, "location" => location}
	end

	def self.get_translate map_cords
		x_cords = []
		y_cords = []
		map_cords.each do |cord|
			x_cords << cord[0]
			y_cords << cord[1]
		end
		[x_cords.min, y_cords.min]
	end


	def self.npc_fields
		['overworld_id',
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



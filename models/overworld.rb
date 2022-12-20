class Overworld < Pokenarc

	def self.get_all 
		@@narc_name = "overworlds"
		super
	end

	def self.get_data file_name, file_type
		@@narc_name = "overworlds"
		file_name = "#{$rom_name}/json/overworlds/#{file_name}.json"
		super file_name, file_type
	end

	def self.add_npc ow_id
		overworld = get_data(ow_id, "all")
		ow = overworld["raw"]
		
		npc_index = ow["npc_count"]
		npc_fields = ["overworld_id",
        "overworld_sprite",
        "movement_permissions",
        "movement_permissions_2",
        "overworld_flag",
        "script_id",
        "direction",
        "sight",
        "unknown_1",
        "unknown_2",
        "horizontal_leash",
        "vertical_leash",
        "unknown_3",
        "unknown_4",
        "x_cord",
        "y_cord",
        "unknown_5",
        "z_cord"]

        # increment npc count and file length
		ow["npc_count"] += 1
		ow["file_length"] += 36

		# set all fields to 0
		npc_fields.each do |field|
			ow["npc_#{npc_index}_#{field}"] = 0
		end

		# set to default sprite and overworld_id
		ow["npc_#{npc_index}_overworld_sprite"] = 1
		ow["npc_#{npc_index}_overworld_id"] = npc_index

		# place next to last npc
		if npc_index > 0
			ow["npc_#{npc_index}_x_cord"] = ow["npc_#{npc_index - 1}_x_cord"] + 1
			ow["npc_#{npc_index}_y_cord"] = ow["npc_#{npc_index - 1}_y_cord"] + 1	
		end 
		overworld["raw"] = ow
		file_path = "#{$rom_name}/json/overworlds/#{ow_id}.json"
		File.open(file_path, "w") { |f| f.write overworld.to_json}

		ow
	end

	# deletes last npc
	def self.remove_npc ow_id
		
		overworld = get_data(ow_id, "all")
		ow = overworld["raw"]		
		npc_index = ow["npc_count"]

		return if npc_index < 1

        # deincrement npc count and file length
		overworld["raw"]["npc_count"] -= 1
		overworld["raw"]["file_length"] -= 36

		# delete all fields for npc
		ow.each do |k,v|
			if k.include?("npc_#{npc_index - 1}_")
				overworld["raw"].delete(k)
			end
		end

		file_path = "#{$rom_name}/json/overworlds/#{ow_id}.json"
		File.open(file_path, "w") { |f| f.write overworld.to_json}

		ow
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
		
		location = nil
		script = nil
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

		# binding.pry
		# location = headers[matching_headers[0].to_s]["location_name"]

		{"maps" => matching_maps.uniq, "translate" => get_translate(all_map_cords), "headers" => matching_headers}
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
end



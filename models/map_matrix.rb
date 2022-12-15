class MapMatrix < Pokenarc

	def self.get_all
		@@narc_name = "matrix"
		super "both"
	end

	def self.get_data file_name
		@@narc_name = "matrix"
		file_name = "#{$rom_name}/json/matrix/#{file_name}.json"
		super file_name, "all"
	end

	def self.get_cords matrix_id
		JSON.parse(File.open("#{$rom_name}/cordinates.json", "r"){|f| f.read})[matrix_id]
	end




	def self.output_cords
		matrices = MapMatrix.get_all

		all_matrices = []

		matrices.each_with_index do |m, j|
			width = m["width"]
			height = m["height"]
			matrix_data = []

			x_cord = 0
			y_cord = 0
			last_height = 0

			m["maps"].each_with_index do |mp, i|
				
				# if new row, reset x_cord, increment y_cord
				if i % width == 0 and i > 0
					x_cord = 0
					y_cord += last_height
				end

				
				# if null map, add 32 32
				if mp == 4294967295
					matrix_data << [x_cord, y_cord, 32,32 ]
					last_height = 32
					x_cord += 32
				else
					map_data = Map.get_data(mp)
					last_height = map_data["height"]
					matrix_data << [x_cord, y_cord, map_data["width"], map_data["height"]]
					x_cord += map_data["width"]
				end


			end

			all_matrices << matrix_data
		end

		File.open("#{$rom_name}/cordinates.json", "w") { |f| f.write all_matrices.to_json }
	end
end
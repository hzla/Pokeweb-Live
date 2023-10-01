
class Spa



	def self.write_data data
		if !data["file_name"].include? "_"
			return write_particle_field data
		end

		file_info = data["file_name"].split("_")
		file_name = "#{$rom_name}/spas/#{file_info[0]}_spa.json"

		texture_id = file_info[1].to_i 
		color_id = file_info[2].to_i
		
		spa = JSON.parse(File.open(file_name, "r"){|f| f.read})

		if data["value"][0] != "#"
			spa["textures"][texture_id]["colors"][color_id] = "rgb(#{data["value"]})"
		else
			spa["textures"][texture_id]["colors"][color_id] = data["value"]
		end


		File.open(file_name, "w") { |f| f.write JSON.pretty_generate(spa)}

		p "python3 python/spa_reader.py #{file_info[0]} #{$rom_name} -w"
		`python3 python/spa_reader.py #{file_info[0]} #{$rom_name} -w`
	end


	def self.write_particle_field data
		file_name = "#{$rom_name}/spas/#{data["file_name"]}_spa.json"
		spa = JSON.parse(File.open(file_name, "r"){|f| f.read})

		particle_index = data['field'].split("_")[-1].to_i


		spa["particles"][particle_index][data['field'].split("_#{particle_index}")[0]] = data['value']

		File.open(file_name, "w") { |f| f.write JSON.pretty_generate(spa)}

		p "python3 python/spa_reader.py #{data["file_name"]} #{$rom_name} -w"
		`python3 python/spa_reader.py #{data["file_name"]} #{$rom_name} -w`
	end


	def self.get_fields spa_id
		particles = JSON.parse(File.read("#{$rom_name}/spas/#{spa_id}_spa.json"))["particles"]


		fields = []

		particles.each do |particle|
			field = {}
			field[:base_color] = particle["base_color"]
			field[:base_scale] = particle["base_scale"]
			field[:base_delay] = particle["base_delay"]
			field[:particle_duration] = particle["particle_duration"]
			field[:air_resistance] = particle["air_resistance"]

			if particle["color_start"]
				field[:color_start] = particle["color_start"]
				field[:color_end] = particle["color_end"]
			end

			fields << field
		end

		fields



	end

end
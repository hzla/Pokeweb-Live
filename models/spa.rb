
class Spa



	def self.write_data data
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

end
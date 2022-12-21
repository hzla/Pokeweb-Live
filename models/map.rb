class Map < Pokenarc

	def self.get_all
		@@narc_name = "maps"
	end



	def self.get_data file_name, type="all"
		@@narc_name = "maps"
		file_name = "#{$rom_name}/json/#{@@narc_name}/#{file_name}.json"
		super file_name, "all"
	end

	def self.perms file_name, layer=2
		get_data(file_name)["layer_#{layer}"]
	end

	def self.cords file_name, matrix_id
	end

	def self.write_data data
		map = get_data data["file_name"]
		field = data["field"].split("_index")[0]
		field_index = data["field"].split("_")[-1].to_i
		map[field][field_index] = data["value"].to_i

		File.open("#{$rom_name}/json/maps/#{data["file_name"]}.json", "w") { |f| f.write map.to_json } 
	end

	def self.colors
		pallete = {}
		pallete[0] = ["#ecf0f1", "passable"]
		pallete[1] = ["#e74c3c", "unpassable"]
		pallete[3] = ["#ecf0f1", "passable road"]
		pallete[2] = ["#ecf0f1", "passable"]
		pallete[4] = ["#2ecc71", "reg tall grass"]
		pallete[6] = ["#00b894", "doubles grass"]
		pallete[20] = ["#81ecec", "puddle"]
		pallete[31] = ["#55efc4", "short grass (no enc)"]
		pallete[34] = ["#2ecc71", "dreamyard grass?"]
		pallete[61] = ["#74b9ff", "pond"]
		pallete[63] = ["#0984e3", "surf"]
		pallete[65] = ["#0984e3", "surf edge"]
		pallete[10] = ["#636e72", "cave encounter"]
		pallete[11] = ["#ffeaa7", "sand"]
		pallete[12] = ["#fdcb6e", "sand encounter"]
		pallete[18] = ["#0984e3", "deep pond ledge"]
		pallete[28] = ["#6ab04c", "swamp"]
		pallete[29] = ["#2d3436", "boulder hole"]
		pallete[48] = ["#ecf0f1", "passable chargestone interactable"]
		pallete[50] = ["#ecf0f1", "passable chargestone interactable"]
		pallete[114] = ["#cc8e35", "ledge right"]
		pallete[115] = ["#cc8e35", "ledge left"]
		pallete[116] = ["#cc8e35", "ledge up"]
		pallete[117] = ["#cc8e35", "ledge down"]
		pallete[219] = ["#e74c3c", "indoor chair"]
		pallete[212] = ["#e74c3c", "indoor unpassable"]
		pallete[223] = ["#e74c3c", "indoor unpasssable"]
		pallete
	end

	def self.color perm
		colors[perm] ? colors[perm] : ["", "unknown"]
	end


end

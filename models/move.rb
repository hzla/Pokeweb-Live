class Move

	def self.get_data(file_name)
		JSON.parse(File.open(file_name, "r").read)["readable"]
	end

	def self.get_all
		moves = {}
		Dir["#{$rom_name}/json/moves/*.json"].each do |move|
			move_data = JSON.parse(File.open(move, "r").read)["readable"]

			move_id = move_data["index"]
			moves[move_id] = move_data
		end
		moves
	end

	def self.get_names_from(moves)
		names = moves.map do |m|
			m[1]["name"].titleize
		end
	end

end
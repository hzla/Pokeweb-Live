class Learnset < Pokenarc


	def self.write_data(data, batch=false)
		@@narc_name = "learnsets"
		@@upcases = "all"
		super
	end

	def self.delete id, idx
		path = "#{$rom_name}/json/learnsets/#{id}.json"
		data = get_data path, "all"

		data["readable"].delete("move_id_#{idx}")
		data["raw"].delete("move_id_#{idx}")

		data["readable"].delete("lvl_learned_#{idx}")
		data["raw"].delete("lvl_learned_#{idx}")

		(idx..23).each do |i|
			break if !data["readable"]["move_id_#{i + 1}"]  


			data["readable"]["move_id_#{i}"] = data["readable"]["move_id_#{i + 1}"] 
			data["raw"]["move_id_#{i}"] = data["raw"]["move_id_#{i + 1}"] 

			data["readable"]["lvl_learned_#{i}"] = data["readable"]["lvl_learned_#{i + 1}"] 
			data["raw"]["lvl_learned_#{i}"] = data["raw"]["lvl_learned_#{i + 1}"] 

			data["readable"]["move_id_#{i}_index"] = data["readable"]["lvl_learned_#{i + 1}"] 
		end 

		File.open(path, "w") { |f| f.write data.to_json }
	end
end
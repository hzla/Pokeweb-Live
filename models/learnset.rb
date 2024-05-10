class Learnset < Pokenarc


	def self.write_data(data, batch=false)
		@@narc_name = "learnsets"
		@@upcases = "all"
		super
	end

	def self.repair_all 
		ls_count = Dir["#{$rom_name}/json/learnsets/*.json"].length - 1
		(1..ls_count).each do |id|
			sort_readable id
		end
		`python3 python/learnset_writer.py update all #{$rom_name} #{ls_count}`		
	end

	def self.get_all
		@@narc_name = "learnsets"
		super
	end

	def self.sort_readable id 
		path = "#{$rom_name}/json/learnsets/#{id}.json"
		begin
			data = get_data(path, "all")
		rescue
			p id
		end
		readable = data["readable"]

		sorted = []
		(0..24).each do |n|
			break if !readable["lvl_learned_#{n}"] && !readable["move_id_#{n}"]
			return if !readable["lvl_learned_#{n}"] or !readable["move_id_#{n}"]

			sorted << {"lvl_learned" => readable["lvl_learned_#{n}"], "move_id" => readable["move_id_#{n}"]}
			# p readable["lvl_learned_#{n}"]  
			# p readable["move_id_#{n}"]
		end




		sorted.sort_by! {|ls| ls["lvl_learned"]}


		
		sorted.each_with_index do |ls, i| 
			data["readable"]["lvl_learned_#{i}"] = ls["lvl_learned"]
			data["readable"]["move_id_#{i}"] = ls["move_id"]
		end


		File.open(path, "w") { |f| f.write data.to_json }
	end

	def self.delete id, idx
		path = "#{$rom_name}/json/learnsets/#{id}.json"
		data = get_data path, "all"

		data["readable"].delete("move_id_#{idx}")
		data["raw"].delete("move_id_#{idx}")

		data["readable"].delete("lvl_learned_#{idx}")
		data["raw"].delete("lvl_learned_#{idx}")

		(idx..23).each do |i|
			if !data["readable"]["move_id_#{i + 1}"] 
				
				data["readable"].delete("move_id_#{i}")
				data["raw"].delete("move_id_#{i}")

				data["readable"].delete("lvl_learned_#{i}")
				data["raw"].delete("lvl_learned_#{i}")
				break
			end 


			data["readable"]["move_id_#{i}"] = data["readable"]["move_id_#{i + 1}"] 
			data["raw"]["move_id_#{i}"] = data["raw"]["move_id_#{i + 1}"] 

			data["readable"]["lvl_learned_#{i}"] = data["readable"]["lvl_learned_#{i + 1}"] 
			data["raw"]["lvl_learned_#{i}"] = data["raw"]["lvl_learned_#{i + 1}"] 

			data["readable"]["move_id_#{i}_index"] = data["readable"]["move_id_#{i+1}_index"] 
		end 

		File.open(path, "w") { |f| f.write data.to_json }
	end
end
class Tm 

	def self.get_data
		JSON.parse(File.open("#{$rom_name}/json/arm9/tms.json", "r"){|f| f.read})
	end

	def self.get_names 
		data = get_data
		names = {}
		tm_names = []
		hm_names = []
		(1..95).each do |tm|
			tm_names << data["readable"]["tm_#{tm}"].move_titleize
		end
		(1..6).each do |hm|
			hm_names << data["readable"]["hm_#{hm}"].move_titleize
		end
		{tm_names: tm_names, hm_names: hm_names}
	end

	def self.get_tms_from(moves)
		tm_moves = []
		tm_data = get_data

		(1..95).each do |tm_num|
			tm_moves << moves[tm_data["raw"]["tm_#{tm_num}"]]
		end

		hm_moves = []
		(1..6).each do |hm_num|
			hm_moves << moves[tm_data["raw"]["hm_#{hm_num}"]]
		end

		[hm_moves, tm_moves]
	end

	# only ever writes tm move name data
	def self.write_data data
		field_to_change = data["field"]
		changed_value = data["value"].upcase


		file_path = "#{$rom_name}/json/arm9/tms.json"
		
		json_data = JSON.parse(File.open(file_path, "r"){|f| f.read})
		json_data["readable"][field_to_change] = changed_value
		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end
end
class Grotto

	def self.get_all
		collection = []
		files = Dir["#{$rom_name}/json/grottos/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			json = JSON.parse(File.open("#{$rom_name}/json/grottos/#{n}.json", "r:ISO8859-1") {|f| f.read})
			entry = json["readable"]

			collection[n] = entry
		end
		collection
	end


	def self.write_data data
		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		if data["int"]
			changed_value = changed_value.to_i
		end

		file_path = "#{$rom_name}/json/grottos/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r") {|f| f.read})

		json_data["readable"][field_to_change] = changed_value

		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end

	def self.wilds grotto
		wilds = []

		["black", "white"].each do |version|
			["rare", "uncommon", "common"].each do |rarity|
				(0..3).each do |n|
					wilds << grotto["#{version}_#{rarity}_pok_#{n}"].gsub(/[^0-9A-Za-z\-]/, '').name_titleize
				end

			end
		end
		wilds.uniq
	end

end
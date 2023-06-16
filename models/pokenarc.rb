class Pokenarc
	@@narc_name = ""
	@@upcases = []


	def self.get_data(file_name, type="readable")
		if type != "all"
			JSON.parse(File.open(file_name, "r"){|f| f.read})[type]
		else
			JSON.parse(File.open(file_name, "r"){|f| f.read})
		end
	end

	def self.get_all use_raw=false, limit=-1
		collection = []
		files = Dir["#{$rom_name}/json/#{@@narc_name}/*.json"]
		file_count = files.length
		(0..file_count - 1).each do |n|
			begin
				file = File.open("#{$rom_name}/json/#{@@narc_name}/#{n}.json", "r:ISO8859-1") {|f| f.read }
			rescue
				break
			end
			json = JSON.parse(file)
			entry = json["readable"]
			entry = json["raw"] if use_raw
			entry = json if use_raw == "both"

			collection[n] = entry
		end
		collection
	end

	def self.write_data data, batch=false, write_to="readable"
		if batch
			write_batch_data data
		end

		file_name = data["file_name"]
		field_to_change = data["field"]
		changed_value = data["value"]

		file_path = "#{$rom_name}/json/#{@@narc_name}/#{file_name}.json"
		json_data = JSON.parse(File.open(file_path, "r") {|f| f.read})

		if data["int"] && data["int"] != "false"
			changed_value = changed_value.to_i
	
		elsif @@upcases == "all" || @@upcases.any? {|field| data["field"].include? field } 
			p @@upcases
		
			p data["field"]
			changed_value = changed_value.upcase
		else
		end



		if data["field"] == "class" && @@narc_name == "trdata"
			class_data = changed_value.split(" (")
			changed_value = class_data[0]
			
			new_class_id = class_data[1].split(")")[0]
			json_data[write_to]["class_id"] = new_class_id
		end


		json_data[write_to][field_to_change] = changed_value
		File.open(file_path, "w") { |f| f.write json_data.to_json }
	end

	def self.write_batch_data data
		data["file_names"].each do |file|
			data["file_name"] = file
			write_data(data)
		end
	end


end
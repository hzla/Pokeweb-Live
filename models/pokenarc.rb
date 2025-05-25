class Pokenarc
	@@narc_name = ""
	@@upcases = []



	def self.copy(narc_name, from, to)
		constantizes = {"learnsets" => "personal"}

		if narc_name == "personal" || narc_name == "moves" || narc_name == "items" 
			static_name = get_data("#{$rom_name}/json/#{narc_name}/#{to}.json")["name"]

		end



		`cp #{$rom_name}/json/#{narc_name}/#{from}.json #{$rom_name}/json/#{narc_name}/#{to}.json`

		if narc_name == "personal" || narc_name == "moves" || narc_name == "items" 
			@@narc_name = narc_name
			write_data({"field" => "name", "value" => static_name, "file_name" => to})

			if narc_name == "personal"
				write_data({"field" => "index", "value" => to, "file_name" => to})
			end
		end

		if constantizes[narc_name]
			"/#{constantizes[narc_name]}"
		else
			"/#{narc_name}"
		end


		
	end

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
			
			begin
				json = JSON.parse(file)
			rescue #fix corrupted trainer data
				if @@narc_name == "trpok"
					# binding.pry
					File.write("#{$rom_name}/json/#{@@narc_name}/#{n}.json", validate_brackets(file))
					file = validate_brackets(file)

					
					# copy from vanilla template files if fix fails
					begin
						json = JSON.parse(file)
					rescue
						`cp templates/#{SessionSettings.get("base_version")}/json/trpok/#{n}.json #{$rom_name}/json/trpok/#{n}.json`
						file = File.open("#{$rom_name}/json/#{@@narc_name}/#{n}.json", "r:ISO8859-1") {|f| f.read }
						json = JSON.parse(file)
					end
				end
			end

			begin
				entry = json["readable"]
			rescue
				p n
			end
			entry = json["raw"] if use_raw
			entry = json if use_raw == "both"

			if @@narc_name == "trpok"
				entry["raw"] = json["raw"]
			end

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

def self.validate_brackets data
	net_brackets = 1
	cut_at = -1
	(1..data.length - 1).each do |n|
		chr = data[n]
		if chr == "{"
			net_brackets += 1
		end
		if chr == "}"
			net_brackets -= 1
		end
		if net_brackets == 0
			cut_at = n
			break
		end
	end
	data[0..cut_at] 
end



end
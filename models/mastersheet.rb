class Mastersheet


	def self.parse encounters, trdata, trpok
		source = File.open("#{$rom_name}/mastersheet.txt").read.split("\n")
		tr_ids = []
		sheet_items = []
		last_location = ""
		last_split = ""
		prev_tr_id = nil
		prev_tr_index = nil
		tr_count = 0
		
		source.each do |line|
			next if line == ""
			element = {}
			if line.start_with?("###")
				tag = "h3"
				element[:content] = line[4..-1]
			elsif line.start_with?("##")
				tag = "h2"
				element[:content] = line[3..-1] 
				last_location = element[:content]
			elsif line.start_with?("#")
				tag = "h1"
				element[:content] = line[2..-1] 
				last_split = element[:content] if element[:content].downcase.include?("split")
			elsif line.start_with?("!tr")
				if line.start_with?("!trm")
					element[:class] = "mand"
				end
				tag = "trainer"
				trainer = line.split(" ")[1]
				element[:id] = trainer.to_i

				if element[:id] == 0
					parsed_trainer = trainer.split("/") 
					tr_name = parsed_trainer[0]
					mon_lvl = parsed_trainer[2].to_i
					mon_name = parsed_trainer[1]

					if mon_name.to_i > 0
						mon_lvl = mon_name.to_i
						element[:id] = Trpok.search trdata, trpok, tr_name, mon_lvl, ""
					else
						element[:id] = Trpok.search trdata, trpok, tr_name, mon_lvl, mon_name
					end	
				end
				tr_data = {id: element[:id]}
				
				# set pointer to previous trainer
				tr_data[:prev] = prev_tr_id
				
				# set pointer of previous trainer to current trainer if it exists
				if prev_tr_index
					tr_ids[prev_tr_index][:next] = element[:id]
				end

				# update previous trainer to current trainer
				prev_tr_id = element[:id]
				tr_count += 1
				prev_tr_index = tr_count - 1

				tr_ids << tr_data


				element[:notes] = line.split(" ")[2..-1]
			elsif line.start_with?("!enc")
				tag = "encounter"
				

				element[:id] = line[5..-1].to_i
				
				#if searching by location name
				if element[:id] == 0
					element[:id] = Encounter.search(encounters, line[5..-1].strip)
				end
			else
				tag = "p"
				element[:content] = line
			end
			element[:tag] = tag
			sheet_items << element
		end
		tr_id_hash = {}
		tr_ids.each do |tr|
			tr_id_hash[tr[:id].to_i] = tr
		end
		File.write("#{$rom_name}/mastersheet_tr_ids.json", JSON.pretty_generate(tr_id_hash))
		sheet_items
	end

	def self.tr_ids trdata, trpok
		source = File.open("#{$rom_name}/mastersheet.txt").read.split("\n")
		tr_ids = []
		sheet_items = []
		last_location = ""
		last_split = ""
		prev_tr_id = nil
		prev_tr_index = nil
		tr_count = 0
		
		source.each do |line|
			next if line == ""
			element = {}
			if line.start_with?("###")
				tag = "h3"
				element[:content] = line[4..-1]
			elsif line.start_with?("##")
				tag = "h2"
				element[:content] = line[3..-1] 
				last_location = element[:content]
			elsif line.start_with?("#")
				tag = "h1"
				element[:content] = line[2..-1] 
				last_split = element[:content] if element[:content].downcase.include?("split")
			elsif line.start_with?("!tr")
				if line.start_with?("!trm")
					element[:class] = "mand"
				end
				tag = "trainer"
				trainer = line.split(" ")[1]
				element[:id] = trainer.to_i

				if element[:id] == 0
					parsed_trainer = trainer.split("/") 
					tr_name = parsed_trainer[0]
					mon_lvl = parsed_trainer[2].to_i
					mon_name = parsed_trainer[1]

					if mon_name.to_i > 0
						mon_lvl = mon_name.to_i
						element[:id] = Trpok.search trdata, trpok, tr_name, mon_lvl, ""
					else
						element[:id] = Trpok.search trdata, trpok, tr_name, mon_lvl, mon_name
					end	
				end
				tr_data = {id: element[:id], name: tr_name}
				
				# set pointer to previous trainer
				tr_data[:prev] = prev_tr_id
				
				# set pointer of previous trainer to current trainer if it exists
				if prev_tr_index
					tr_ids[prev_tr_index][:next] = element[:id]
				end

				# update previous trainer to current trainer
				prev_tr_id = element[:id]
				tr_count += 1
				prev_tr_index = tr_count - 1

				tr_ids << tr_data


				element[:notes] = line.split(" ")[2..-1]
			elsif line.start_with?("!enc")
				# tag = "encounter"
				

				# element[:id] = line[5..-1].to_i
				
				# #if searching by location name
				# if element[:id] == 0
				# 	element[:id] = Encounter.search(encounters, line[5..-1].strip)
				# end
			else
				tag = "p"
				element[:content] = line
			end
			element[:tag] = tag
			sheet_items << element
		end
		tr_id_hash = {}
		tr_ids.each do |tr|
			tr_id_hash[tr[:id].to_i] = tr
		end
		File.write("#{$rom_name}/mastersheet_tr_ids.json", JSON.pretty_generate(tr_id_hash))
		tr_ids.map do |n| 
			"#{n[:id]} (#{n[:name]})"
		end
	end

	def self.add_pointers_to_npoint
		tr_ids = JSON.parse(File.read("#{$rom_name}/mastersheet_tr_ids.json"))
		npoint = JSON.parse(File.read("#{$rom_name}/npoint.json"))["formatted_sets"]
		tr_ids.each_with_index do |tr, i|

		end

	end

	def self.handle(element)
		"<#{element[:tag]}>#{h(element[:content])}</#{element[:tag]}>"
	end


	def self.h(text)
	    Rack::Utils.escape_html(text)
	end


	def self.get_pok(id)
		
	end




end
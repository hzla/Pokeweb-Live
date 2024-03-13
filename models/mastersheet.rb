class Mastersheet


	def self.parse encounters, trdata, trpok
		source = File.open("#{$rom_name}/mastersheet.txt").read.split("\n")
		sheet_items = []
		
		source.each do |line|
			next if line == ""
			element = {}
			if line.start_with?("###")
				tag = "h3"
				element[:content] = line[4..-1] 
			elsif line.start_with?("##")
				tag = "h2"
				element[:content] = line[3..-1] 
			elsif line.start_with?("#")
				tag = "h1"
				element[:content] = line[2..-1] 
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
		sheet_items
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
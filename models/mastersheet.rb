class Mastersheet


	def self.parse
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
				tag = "trainer"
				element[:id] = line.split(" ")[1].to_i
				element[:notes] = line.split(" ")[2..-1]
			elsif line.start_with?("!enc")
				tag = "encounter"
				element[:id] = line[5..-1].to_i
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
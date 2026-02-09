class Mastersheet


	def self.export_json
	  encs = Encounter.get_all
	  Trpok.fill_in_natures_and_abilities
	  trpok_info = Trpok.get_all
	  trdata_info = Trdata.get_all
	  personals = Personal.poke_data

	  master_data = parse(encs, trdata_info, trpok_info)
	  encounters_by_id = Encounter.mastersheet_data(encs)

	  i = 0
	  trainers_by_id = Trpok.get_all.map do |tr|
	    
	    trdata_info_file = trdata_info[i]
	    num_pokemon = trdata_info_file["num_pokemon"]

	    (0..num_pokemon - 1).each do |n|
	    	# Detect alt forms
	    	form = tr["form_#{n}"] 

	    	if form > 0
	    		species = tr["species_id_#{n}"]
	    		if !(["Arceus", "Deerling"].include?(species))
						
	    			# Update name
						species_name = tr["species_id_#{n}"].titleize

						if !RomInfo.form_info[species_name]
							p "No form info available for #{species_name} on Trainer #{i}"
							next
						end
						species_name += "-#{RomInfo.form_info[species_name][form - 1]}"
						tr["species_id_#{n}"] = species_name.upcase

						# Update Ability
						alt_form_personal_file_index = personals[tr["raw"]["species_id_#{n}"]]["form_id"] + form - 1
						alt_form_personal_file = personals[alt_form_personal_file_index]
						ability_index = tr["ability_#{n}"]

						tr["ability_name_#{n}"] = alt_form_personal_file["ability_#{[ability_index, 1].max}"].titleize
					end
	    	end

	    	# Get correct AI exclusive ability

	    	ability_index = tr["ability_#{n}"]

	    	if ability_index > 3
	    		tr["ability_name_#{n}"] = Trpok.aiAbilities[tr["raw"]["species_id_#{n}"]][ability_index - 4]
	    	end
	    end
			ms_trainer = tr
	    ms_trainer["type"] = trdata_info_file["battle_type_1"]
			# Clear the raw section to save space 
	    ms_trainer["raw"] = nil
	    i += 1
	    ms_trainer
	  end

	  payload = {
	    "masterData" => master_data,
	    "encountersById" => encounters_by_id,
	    "trainersById" => trainers_by_id
	  }

	  rom_title = $rom_name.split("/")[-1]

	  File.open("public/scripts/#{rom_title}_mastersheet.js", "w") do |file|
	    file.puts "masterData ="
	    file.puts JSON.pretty_generate(master_data)

	    file.puts "encountersById ="
	    file.puts JSON.pretty_generate(encounters_by_id)

	    file.puts "trainersById ="
	    file.puts JSON.pretty_generate(trainers_by_id)

	    file.puts "highlights ="
	    file.puts JSON.pretty_generate(highlighted_elements)
	  end

	  payload
	end

	# Gets all 
	def self.highlighted_elements
		rom_title = $rom_name.split("projects/")[1]

		to_highlight = {"new" => {}, "changed" => {}}

		if File.exist?("exports/dex/#{rom_title}.js")
			rom_data = JSON.parse File.read("exports/dex/#{rom_title}.js")[12..-1] 
		else
			return to_highlight
		end

		rom_data["items"].each do |item, desc|
			if desc["new"] == true
				to_highlight["new"][item] = 1
			end
			if desc["oldDesc"] 
				to_highlight["changed"][item] = 1
			end
		end

		rom_data["moves"].each do |item, desc|
			if desc["new"] == true
				to_highlight["new"][item.clean] = 1
			end
			if desc["oldDesc"] 
				to_highlight["changed"][item.clean] = 1
			end
		end

		rom_data["abilities"].each do |item, desc|
			if desc["new"] == true
				to_highlight["new"][item] = 1
			end
			if desc["oldDesc"]
				to_highlight["changed"][item] = 1
			end
		end
		to_highlight
	end



	def self.parse(encounters, trdata, trpok)
	  source = File.open("#{$rom_name}/mastersheet.txt").read.split("\n")

	  tr_ids = []
	  sheet_items = []
	  last_location = ""
	  last_split = ""
	  prev_tr_id = nil
	  prev_tr_index = nil
	  tr_count = 0

		i = 0
		while i < source.length
		  raw_line = source[i]
		  element = {}

		  line = raw_line.to_s.gsub("\t", "  ").rstrip
		  stripped = line.strip

		  # LINE BREAK SUPPORT (blank lines)
			if stripped == ""
				sheet_items << {content: "", content_parts: {type: "text", text: ""}, tag: "p" }
			  i += 1
			  next
			end

		  # !gifts <title> ... end
			if stripped.start_with?("!gifts")
			  title = stripped.sub("!gifts", "").strip
			  i += 1
			  gifts_desc, gift_list, gift_descs, end_i = _parse_block_list(source, i)

			  element[:tag] = "gifts"
			  element[:giftsTitle] = title
			  element[:giftsDescription] = gifts_desc
			  element[:giftPokemonList] = gift_list
			  element[:giftPokemonDescriptions] = gift_descs

			  sheet_items << element
			  i = (end_i < source.length && source[end_i].to_s.strip.downcase == "end") ? end_i + 1 : end_i
			  next
			end

			# !items <title> ... end
			if stripped.start_with?("!items")
			  title = stripped.sub("!items", "").strip
			  i += 1
			  items_desc, item_list, item_descs, end_i = _parse_block_list(source, i)

			  element[:tag] = "items"
			  element[:itemsTitle] = title
			  element[:itemsDescription] = items_desc
			  element[:itemList] = item_list
			  element[:itemDescriptions] = item_descs

			  sheet_items << element
			  i = (end_i < source.length && source[end_i].to_s.strip.downcase == "end") ? end_i + 1 : end_i
			  next
			end

			# !notif TITLE, text..., optionalColor
			if stripped.start_with?("!notif")
			  payload = stripped.sub("!notif", "").strip
			  parts = payload.split(",").map(&:strip)

			  title = parts[0] || ""
			  font = nil
			  text_parts = []

			  if parts.length >= 3 && _is_color_token?(parts[-1])
			    font = parts[-1]
			    text_parts = parts[1..-2]
			  else
			    text_parts = parts[1..-1]
			  end

			  element[:tag] = "notif"
			  element[:notificationTitle] = title
			  element[:text] = (text_parts || []).join(",").strip
			  element[:fontColor] = font if font

			  sheet_items << element
			  i += 1
			  next
			end

	    element = {}

	    if line.start_with?("####")
	      tag = "h4"
	      element[:content] = line[5..-1]
	      element[:content_parts] = parse_inline(element[:content])

	    elsif line.start_with?("###")
	      tag = "h3"
	      element[:content] = line[4..-1]
	      element[:content_parts] = parse_inline(element[:content])

	    elsif line.start_with?("##")
	      tag = "h2"
	      element[:content] = line[3..-1]
	      last_location = element[:content]
	      element[:content_parts] = parse_inline(element[:content])

	    elsif line.start_with?("#")
	      tag = "h1"
	      element[:content] = line[2..-1]
	      last_split = element[:content] if element[:content].downcase.include?("split")
	      element[:content_parts] = parse_inline(element[:content])

	    # BULLETS
	    elsif line.start_with?("- ") || line.start_with?("* ")
	      tag = "li"
	      element[:content] = line[2..-1]
	      element[:content_parts] = parse_inline(element[:content])

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
	          element[:id] = Trpok.search(trdata, trpok, tr_name, mon_lvl, "")
	        else
	          element[:id] = Trpok.search(trdata, trpok, tr_name, mon_lvl, mon_name)
	        end
	      end

	      tr_data = { id: element[:id] }
	      tr_data[:prev] = prev_tr_id

	      if prev_tr_index
	        tr_ids[prev_tr_index][:next] = element[:id]
	      end

	      prev_tr_id = element[:id]
	      tr_count += 1
	      prev_tr_index = tr_count - 1
	      tr_ids << tr_data

	      element[:notes] = line.split(" ")[2..-1]
	      # Optional: allow links in notes too
	      if element[:notes] && !element[:notes].empty?
	        element[:notes_parts] = parse_inline(element[:notes].join(" "))
	      end

	    elsif line.start_with?("!enc")
	      tag = "encounter"
	      element[:id] = line[5..-1].to_i
	      if element[:id] == 0
	        element[:id] = Encounter.search(encounters, line[5..-1].strip)
	      end

	    else
	      # PARAGRAPH + INLINE <br> SUPPORT
	      tag = "p"
	      # If you want <br> inside a line, split and emit multiple p/br
	      chunks = split_with_line_breaks(line)
	      if chunks.length > 1
	        chunks.each_with_index do |chunk, idx|
	          chunk = chunk.strip
	          next if chunk == ""
	          sheet_items << { tag: "p", content: chunk, content_parts: parse_inline(chunk) }
	          sheet_items << { tag: "br" } if idx < chunks.length - 1
	        end
	        next
	      else
	        element[:content] = line
	        element[:content_parts] = parse_inline(line)
	      end
	    end

	    element[:tag] = tag
	    sheet_items << element
	    i += 1
	  end

	  tr_id_hash = {}
	  tr_ids.each { |tr| tr_id_hash[tr[:id].to_i] = tr }
	  File.write("#{$rom_name}/mastersheet_tr_ids.json", JSON.pretty_generate(tr_id_hash))

	  sheet_items
	end

	def self.parse_inline(text)
  parts = []
  i = 0

  while i < text.length
    # Markdown link: [text](url)
    if text[i] == "["
      close_bracket = text.index("]", i)
      if close_bracket && text[close_bracket + 1] == "("
        close_paren = text.index(")", close_bracket + 2)
        if close_paren
          link_text = text[(i + 1)...close_bracket]
          href = text[(close_bracket + 2)...close_paren]
          parts << { type: "link", text: link_text, href: href }
          i = close_paren + 1
          next
        end
      end

      # IMPORTANT: not a valid markdown link; consume '[' as text
      parts << { type: "text", text: "[" }
      i += 1
      next
    end

    # Bare URL (optional)
    if text[i..].start_with?("http://") || text[i..].start_with?("https://")
      j = i
      j += 1 while j < text.length && !text[j].match?(/\s/)
      url = text[i...j]
      parts << { type: "link", text: url, href: url }
      i = j
      next
    end

    # Accumulate plain text until next '[' or 'http'
    next_bracket = text.index("[", i)
    next_http    = text.index("http://", i)
    next_https   = text.index("https://", i)

    next_special = [next_bracket, next_http, next_https].compact.min

    if next_special
      if next_special > i
        parts << { type: "text", text: text[i...next_special] }
      end
      i = next_special
    else
      parts << { type: "text", text: text[i..] }
      break
    end
  end

  # merge adjacent text parts
  merged = []
  parts.each do |p|
    if p[:type] == "text" && merged.any? && merged[-1][:type] == "text"
      merged[-1][:text] << p[:text]
    else
      merged << p
    end
  end
  merged
end

	def self.split_with_line_breaks(text)
	  # Supports explicit <br> tokens inside a line
	  text.split(/\s*<br>\s*/i)
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
	  tag = element[:tag]

	  # 1) Line breaks
	  return "<p></p>" if tag == "p"

	  # 2) Rich inline content (links) if present
	  inner =
	    if element[:content_parts].is_a?(Array) && !element[:content_parts].empty?
	      element[:content_parts].map do |part|
	        case part[:type]
	        when "text"
	          h(part[:text].to_s)
	        when "link"
	          text = h(part[:text].to_s)
	          href = h(part[:href].to_s)

	          # Basic safety: only allow http(s) links (prevents javascript: etc.)
	          if href.start_with?("http://", "https://")
	            %Q(<a href="#{href}" target="_blank" rel="noopener noreferrer">#{text}</a>)
	          else
	            # Fallback: render as text if it's not a safe scheme
	            text
	          end
	        else
	          h(part.to_s)
	        end
	      end.join
	    else
	      # 3) Old behavior
	      h(element[:content].to_s)
	    end

	  "<#{tag}>#{inner}</#{tag}>"
	end

	def self.h(text)
	    Rack::Utils.escape_html(text)
	end


	def self.get_pok(id)
		
	end

	def self._is_color_token?(s)
  return false if s.nil?
  t = s.strip
  return true if t.match?(/\A#[0-9a-fA-F]{3}\z/)
  return true if t.match?(/\A#[0-9a-fA-F]{6}\z/)
  return true if t.match?(/\Argb\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\)\z/i)
  return true if t.match?(/\Argba\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*(0(\.\d+)?|1(\.0+)?)\s*\)\z/i)
  return true if t.match?(/\A[a-zA-Z]+\z/) # loose named-color support
  false
end

def self._parse_block_list(source, start_i)
  list = []
  descs = []
  desc = ""

  i = start_i
  while i < source.length
    line = source[i].to_s.strip
    break if line.downcase == "end"

    if line != ""
      if line.match?(/\A(desc|description)\s*:\s*/i)
        desc = line.sub(/\A(desc|description)\s*:\s*/i, "").strip
      else
        name, rest = line.split(",", 2).map { |x| x&.strip }
        list << (name || "")
        descs << (rest && rest != "" ? rest : nil)
      end
    end

    i += 1
  end

  [desc, list, descs, i] # i points at 'end' or source.length
end




end
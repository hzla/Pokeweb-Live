class Text 

	def self.get_all narc_name
		file_path = "#{$rom_name}/#{narc_name}/texts.json"
		data = JSON.parse(File.open(file_path, "r"){|f| f.read})
	end

	def self.get_bank narc_name, bank_id
		file_path = "#{$rom_name}/#{narc_name}/texts.json"
		data = JSON.parse(File.open(file_path, "r"){|f| f.read})
		bank = data[bank_id.to_i]
	end

	def self.write_ppre_bank narc_name="message_texts", bank_id=381
		bank = get_bank narc_name, bank_id
		
		#convert ppre bank to beatertext format
		formatted_bank = {}
		bank.each_with_index do |entry, i|
			formatted_entry = entry[1].gsub('\\r', '\c').split('\\n')

			formatted_entry.each_with_index do |line, i|
				if i < formatted_entry.length - 1
					formatted_entry[i] += "\\n"
				end
			end

			formatted_bank[i.to_s] = formatted_entry
		end

		edit_bank narc_name, bank_id, formatted_bank
	end

	def self.handle_compressed text, bank, msg_id
		if text.include?("xF100")
			text = bank[msg_id][1] + "     "
		end
		text
	end

	def self.insert_text idx, text_data, bank_id=381, narc_name="message_texts"
		bank = get_bank narc_name, bank_id
		text_id = "0_#{idx}"

		#insert text
		bank.insert(idx, [text_id, text_data])

		
		#update idx for all other banks
		bank[idx+1..-1].each do |bank|
			old_id = bank[0].split("_")[-1]
			new_id = (old_id.gsub(/\D/, '').to_i + 1).to_s
			bank[0] = bank[0].gsub("_#{old_id}", "_#{new_id}")
		end
		banks = get_all(narc_name)
		banks[bank_id] = bank

		File.open("#{$rom_name}/#{narc_name}/texts.json", "w") { |f| f.write banks.to_json }


		p "Inserted into Bank #{bank_id} at index #{idx}"
	end

	def self.delete_text idx, bank_id=381, narc_name="message_texts"
		bank = get_bank narc_name, bank_id

		bank.delete_at(idx)

		bank[idx..-1].each do |bank|
			old_id = bank[0].split("_")[-1]
			new_id = (old_id.gsub(/\D/, '').to_i - 1).to_s
			bank[0] = bank[0].gsub("_#{old_id}", "_#{new_id}")
		end
		banks = get_all(narc_name)
		banks[bank_id] = bank

		File.open("#{$rom_name}/#{narc_name}/texts.json", "w") { |f| f.write banks.to_json}
		p "Deleted from Bank #{bank_id} at index #{idx}"
	end

	def self.edit_bank narc, bank_id, bank
		open("#{$rom_name}/#{narc}/#{bank_id}_edited.txt", 'w') do |f|
			n = 0
			until !bank[n.to_s]
				f.puts "# STR_#{n}"
				entry = bank[n.to_s]
				entry.each_with_index do |line, j|	
					prefix = "\""
					suffix = "\","

					#first line
					prefix = "[\"" if j == 0
					#last line
					suffix = "$\"]" if j == entry.length - 1

					f.puts (prefix + line + suffix)
				end
				f.puts
				n += 1
			end
			f.puts "END_MSG"
		end



		command = "dotnet tools/beatertext/BeaterText.dll -m #{$rom_name}/#{narc}/#{bank_id}_edited.txt #{$rom_name}/#{narc}/#{bank_id}.bin"
		pid = spawn command
		Process.detach(pid)
	end




	def self.write_data data
		file_path = "#{$rom_name}/#{data['narc']}/texts.json"
		banks = JSON.parse(File.open(file_path, "r"){|f| f.read})

		bank_info = data['field'].split('_')
		bank_id = bank_info[1].to_i
		entry_id = bank_info[-1].to_i


		banks[bank_id][entry_id][1] = data['value']

		File.open(file_path, "w") { |f| f.write banks.to_json }


	end

	def self.search narc_name, terms, ignore_case=false
		file_path = "#{$rom_name}/#{narc_name}/texts.json"
		texts = JSON.parse(File.open(file_path, "r"){|f| f.read})

		results = texts.map do |text_bank|
			if text_bank
				text_bank.select do |line|
					search_terms = /(?<!\\)#{terms.downcase}/
						
					if line[1]
						if ignore_case
							(line[1].downcase =~ search_terms)
						else
							(line[1] =~ search_terms)
						end
					else
						false
					end				
				end
			else
				false
			end
		end
		results
	end


end




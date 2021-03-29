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
					search_terms = /(?<!\\)#{terms}/
						
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




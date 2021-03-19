class Trpok


	def self.get_all
		trainers = []
		files = Dir["#{$rom_name}/json/trpok/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			json = JSON.parse(File.open("#{$rom_name}/json/trpok/#{n}.json", "r").read)
			tr_data = json["readable"]

			trainers[n] = tr_data
		end
		trainers
	end

	def self.get_poks_for count, trainer_poks
		poks = []
		(0..count-1).each do |n|
			if trainer_poks["species_id_#{n}"]
				poks << trainer_poks["species_id_#{n}"].gsub(". ", "-").downcase
			end
		end
		poks
	end

	def self.write_data data

	end
end


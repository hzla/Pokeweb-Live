class Trdata


	def self.get_data(file_name)
		JSON.parse(File.open(file_name, "r").read)["readable"]
	end

	def self.names
		File.open('Reference_Files/trainer_names.txt', "r").read.split("\n")
	end

	def self.class_names
		File.open("#{$rom_name}/texts/tr_classes.txt", "r").read.split("\n")	
	end

	def self.sprite_name_for(trainer, names, i)
		sprite_name = trainer["class"].downcase.gsub(" ", "_").gsub("pkmn", "pokemon").gsub("__", "_")

		class_prefix = sprite_name.split("_")[0]
		if class_prefix == "leader" || class_prefix == "elite" || class_prefix == "champion" ||class_prefix == "subway"
			sprite_name = names[i]
		end

		"trainer_sprites/#{sprite_name}.png"
	end

	def self.get_all
		trainers = []
		files = Dir["#{$rom_name}/json/trdata/*.json"]
		file_count = files.length

		(0..file_count - 1).each do |n|
			json = JSON.parse(File.open("#{$rom_name}/json/trdata/#{n}.json", "r").read)
			tr_data = json["readable"]

			trainers[n] = tr_data
		end
		trainers
	end

	def self.has_items? trainer
		"checked" if trainer["template"] > 1
	end

	def self.has_moves? trainer
		"checked" if (trainer["template"] == 1 || trainer["template"] == 3)
	end



	def self.write_data data

	end


end


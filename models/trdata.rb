class Trdata < Pokenarc


	def self.write_data data, batch=false
		@@narc_name = "trdata"
		super
	end

	def self.get_all
		@@narc_name = "trdata"
		super
	end




	def self.names
		if SessionSettings.base_rom == "BW"
			file_name = "#{$rom_name}/message_texts/texts.json"
			names = JSON.parse(File.open(file_name, "r"){|f| f.read})[190]

			# File.open('Reference_Files/trainer_names.txt', "r").read.split("\n")
		else
			file_name = "#{$rom_name}/message_texts/texts.json"
			names = JSON.parse(File.open(file_name, "r"){|f| f.read})[382]
		end
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

	def self.ais
		["Prioritize Effectiveness",
		"Evaluate Attacks",
		"Expert",
		"Prioritize Status",
		"Risky Attacks",
		"Prioritize Damage",
		"Partner",
		"Double Battle",
		"Prioritize Healing",
		"Utilize Weather",
		"Harassment",
		"Roaming Pokemon",
		"Safari Zone",
		"Catching Demo"]
	end

	def self.has_items? trainer
		"checked" if trainer["has_items"] > 0
	end

	def self.has_moves? trainer
		"checked" if trainer["has_moves"] > 0
	end

end


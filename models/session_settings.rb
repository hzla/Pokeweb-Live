class SessionSettings

	def self.rom_name
		if File.exist?('session_settings.json')
			contents = File.open("#{$rom_name}/session_settings.json", "r") do |f|
				f.read
			end
			return ( JSON.parse(contents)["rom_name"]) if contents != ""
		else
			nil
		end
		nil
	end


	def self.fairy?
		if File.exist?("#{$rom_name}/session_settings.json")
			contents = File.open("#{$rom_name}/session_settings.json", "r") do |f|
				f.read
			end
			return ( JSON.parse(contents)["fairy"]) if contents != ""
		else
			nil
		end
		nil
	end

	def self.calc_settings
		contents = File.open("calculator_settings.json", "r") do |f|
			f.read
		end
		JSON.parse(contents)
	end

	def self.global_settings
		contents = File.open("global_settings.json", "r") do |f|
			f.read
		end
		JSON.parse(contents)
	end

	def self.base_rom
		settings = File.open("#{$rom_name}/session_settings.json", "r") do |f|
			f.read
		end
		if settings
			JSON.parse(settings)["base_rom"]
		else
			nil
		end
	end

	def self.reset
		current_settings = File.open("#{$rom_name}/session_settings.json", "r") do |f|
			f.read
		end

		File.open("#{$rom_name}/session_settings.json", "w")do |f|
			f.write(current_settings)
		end
		
		settings = File.open("#{$rom_name}/session_settings.json", "w") do |f|
			f.write("")
		end
	end

	def self.set field, value
		current_settings = File.open("#{$rom_name}/session_settings.json", "r") do |f|
			f.read
		end
		current_settings = JSON.parse current_settings
		current_settings[field] = value
		
		
		settings = File.open("#{$rom_name}/session_settings.json", "w") do |f|
			f.write(JSON.pretty_generate(current_settings))
		end
	end

	def self.get field, rom_name=nil
		$rom_name = rom_name if rom_name
		current_settings = File.open("#{$rom_name}/session_settings.json", "r") do |f|
			f.read
		end
		current_settings = JSON.parse current_settings
		current_settings[field]
	end

	def self.load_project project_name
		project_settings = File.open("#{project_name}/session_settings.json", "r") do |f|
			f.read
		end
		File.open("#{$rom_name}/session_settings.json", "w") do |f|
			f.write project_settings
		end
	end
end
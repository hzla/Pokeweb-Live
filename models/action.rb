class Action

	def self.randomize_encs
		old_gym_caps = load_file('base_rom_level_caps') 
		target_gym_viabilities = load_file('gym_viabilities')


		encounter_count = Encounter.get_all.length

		(0..encounter_count - 1).each do |n|
			p "randomizing enc file #{n}"
			lvl =  Encounter.get_max_level n
			next_gym_lvl = nil
			next_gym_range = nil



			target_gym_viabilities.each do |gym|
				if lvl <= gym['lvl']
					next_gym_lvl = gym['lvl']
					next_gym_range = gym['range']
					break
				end
			end

			next_gym_lvl = target_gym_viabilities[-1]['lvl'] if !next_gym_lvl
			next_gym_range = target_gym_viabilities[-1]['range'] if !next_gym_range

			p "lvl #{next_gym_lvl - 6}"
			p next_gym_range
			rand_enc = Randomizer.create_encounter [next_gym_range[0] - 30, next_gym_range[1] - 30], [1, next_gym_lvl - 6].max



			Randomizer.apply_encounter rand_enc, n




		end
	end

	def self.load_file file_name
		JSON.parse(File.read("randomizer/#{file_name}.json"))
	end



end
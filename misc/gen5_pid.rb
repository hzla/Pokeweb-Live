
def get_pid(trainer_id, trainer_class, pok_id, pok_iv, pok_lvl, ability_gender, personal_gender, trainer_gender, ability_slot)

	seed = trainer_id + pok_id + pok_iv + pok_lvl

	trainer_class.times do 
		seed = seed * 0x5D588B656C078965 + 0x269EC3
	end

	pid = (((seed >> 32) & 0xFFFFFFFF) >> 16 << 8) + get_gender_ab(ability_gender, personal_gender, trainer_gender, ability_slot)
end

def get_gender_ab(ability_gender, personal_gender, trainer_gender, ablity_slot)
	result = trainer_gender ? 125 : 136
	g = ability_gender & 0xF
	a = (ability_gender & 0xF0) >> 4

	if ability_gender != 0

		if g!= 0
			result = personal_gender
			if g == 1
				result += 2
			else
				result -= 2
			end
		end

		case ability_slot
		when 0
			result
		when 1
			result &= 0xFFFFFFFE
		else 
			result |= 1
		end
	end
	result
end

natures = ["Hardy",
	"Lonely",
	"Brave",
	"Adamant",
	"Naughty",
	"Bold",
	"Docile",
	"Relaxed",
	"Impish",
	"Lax",
	"Timid",
	"Hasty",
	"Serious",
	"Jolly",
	"Naive",
	"Modest",
	"Mild",
	"Quiet",
	"Bashful",
	"Rash",
	"Calm",
	"Gentle",
	"Sassy",
	"Careful",
	"Quirky"]

pid = get_pid(164,2,504,0, 6, 0, 127, true, 0)
nature = natures[(pid >> 8) % 25]

p pid.to_s(16)



# puts pid(164,2,504,0, 5, 0, 127, false, 0).to_s(16)
# puts pid(164,2,504,0, 6, 0, 127, false, 0).to_s(16)


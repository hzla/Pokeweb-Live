def prng level, species, difficulty, trainer_id, trainer_class, gender
	seed = (level.to_i + species.to_i + difficulty.to_i + trainer_id.to_i).to_s(16)

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

	result = 0
	trainer_class.to_i.times do 
		seed = seed.to_i(16)
		result = 0x41C64E6D * seed + 0x00006073
		seed = result.to_s(16)[-8..-1]


	end
	result = seed[0..-5]

	mid_bytes = result[-4..-1]
	low_bytes = ""

	if gender == "male"
		low_bytes = "88"
	else
		low_bytes = "78"
	end
	
	high_bytes = "00"

	pid =  high_bytes + mid_bytes + low_bytes
	nature_index = pid.to_i(16).to_s[-2..-1].to_i % 25

	puts "#{difficulty} IV: #{natures[nature_index]}"
end 


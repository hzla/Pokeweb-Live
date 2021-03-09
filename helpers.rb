def bin_to_hex(s)
  s.unpack('H*').first
end

def hex_to_bin(s)
  s.scan(/../).map { |x| x.hex }.pack('c*')
end

def stringified_data data
	characters = data.split("").map do |byte|
		bin_to_hex byte
	end
	characters.join().scan(/.{1,4}/).join(' ')
end

def to_narc_format data
	data.split(" ").join("").scan(/.{2}/).map {|byte| hex_to_bin byte}.join
end

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

	natures[nature_index]
end 

def unpack_narc narc
	narc = NarcFile.open(narc)
	parsed_data = {}
	files = narc.elements
	parsed_data["file_count"] = files.count
	parsed_data["files"] = {}
	binding.pry
	files.each do |f|
		parsed_data["files"][f["name"]] = stringified_data(f["data"])
	end
	parsed_data
end


class String
  def titleize
  	if self == ""
  		return "-"
  	end
    gsub("-", " ").split(/([ _-])/).map(&:capitalize).join
  end

  def squish!
    gsub!("\n", '')
    self
  end
end

def to_gen(pok_id)
	case pok_id
	when 0..151
	  gen = "gen1"
	when 152..251
	  gen = "gen2"
	when 252..386
	  gen = "gen3"
	when 387..493
	  gen = "gen4"
	when 494..649
	  gen = "gen5"
	when 650..721
	  gen = "gen6"
	when 722..809
	  gen = "gen7"
	when 810..898
	  gen = "gen8"
	else
	  gen = ""
	end
	gen
end
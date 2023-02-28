require 'json'

expert = JSON.parse(File.read("expert.json"))

new_expert = {}

expert.each do |id, lines|
	new_expert[id] = []
	lines.each do |line|

		if line.include?("IF_STAT_")
			params = line.split(",")
			direction = params[0].split("\t")[1].split("_").last
			checking = params[0].split("\t").last.split("_").last
			stat = params[1].split("_")[1]
			under = params[2]
			jumpto = params.last
			line = "If #{stat} of #{checking} is #{direction} #{under},#{jumpto}"
		end
		new_expert[id] << line
	end
end


File.write("expert2.json", new_expert.to_json)


# expert = File.read("expert_ai.txt").split("\n")
# effects = File.read("effects.txt").split("\n")

# current_effect = 0

# ais = {}

# expert.each do |line|
# 	if line.include?(":")
# 		effect_code = line.split("_")[1].gsub(":", "").to_i

		

# 		if effect_code != current_effect
# 			current_effect = effect_code
# 		end
		


# 		if ais[effect_code]
# 			ais[effect_code] << line
# 		else
# 			ais[effect_code] = [line]
# 		end

# 	else
# 		if line.include?("HAVE_MOVE_EFFECT")
# 			move_effect = line.split(",")[1]
# 			line = line.gsub(move_effect, effects[move_effect.to_i])
# 		end



# 		ais[current_effect] << line


# 	end
# end

# def disp(ai)
# 	ai.each {|n| puts n}
# end

# p disp(ais[1])

# File.write("expert.json", ais.to_json)






# move_names = File.read("../projects/B/texts/moves.txt").split("\n")
# abilities = File.read("../projects/B/texts/abilities.txt").split("\n")

# j_names = File.read("j_moves.txt").split("\n")
# j_abilities = File.read("j_abilities.txt").split("\n")


# translations = {}
# ab_translations = {}


# j_names.each do |n|
# 	info = n.split(" ")
# 	eng = move_names[info[1].to_i].gsub(" ", "_")
# 	translations[info[0]] = eng
# end

# j_abilities.each do |n|
# 	info = n.split(" ")
# 	eng = abilities[info[1].to_i].gsub(" ", "_")
# 	ab_translations[info[0]] = eng
# end




# ai = File.read("tr_ai_seq.s")

# translations.each do |k,v|
# 	ai = ai.gsub(k, "MOVE_#{v}")
# end

# ab_translations.each do |k,v|
# 	ai = ai.gsub(k, "ABILITY_#{v}")
# end



# File.write("ai.s", ai)
# risky = [1,7,9,38,43,49,83,88,89,98,118,120,122,140,142,144,170,185,199,219,226,227,230,241,248]

# status = [10,11,12,13,14,15,16,18,19,20,21,22,23,24,30,35,54,47,49,50,51,52,53,54,55,56,58,59,60,61,62,63,64,65,66,67,79,84,108,109,118,213,187,156,165,166,167,181,192,199,205,206,208,211,213,225,226,240,252,258,261]

# effects = File.read("effects.txt").split("\n")


# def get_all directory
# 	moves = {}

# 	Dir["#{directory}/json/moves/*.json"].each do |move|
# 		move_data = JSON.parse(File.open(move, "r"){|f| f.read})["readable"]
# 		move_data["effect_id"] = JSON.parse(File.open(move, "r"){|f| f.read})["raw"]["effect"]

# 		move_id = move_data["index"]
# 		moves[move_id] = move_data
# 	end
# 	moves = moves.to_a.sort_by {|mov| mov[0] }
# 	moves
# end


# moves = get_all "../documentation/vanilla"
# risky_moves = []
# moves.each do |move|
# 	if risky.include?(move[1]["effect_id"])
# 		risky_moves << "#{move[1]["name"]}: #{move[1]["effect"]}"
# 	end
# end

# status_moves = []

# moves.each do |move|
# 	if status.include?(move[1]["effect_id"])
# 		status_moves << "#{move[1]["name"]}: #{move[1]["effect"]}"
# 	end
# end









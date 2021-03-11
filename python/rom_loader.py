import ndspy
import ndspy.rom, ndspy.bmg
import ndspy.narc
import code 
import io
import codecs
import os
import json
import msg_reader
from personal_reader import output_personal_json
from learnset_reader import output_learnset_json
from moves_reader import output_moves_json

# code.interact(local=dict(globals(), **locals()))


#################### CREATE FOLDERS #############################

rom_name = "moddedblack.nds".split(".")[0] 

# code.interact(local=dict(globals(), **locals()))

if not os.path.exists(f'{rom_name}'):
    os.makedirs(f'{rom_name}')

for folder in ["narcs", "texts", "json"]:
	if not os.path.exists(f'{rom_name}/{folder}'):
		os.makedirs(f'{rom_name}/{folder}')

################# HARDCODED ROM INFO ##############################

BW_NARCS = [["a/0/1/6", "personal"], 
["a/0/1/7", "growth"],
["a/0/1/8", "learnsets"],
["a/0/1/9", "evolution"], 
["a/0/2/0", "babyforms"],
["a/0/2/1","moves"],
["a/0/2/4", "items"],
["a/0/9/1", "trdata"],
["a/0/9/2", "trpok"],
["a/1/2/7", "encounters"],
["a/0/0/3", "storytext"],
["a/0/0/2", "messagetext"],
["a/0/5/6", "scripts"]]

BW_MSG_BANKS = [[286, "moves"],
[199, "types"],
[202, "move_descriptions"],
[285, "abilities"],
[183, "ability_descriptions"],
[284, "pokedex"],
[191, "tr_classes"],
[190, "tr_names"],
[54, "items"],
[89, "locations"]]

################### EXTRACT RELEVANT NARCS #######################

narc_info = {} ##store narc names and file id pairs

with open(f'{rom_name}.nds', 'rb') as f:
    data = f.read()
rom = ndspy.rom.NintendoDSRom(data)

for narc in BW_NARCS:
	file_id = rom.filenames[narc[0]]
	file = rom.files[file_id]
	parsed_file = ndspy.narc.NARC(file)
	
	narc_info[narc[1]] = file_id # store file ID for later
	
	with open(f'{rom_name}/narcs/{narc[1]}-{file_id}.narc', 'wb') as f:
	    f.write(file)


#############################################################

################### EXTRACT RELEVANT TEXTS ##################

msg_file_id = narc_info['messagetext']

for msg_bank in BW_MSG_BANKS:
	text = msg_reader.parse_msg_bank(f'{rom_name}/narcs/messagetext-{msg_file_id}.narc', msg_bank[0])

	with codecs.open(f'{rom_name}/texts/{msg_bank[1]}.txt', 'w') as f:
	    for block in text:
	    	for entry in block:
	    		# print(entry)
	    		try:
	    			f.write(entry)
	    		except UnicodeEncodeError:
	    			print("error")
	    			# f.write(str(entry.encode("UTF-8")))
	    		f.write("\n")


##############################################################
################### WRITE SESSION SETTINGS ###################

settings = {}
settings["rom_name"] = rom_name
settings["base_rom"] = "Pokemon Black"
settings.update(narc_info)

with open(f'session_settings.json', "w") as outfile:  
	json.dump(settings, outfile) 

#############################################################
################### CONVERT TO JSON #########################


personal_narc_data = ndspy.narc.NARC(rom.files[narc_info["personal"]])
output_personal_json(personal_narc_data)

learnset_narc_data = ndspy.narc.NARC(rom.files[narc_info["learnsets"]])
output_learnset_json(learnset_narc_data)

moves_narc_data = ndspy.narc.NARC(rom.files[narc_info["moves"]])
output_moves_json(moves_narc_data)


### TODO IMPLEMENT READERS FOR OTHER NARCS



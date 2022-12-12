import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import codecs
import os
import json
import sys
import msg_reader2
from header_reader import output_headers_json
from msg_reader2 import output_texts


# code.interact(local=dict(globals(), **locals()))


#################### CREATE FOLDERS #############################

rom_name = "projects/" + sys.argv[1].split(".")[0] 

# code.interact(local=dict(globals(), **locals()))

if not os.path.exists(f'{rom_name}'):
    os.makedirs(f'{rom_name}')

for folder in ["narcs", "texts", "json", "message_texts", "story_texts"]:
	if not os.path.exists(f'{rom_name}/{folder}'):
		os.makedirs(f'{rom_name}/{folder}')

################# HARDCODED ROM INFO ##############################

NARCS = [["a/0/1/2", "headers"],["a/0/0/2", "message_texts"], ["a/0/0/3", "story_texts"]]
BW_MSG_BANKS = [[89, "locations"]]
BW2_MSG_BANKS = [[109, "locations"]]
MSG_BANKS = []


################### EXTRACT RELEVANT BW_NARCS AND ARM9 #######################

narc_info = {} ##store narc names and file id pairs

with open(f'{rom_name.split("/")[-1]}.nds', 'rb') as f:
    data = f.read()

rom = ndspy.rom.NintendoDSRom(data)


## check if T to deal with SAK
if str(rom.name)[-3] == '2' or str(rom.name)[-3] == 'T' :
	narc_info["base_rom"] = "BW2"
	MSG_BANKS = BW2_MSG_BANKS
	narc_info["base_version"] = str(rom.name)[20] + "2"
else:
	narc_info["base_rom"] = "BW"
	MSG_BANKS = BW_MSG_BANKS
	narc_info["base_version"] = str(rom.name)[20]

# code.interact(local=dict(globals(), **locals()))

for narc in NARCS:
	file_id = rom.filenames[narc[0]]
	file = rom.files[file_id]
	narc_file = ndspy.narc.NARC(file)

	# extract text banks
	if narc[1][-5:] == "texts":
		output_texts(f"{rom_name}/{narc[1]}", narc_file)


	narc_info[narc[1]] = file_id # store file ID for later


	
	with open(f'{rom_name}/narcs/{narc[1]}-{file_id}.narc', 'wb') as f:
	    f.write(file)

	# f = open(f'{rom_name}/narcs/{narc[1]}-{file_id}.narc', 'rb')
	# print(len(f.read()))


#############################################################

################### EXTRACT RELEVANT TEXTS ##################

msg_file_id = narc_info['message_texts']

with open(f'{rom_name}/message_texts/texts.json', 'r') as f:
	messages = json.load(f)
	
	for msg_bank in MSG_BANKS:
		text = messages[msg_bank[0]]

		with open(f'{rom_name}/texts/{msg_bank[1]}.txt', 'w+') as outfile:
			for line in text:
				line[1] = line[1].replace("―", "").replace("⑮", " F").replace("⑭", " M").replace("⒆⒇", "PkMn").replace("é", "e").encode("ascii", "ignore").decode()

				outfile.write(line[1] + "\n")


##############################################################
################### WRITE SESSION SETTINGS ###################

settings = {}
settings["rom_name"] = rom_name
settings.update(narc_info)

with open(f'session_settings.json', "w") as outfile:  
	json.dump(settings, outfile) 
	print(settings)





#############################################################
################### CONVERT TO JSON #########################

headers_narc_data = ndspy.narc.NARC(rom.files[narc_info["headers"]])
output_headers_json(headers_narc_data)





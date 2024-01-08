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
from msg_reader2 import output_scripts
from msg_reader2 import output_move_scripts


# code.interact(local=dict(globals(), **locals()))


#################### CREATE FOLDERS #############################

rom_name = "projects/" + sys.argv[1].split(".")[0]
pw = sys.argv[2] 

# code.interact(local=dict(globals(), **locals()))

if not os.path.exists(f'{rom_name}'):
    os.makedirs(f'{rom_name}')

for folder in ["narcs", "texts", "json", "message_texts", "story_texts", "scripts", "move_scripts"]:
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

print("decompressing arm9")
rom = ndspy.rom.NintendoDSRom(data)
arm9 = ndspy.codeCompression.decompress(rom.arm9)
arm9_sample = int.from_bytes(arm9[14:16], 'little')
version_identifier = {15395: ["B2","BW2"], 63038: ["W2","BW2"], 43676: ["B","BW"], 4581: ["W","BW"]}

narc_info["base_version"] = version_identifier[arm9_sample][0]
narc_info["base_rom"] = version_identifier[arm9_sample][1]

with open(f'{rom_name}/arm9.bin', 'wb') as f:
	f.write(arm9)


if narc_info["base_rom"] == "BW2":
	MSG_BANKS = BW2_MSG_BANKS
else:
	MSG_BANKS = BW_MSG_BANKS
	# NARCS[3][0] = "a/0/5/7"


use_vanilla_banks = False
for narc in NARCS:
	print(narc)
	file_id = rom.filenames[narc[0]]
	file = rom.files[file_id]

	if narc[1] == "scripts":
		with open(f'a056.narc', 'wb') as f:
			f.write(file)

	try:
		narc_file = ndspy.narc.NARC(file)
	except:
		if narc[1] == "message_texts":
			print("Ctrmap edited texts detected, switching to vanilla text banks")
			use_vanilla_banks = narc_info["base_version"]




	

	# extract text banks
	if narc[1][-5:] == "texts":
		output_texts(f"{rom_name}/{narc[1]}", narc_file, use_vanilla_banks)

	if narc[1] == "scripts":
		output_scripts(f"{rom_name}/scripts", narc_file)




	narc_info[narc[1]] = file_id # store file ID for later


	
	# with open(f'{rom_name}/narcs/{narc[1]}-{file_id}.narc', 'wb') as f:
	#     f.write(file)


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
settings["pw"] = pw
settings.update(narc_info)
if use_vanilla_banks:
	settings["disable_text_exports"] = True
else:
	settings["disable_text_exports"] = False

with open(f'{rom_name}/session_settings.json', "w") as outfile:  
	json.dump(settings, outfile) 
	print(settings)





#############################################################
################### CONVERT TO JSON #########################

headers_narc_data = ndspy.narc.NARC(rom.files[narc_info["headers"]])
output_headers_json(headers_narc_data, rom_name)





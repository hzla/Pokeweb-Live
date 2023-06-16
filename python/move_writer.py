import ndspy
import ndspy.rom
import ndspy.narc
import code 
import copy
import sys
import rom_data
import tools
import json
import subprocess

# code.interact(local=dict(globals(), **locals()))

def output_narc(rom, rom_name):
	
	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		ROM_NAME = settings["rom_name"]

		if ("output_spas" in settings) and settings["output_spas"]:
			narc_id = settings["move_spas"]
			narcfile_path = f'{rom_name}/narcs/move_spas-{narc_id}.narc'
			narc = ndspy.narc.NARC.fromFile(narcfile_path)
			narc.endiannessOfBeginning = ">"

			rom.files[narc_id] = narc.save()
			print("spas saved")

		for ani in ["move_animations", "battle_animations"]:
			narc_id = settings[ani]
			narcfile_path = f'{rom_name}/narcs/{ani}-{narc_id}.narc'

			narc = ndspy.narc.NARC.fromFile(narcfile_path)
			narc.endiannessOfBeginning = ">"

			rom.files[narc_id] = narc.save()



	return tools.output_narc("moves", rom, rom_name)

def decompile_script(rom_name, move_id):
	if move_id > 559:
		ani = "battle_animations"
		offset = 561
	else:
		ani = "move_animations"
		offset = 0

	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		narc_id = settings[ani]
		narcfile_path = f'{rom_name}/narcs/{ani}-{narc_id}.narc'
		narc = ndspy.narc.NARC.fromFile(narcfile_path)
		script = narc.files[move_id - offset]

		f = open(f"{rom_name}/move_scripts/{move_id}.bin", "wb")
		f.write(script)
		f.close()

		subprocess.run(["python3", "python/MovScrCMDDecompiler.py", f"{rom_name}/move_scripts/{move_id}.bin", '>', f"{rom_name}/move_scripts/{move_id}.txt"], check=True)

def compile_script(rom_name, move_id):
	if move_id > 559:
		ani = "battle_animations"
		offset = 561
	else:
		ani = "move_animations"
		offset = 0
	# arm-none-eabi-as <decompiled> -o tmp.elf && arm-none-eabi-objcopy -O binary tmp.elf <output>
	subprocess.run(["arm-none-eabi-as", f"{rom_name}/move_scripts/{move_id}.txt", "-o", "tmp.elf"], check=True)
	subprocess.run(["arm-none-eabi-objcopy", "-O", 'binary', 'tmp.elf', f"{rom_name}/move_scripts/{move_id}.bin"], check=True)

	with open(f'{rom_name}/session_settings.json', "r") as outfile:  
		settings = json.load(outfile) 
		narc_id = settings[ani]
		narcfile_path = f'{rom_name}/narcs/{ani}-{narc_id}.narc'
		narc = ndspy.narc.NARC.fromFile(narcfile_path)
		
		narc.files[move_id - offset] = open(f"{rom_name}/move_scripts/{move_id}.bin", "rb").read()


		f = open(narcfile_path, "wb")
		f.write(narc.save())
		f.close()







def write_readable_to_raw(file_name, narc_name="moves", skip_ani=False):
	tools.write_readable_to_raw(file_name, narc_name, to_raw)


def to_raw(readable):
	raw = copy.deepcopy(readable)


	raw["type"] = rom_data.TYPES.index(readable["type"].lower().capitalize())

	raw["effect_category"] = rom_data.EFFECT_CATEGORIES.index(readable["effect_category"])
	
	raw["category"] = rom_data.CATEGORIES.index(readable["category"].lower().capitalize())

	#special case for tri attack
	if readable["result_effect"] == "Chance of either Paralyzing; Burning; or Freezing target":
		raw["result_effect"] = 65535
	else:
	
		raw["result_effect"] = rom_data.RESULT_EFFECTS.index(raw["result_effect"].lower().capitalize())

	# code.interact(local=dict(globals(), **locals()))
	raw["effect"] = rom_data.EFFECTS.index(raw["effect"])

	raw["status"] = rom_data.STATUSES.index(raw["status"])

	if readable["recoil"] > 0:
		raw["recoil"] = 256 - readable["recoil"]

	raw["target"] = rom_data.TARGETS.index(raw["target"])

	raw["stat_1"] = rom_data.STATS.index(readable["stat_1"])
	raw["stat_2"] = rom_data.STATS.index(readable["stat_2"])
	raw["stat_3"] = rom_data.STATS.index(readable["stat_3"])

	if readable["magnitude_1"] < 0:
		raw["magnitude_1"] = readable["magnitude_1"] + 256

	if readable["magnitude_2"] < 0:
		raw["magnitude_2"] = readable["magnitude_2"] + 256

	if readable["magnitude_3"] < 0:
		raw["magnitude_3"] = readable["magnitude_3"] + 256

	binary_hits = ""
	hits = ["max_hits", "min_hits"]
	for hit in hits:
		binary_hits += bin(readable[hit])[2:].zfill(4)
	raw["hits"] = int(binary_hits, 2)

	binary_props = ""
	rom_data.PROPERTIES.reverse()

	
	for prop in rom_data.PROPERTIES:
		binary_props += bin(readable[prop])[2:].zfill(1)
	raw["properties"] = int(binary_props, 2)

	# set animation
	animations_file_path = f'{rom_data.ROM_NAME}/narcs/move_animations-{rom_data.ANIMATION_ID}.narc'
	b_animations_file_path = f'{rom_data.ROM_NAME}/narcs/battle_animations-{rom_data.B_ANIMATION_ID}.narc'

	# for non expanded moves
	if readable["animation"] != 0:

		if readable["index"] < 673:
			animations = ndspy.narc.NARC.fromFile(animations_file_path)
			animations.files[readable["index"]] = animations.files[readable["animation"]]
			# code.interact(local=dict(globals(), **locals()))
			with open(animations_file_path, 'wb') as f:
				f.write(animations.save())
		else: # for expanded moves
			animations = ndspy.narc.NARC.fromFile(animations_file_path)
			b_animations = ndspy.narc.NARC.fromFile(b_animations_file_path)
			# code.interact(local=dict(globals(), **locals()))
			if rom_data.BASE_ROM == "BW2":
				offset = 561
			else:
				offset = 561
			try:
				b_animations.files[readable["index"] - offset] = animations.files[readable["animation"]]
				print(readable["animation"])
			except:
				print("animation out of bounds")
				b_animations.files[readable["index"] - offset] = animations.files[1]
			
			print(len(b_animations.files))
			with open(b_animations_file_path, 'wb') as f:
				f.write(b_animations.save())



	return raw
	
################ If run with arguments #############

if len(sys.argv) > 2:
	rom_data.set_global_vars(sys.argv[3])
	file_names = sys.argv[2].split(",")
	 

	if sys.argv[1] == "update": 
		for file_name in file_names:
			write_readable_to_raw(int(file_name))
	elif sys.argv[1] == "decompile":
		for file_name in file_names:
			decompile_script(sys.argv[3], int(file_name))
	else: #compile
		for file_name in file_names:
			compile_script(sys.argv[3], int(file_name))




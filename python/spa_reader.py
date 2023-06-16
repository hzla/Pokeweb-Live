import io
import json
import sys
import re
import os
import ndspy
import ndspy.rom
import ndspy.narc



## BEFORE USE: name any files to be opened with extension .spa and place in a folder named "spas"

## TO READ ###############

## USAGE: python spa_reader.py NAME_OF_SPA_FILE PATH_TO_SPAS_FOLDER -r

## EXAMPLE python spa_reader.py 171 ./ -r

## EXPECTED OUTPUT: ./spas/171_spa.json, raw texture data ./spas/171_texture_N.bin, and parsed texture json ./spas/171_parsed_texture_N.json

### TO WRITE ############

## USAGE: python spa_reader.py NAME_OF_SPA_FILE PATH_TO_SPAS_FOLDER -w
## EXAMPLE python spa_reader.py 171 ./ -w

## EXPECTED OUTPUT: ./spas/171_edited.spa
## Writer will look for ./spas/171_spa.json and the associated texture .bin files



###### SPA BLOCK FORMATS ###########

SPA_HEADER = [[8, "title"],
[2, "particle_count"],
[2, "texture_count"],
[4, "header_padding_1"],
[4, "particle_block_size"],
[4, "texture_block_size"],
[4, "texture_block_offset"],
[4, "header_padding_2"]]

PARTICLE_BLOCK = [[4, "flags"],
[4, "base_position_x"],
[4, "base_position_y"],
[4, "base_position_z"],
[4, "base_frame_count"],
[4, "base_radius"],
[4, "base_length"],
[2, "base_axis_x"],
[2, "base_axis_y"],
[2, "base_axis_z"],
[2, "base_color"],
[4, "base_velocity_position"],
[4, "base_velocity_axis"],
[4, "base_scale"],
[2, "base_aspect_ratio"],
[2, "base_delay"],
[2, "min_rotation"],
[2, "max_rotation"],
[2, "base_rotation"],
[2, "particle_padding_1"],
[2, "emitter_duration"],
[2, "particle_duration"],
[1, "random_base_scale"],
[1, "particle_life"],
[1, "base_velocity"],
[1, "particle_padding_2"],
[1, "frame_interval"],
[1, "base_alpha"],
[1, "air_resistance"],
[1, "texture_index"],
[1, "frames_per_loop"],
[2, "billboard_scale"],
[1, "texture_loop_flags"],
[4, "texture_position_flags"],
[2, "offset_x"],
[2, "offset_y"],
[4, "unknown_1"]]

TEXTURE_BLOCK = [[4, "signature"],
[4, "texture_parameters"],
[4, "texture_size"],
[4, "pallete_offset"],
[4, "pallete_size"],
[4, "pallete_index_offset"],
[4, "pallete_index_size"],
[4, "total_size"]]


########### PARTICLE BLOCK FLAGS ############

FORMATS = {}

FORMATS["SCALE_ANIMATION_FLAG"] = 9
FORMATS["COLOR_ANIMATION_FLAG"] = 10
FORMATS["ALPHA_ANIMATION_FLAG"] = 11
FORMATS["TEXTURE_ANIMATION_FLAG"] = 12
FORMATS["ROTATION_ANIMATION_FLAG"] = 13
FORMATS["RANDOM_ROTATATION_FLAG"] = 14

FORMATS["SELF_DESTRUCT_FLAG"] = 15
FORMATS["FOLLOW_EMITTER_FLAG"] = 16
FORMATS["CHILD_FLAG"] = 17

FORMATS["POLYGON_REFERENCE_FLAG"] = 20
FORMATS["RANDOM_LOOP_FLAG"] = 21
FORMATS["RENDER_CHILD_FIRST_FLAG"] = 22
FORMATS["RENDER_PARENT_FLAG"] = 23
FORMATS["VIEWPORT_OFFSET_FLAG"] = 24

FORMATS["GRAVITY_FLAG"] = 25
FORMATS["RANDOM_FLAG"] = 26
FORMATS["MAGNET_FLAG"] = 27
FORMATS["ROTATION_FLAG"] = 28
FORMATS["COLLISION_FLAG"] = 29
FORMATS["CONVERGENCE_FLAG"] = 30
FORMATS["CONSTANT_ID_FLAG"] = 31
FORMATS["CONSTANT_CHILD_ID_FLAG"] = 32

FLAG_FORMATS = ["SCALE_ANIMATION", "COLOR_ANIMATION", "ALPHA_ANIMATION", "TEXTURE_ANIMATION", "CHILD", "GRAVITY", "RANDOM", "MAGNET","ROTATION", "COLLISION", "CONVERGENCE"]

FORMATS["SCALE_ANIMATION"] = [[2, "scale_start"],
[2, "scale_interval"],
[2, "scale_end"],
[1, "scale_fade_in"],
[1, "scale_fade_out"],
[2, "scale_animation_padding"],
[2, "scale_animation_padding2"]
]

FORMATS["COLOR_ANIMATION"] = [[2, "color_start"],
[2, "color_end"],
[1, "color_fade_in"],
[1, "color_fade_hold"],
[1, "color_fade_out"],
[1, "color_fade_padding"],
[2, "color_padding"],
[2, "color_padding_2"]
]

FORMATS["ALPHA_ANIMATION"] = [[4, "alpha_info"],
[1, "alpha_fade_in"],
[1, "alpha_fade_out"],
[2, "alpha_unknown"]]

FORMATS["TEXTURE_ANIMATION"] = [[8, "texture_animation_list"],
[1, "texture_animation_index"],
[1, "texture_animation_diffusion"],
[2, "texture_animation_random_loop_flags"]]

FORMATS["CHILD"] = [[2, "child_flags"],
[2, "child_base_random_velocity"],
[2, "child_scale_end"],
[2, "child_duration"],
[1, "child_velocity_ratio"],
[1, "child_scale_ratio"],
[2, "child_base_color"],
[1, "child_base_frame_count"],
[1, "child_start_delay"],
[1, "child_frame_interval"],
[1, "child_texture_index"],
[4, "child_texture_position"]]

FORMATS["GRAVITY"] = [[2, "gravity_intensity_x"],
[2, "gravity_intensity_y"],
[2, "gravity_intensity_z"],
[2, "gravity_padding"]]

FORMATS["RANDOM"] = [[2, "random_intensity_x"],
[2, "random_intensity_y"],
[2, "random_intensity_z"],
[2, "random_interval"]]

FORMATS["MAGNET"] = [[4, "magnet_position_x"],
[4, "magnet_position_y"],
[4, "magnet_position_z"],
[2, "magnet_intensity"],
[2, "magnet_padding"]]

FORMATS["ROTATION"] =  [[2, "rotation_radian"],
[2, "rotation_axis"]]

FORMATS["COLLISION"] =  [[4, "collision_y_position"],
[2, "collision_bounce"],
[2, "collision_type"]]

FORMATS["CONVERGENCE"] =  [[4, "convergence_position_x"],
[4, "convergence_position_y"],
[4, "convergence_position_z"],
[2, "convergence_intensity"],
[2, "convergence_padding"]]


RGB_FIELDS = ["base_color", "color_start", "color_end", "child_base_color"]

def parse_a3i5(value):
	color_index = value & 0b11111
	alpha = (value >> 5 & 0b111) / 7 
	alpha = str(round(alpha, 2))
	return [color_index, alpha]

def parse_a5i3(value):
	color_index = value & 0b111
	alpha = value >> 3 & 0b11111
	return [color_index, alpha]

TEX_FORMATERS = {}
TEX_FORMATERS[1] = parse_a3i5
TEX_FORMATERS[6] = parse_a5i3


def write_spa():
	spa = json.load(open(f'{sys.argv[2]}/spas/{sys.argv[1]}_spa.json', "r"))
	stream = bytearray()

	#Write Header
	for entry in SPA_HEADER:
		write_bytes(stream, entry[0], spa[entry[1]])

	# Write Particle BLock
	for particle in spa["particles"]:
		for entry in PARTICLE_BLOCK:
			if entry[1] in RGB_FIELDS:
				particle[entry[1]] = convert_to_rgb5_int(particle[entry[1]])

			write_bytes(stream, entry[0], particle[entry[1]])


		flags = particle["flags"]

		# Write additional particle data depending on found flags
		for flag in FLAG_FORMATS:
			if check_flag(flags, FORMATS[f"{flag}_FLAG"]):
				for flag_entry in FORMATS[flag]:
					if flag_entry[1] in RGB_FIELDS:
						particle[flag_entry[1]] = convert_to_rgb5_int(particle[flag_entry[1]])
					
					write_bytes(stream, flag_entry[0], particle[flag_entry[1]])



	# Write Texture Block

	for idx, texture in enumerate(spa["textures"]):
		for entry in TEXTURE_BLOCK:
			write_bytes(stream, entry[0], texture[entry[1]])


		# Write texture data
		texture_data = open(f"{sys.argv[2]}/spas/{sys.argv[1]}_texture_{idx}.bin", 'rb').read()
		stream += texture_data

		
		pallete_format = get_format(texture["texture_parameters"])

		# Write Pallete
		for color in texture["colors"]:
			rgb5 = convert_to_rgb5_int(color)
			write_bytes(stream, 2, rgb5)

	with open(f'{sys.argv[2]}/spas/{sys.argv[1]}_edited.spa', 'wb') as f:
		f.write(stream)

	return stream

					
def read_spa(data=None, filename=None):
	filename = filename or sys.argv[1]
	data = data or open(f'{sys.argv[2]}/spas/{filename}.spa', "rb").read()
	

	stream = io.BytesIO(data)
	spa = {}
	spa["particles"] = []
	spa["textures"] = []

	#  Parse Header
	for entry in SPA_HEADER:
		value = read_bytes(stream, entry[0])
		spa[entry[1]] = value


	# Parse Particle Block
	for i in range(spa["particle_count"]):
		particle = {}
		for entry in PARTICLE_BLOCK:
			# print(entry[1])
			# print(data[stream.tell():stream.tell() + entry[0]])
			# print(int.from_bytes(data[stream.tell():stream.tell() + entry[0]], 'little'))

			value = read_bytes(stream, entry[0])

			if entry[1] in RGB_FIELDS:
				value = convert_to_rgb(value)
			# print(value)
			particle[entry[1]] = value

			
		flags = particle["flags"]
		
		# Parse additional data depending on found flags
		for flag in FLAG_FORMATS:
			if check_flag(flags, FORMATS[f"{flag}_FLAG"]):
				for flag_entry in FORMATS[flag]:
					value = read_bytes(stream, flag_entry[0])
					
					if flag_entry[1] in RGB_FIELDS:
						value = convert_to_rgb(value)

					particle[flag_entry[1]] = value

		spa["particles"].append(particle)

	# Parse Texture Block
	for i in range(spa["texture_count"]):
		texture = {}
		texture["colors"] = []
		for entry in TEXTURE_BLOCK:
			value = read_bytes(stream, entry[0])
			texture[entry[1]] = value

		# Extract Texture data, usually 4096 bytes
		texture_size = texture["texture_size"]
		texture_data = stream.read(texture_size)
		with open(f'{sys.argv[2]}/spas/{filename}_texture_{i}.bin', "wb") as outfile:  
			outfile.write(texture_data)

		# Convert Texture to pixel info
		stream.seek(stream.tell() - texture_size)

		parsed_texture = []
		tex_format = get_format(texture["texture_parameters"])

		texture["format"] = tex_format

		for n in range(texture_size):
			pixel = read_bytes(stream, 1)

			try:
				parsed_texture.append(TEX_FORMATERS[tex_format](pixel))
			except:
				print(f"File: {filename}, format: {tex_format}")
				return


		with open(f'{sys.argv[2]}/spas/{filename}_parsed_texture_{i}.json', "w") as outfile:  
			json.dump(parsed_texture, outfile, indent=4) 

		# Parse Pallete
		pallete_size = int(texture["pallete_size"] / 2)
		colors = []
		for color_idx in range(pallete_size):
			texture["colors"].append(convert_to_rgb(read_bytes(stream, 2)))
		spa["textures"].append(texture)

	with open(f'{sys.argv[2]}/spas/{filename}_spa.json', "w") as outfile:  
		json.dump(spa, outfile, indent=4) 


def read_bytes(stream, n):
	return int.from_bytes(stream.read(n), 'little')

def write_bytes(stream, n, data):
	stream += (int(data).to_bytes(n, 'little'))		
	return stream

def check_flag(n, k):
	if n & (1 << (k - 1)):
		return True
	else:
		return False

def convert_to_rgb(value):
	value = int(value)
	red = value & 0b11111
	blue = value >> 5 & 0b11111
	green = value >> 10 & 0b11111
	return f"rgb({red*8 },{blue*8 },{green*8 })"

def convert_to_rgb5_int(rgb):
    if rgb[0] == "#":
    	rgb = hex_to_rgb(rgb)

    colors = re.findall(r'[0-9]+', rgb)
    colors.reverse()
    bin_str = "0"
    for color in colors:
    	converted_val = int(int(color) / 8)
    	bin_str += (bin(converted_val)[2:].zfill(5))

    return int(bin_str,2)
    

def parse_a3i5(value):
	color_index = value & 0b11111
	alpha = (value >> 5 & 0b111) / 7 
	alpha = str(round(alpha, 2))
	return [color_index, alpha]

def hex_to_rgb(hex):
	h = hex.lstrip('#')
	h = tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
	return f"rgb{h[0],h[1],h[2]}"

def parse_a5i3(value):
	color_index = value & 0b111
	alpha = (value >> 3 & 0b11111) / 31
	alpha = str(round(alpha, 2))
	return [color_index, alpha]

def get_format(value):
	return value & 0b1111


if __name__ == "__main__":
	if  sys.argv[1][0:3] == "rgb":
		print(convert_to_rgb5_int(sys.argv[1]))

	if  sys.argv[1][0:3] == "int":
		print(convert_to_rgb(sys.argv[1].split("int")[1]))


	
	if len(sys.argv) > 3 and sys.argv[3] == "-r" and sys.argv[1] == "all":
		os.system(f"mkdir {sys.argv[2]}/spas")
		narc = ndspy.narc.NARC.fromFile(f"{sys.argv[2]}/narcs/move_spas-353.narc") 
		for idx, file in enumerate(narc.files):
			read_spa(file, idx )

	elif len(sys.argv) > 3 and sys.argv[3] == "-r":
		narc = ndspy.narc.NARC.fromFile(f"{sys.argv[2]}/narcs/move_spas-353.narc") 

		read_spa(narc.files[int(sys.argv[1])])
	else:
		"Do Nothing"


	if len(sys.argv) > 3 and sys.argv[3] == "-w":
		narc = ndspy.narc.NARC.fromFile(f"{sys.argv[2]}/narcs/move_spas-353.narc") 
		data = write_spa()

		narc.files[int(sys.argv[1])] = data

		with open(f"{sys.argv[2]}/narcs/move_spas-353.narc", 'wb') as f:
			f.write(narc.save())

	



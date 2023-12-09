import ndspy
import ndspy.rom
import ndspy.narc
import sys


# EXTRACTING USAGE: python file_manager.py -extract path_to_rom path_to_narcfile_index 
# EXAMPLE: python file_manager.py -extract my_rom.nds a/0/1/6 1
# EXAMPLE OUTPUT: Outputs a-0-1-6_1.bin to current directory (personal file for personal)


# REPLACING USAGE: python file_manager.py -replace path_to_rom path_to_narc file_index path_to_replacement_file
# EXAMPLE: python file_manager.py -replace my_rom.nds a/0/1/6 1 1.bin
# EXAMPLE OUTPUT: Outputs my_rom_edited.nds to current directory

rom_path = sys.argv[2]
rom_name = rom_path.split('.')[0]
file_path = sys.argv[3]
subfile_name = False

if len(sys.argv) > 4:
	subfile_name = int(sys.argv[4])

rom = ndspy.rom.NintendoDSRom.fromFile(rom_path)
file_to_send = ndspy.narc.NARC(rom.files[rom.filenames[file_path]])

if subfile_name:
	file_to_send = file_to_send.files[subfile_name]

if sys.argv[1] == "-extract":
	file_path = file_path.replace("/","")
	if subfile_name:
		with open(f'exports/{rom_name}_{file_path}_{subfile_name}.bin', 'wb') as f:
			f.write(file_to_send)
	else:
		with open(f'exports/{rom_name}_{file_path}.bin', 'wb') as f:
			f.write(file_to_send.save())


if sys.argv[1] == "-replace":
	input_file = sys.argv[5]
	narc.files[subfile_name] = open(input_file, "rb").read()
	rom.files[rom.filenames[file_path]] = narc.save()
	rom.saveToFile(f"{rom_name}_edited.nds")












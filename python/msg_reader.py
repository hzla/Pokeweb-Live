import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import math


def read16(stream):
	return int.from_bytes(stream.read(2), 'little')

def read32(stream):
	return int.from_bytes(stream.read(4), 'little')

def char_check(v):
    return v & 0xFF == 0xFF

def to_char(v):
    try:
        return chr(v)
    except ValueError:
        return hex(v)

def parse_msg_bank(filepath, msg_bank):
	messages = ndspy.narc.NARC.fromFile(filepath)

	message = messages.files[msg_bank]

	# code.interact(local=dict(globals(), **locals()))
	stream = io.BytesIO(message)

	numblocks = read16(stream)
	numentries = read16(stream)
	filesize = read32(stream)
	zero = read32(stream)

	blockoffsets = [] # uint32 blockoffsets[numblocks]
	tableoffsets = [] # uint32 tableoffsets[numblocks][numentries]
	charcounts = [] # uint16 charcounts[numblocks][numentries]
	textflags = [] # uint16 textflags[numblocks][numentries]

	texts = [] # string texts[numblocks][numentries]

	for i in range(0, numblocks):
		blockoffsets.append(read32(stream))

	for i in range(0, numblocks):
		stream.seek(blockoffsets[i])
		blocksize = read32(stream)
		texts.append([])
		for j in range(0, numentries):
			tableoffsets.append([])
			charcounts.append([])
			textflags.append([])
			texts[i].append([])

			tableoffsets[i].append(read32(stream))
			charcounts[i].append(read16(stream))
			textflags[i].append(read16(stream))
		
		for j in range(0, numentries):
			encchars = [0]
			decchars = [0]
			string = ""
			stream.seek(blockoffsets[i] + tableoffsets[i][j])

			for k in range(0, charcounts[i][j]):
				encchars.append(read16(stream))
			key = encchars[-1] ^ 0xFFFF
			
			while encchars:
				enc = encchars.pop()
				decchars.append(enc ^ key)
				# print(f'enc: {enc}, key: {key}, result: {enc ^ key}')
				key = ((key>>3)|(key<<13))&0xFFFF

			while decchars:
				char = decchars.pop()
				

				if char == 0xFFFF:
					break
				elif char == 0xFFFE:
					string += "\n"
				elif char == 0xF000:
					string += chr(char)
				elif char == 9350:
					string += "PK"
				elif char == 9351:
					string += "MN"
				# CODE FOR DECOMPRESSION GOES HERE
				elif char > 300: 
					# print(decompress.decomp(char))
					continue
				else:
					string += chr(char)

			texts[i][j] = str(string)
	return texts




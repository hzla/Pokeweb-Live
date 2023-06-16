import ndspy
import ndspy.rom
import ndspy.narc
import code 
import io
import math
import struct, re
from binary16 import binaryreader, binarywriter

def read16(stream):
	return int.from_bytes(stream.read(2), 'little')

def read32(stream):
	return int.from_bytes(stream.read(4), 'little')

def parse_msg_bank(filepath, msg_bank):
	messages = ndspy.narc.NARC.fromFile(filepath)
	message = messages.files[msg_bank]
	stream = io.BytesIO(message)

	numblocks = read16(stream)
	numentries = read16(stream)
	filesize = read32(stream)
	zero = read32(stream)

	blockoffsets = [] # uint32 blockoffsets[numblocks]
	texts = [] # string texts[numblocks][numentries]

	for i in range(0, numblocks):
		blockoffsets.append(read32(stream))

	for i in range(0, numblocks):
		stream.seek(blockoffsets[i])
		blocksize = read32(stream)
		tableoffsets = [] 
		charcounts = [] 
		textflags = [] 
		for j in range(numentries):
			tableoffsets.append(read32(stream))
			charcounts.append(read16(stream))
			textflags.append(read16(stream))	
		for j in range(numentries):
			compressed = False
			encchars = []
			string = ""
			stream.seek(blockoffsets[i] + tableoffsets[j])

			for k in range(charcounts[j]):
				encchars.append(read16(stream))
			key = encchars[len(encchars)-1] ^ 0xFFFF
			decchars = []
			
			while encchars:
				char = encchars.pop() ^ key
				key = ((key>>3)|(key<<13))&0xFFFF
				decchars.insert(0, char)

			if decchars[0] == 0xF100:
				compressed = True
				decchars.pop(0)
				newstring = []
				container = 0
				bit = 0
				while decchars:
					container |= decchars.pop(0)<<bit
					bit += 16
					while bit >= 9:
						bit -= 9
						c = container&0x1FF
						if c == 0x1FF:
							newstring.append(0xFFFF)
						else:
							newstring.append(c)
						container >>= 9
				decchars = newstring
			while decchars:
				char = decchars.pop()
				
				if char == 0xFFFF:
					break
				elif char == 0xFFFE:
					string += "\\n"
				elif char < 20 or c > 0xF000:
					string +=  "\\x%04X"%c
				elif char == 0xF000:
					try:
						kind = decchars.pop(0)
						count = decchars.pop(0)
						if kind == 0xbe00 and count == 0:
							string += "\\f"
							continue
						if kind == 0xbe01 and count == 0:
							string += "\\r"
							continue
						string += "VAR("
						args = [kind]
						for k in range(count):
							args.append(decchars.pop(0))
					except IndexError:
						break
					string += ", ".join(map(str, args))
					string += ")"
				else:
					string += chr(c)
			e = "%i_%i"%(i, j)
			flag = ""
			val = textflags[j]
			c = 65
			while val:
				if val&1:
					flag += chr(c)
				c += 1
				val >>= 1
			if compressed:
				flag += "c"
			e += flag
			texts.append([e, string])
	# print(texts)
	return texts




def gen5get(f):
    texts = []
    reader = binaryreader(f)
    
    numblocks = reader.read16()
    numentries = reader.read16()
    filesize = reader.read32()
    zero = reader.read32()
    blockoffsets = []
    for i in range(numblocks):
        blockoffsets.append(reader.read32())
    # filesize == len(f)-reader.pos()
    for i in range(numblocks):
        reader.seek(blockoffsets[i])
        size = reader.read32()
        tableoffsets = []
        charcounts = []
        textflags = []
        for j in range(numentries):
            tableoffsets.append(reader.read32())
            charcounts.append(reader.read16())
            textflags.append(reader.read16())
        for j in range(numentries):
            compressed = False
            encchars = []
            text = ""
            reader.seek(blockoffsets[i]+tableoffsets[j])
            for k in range(charcounts[j]):
                encchars.append(reader.read16())
            key = encchars[len(encchars)-1]^0xFFFF
            decchars = []
            while encchars:
                char = encchars.pop() ^ key
                key = ((key>>3)|(key<<13))&0xFFFF
                decchars.insert(0, char)
            if decchars[0] == 0xF100:
                compressed = True
                decchars.pop(0)
                newstring = []
                container = 0
                bit = 0
                while decchars:
                    container |= decchars.pop(0)<<bit
                    bit += 16
                    while bit >= 9:
                        bit -= 9
                        c = container&0x1FF
                        if c == 0x1FF:
                            newstring.append(0xFFFF)
                        else:
                            newstring.append(c)
                        container >>= 9
                decchars = newstring
            while decchars:
                c = decchars.pop(0)
                if c == 0xFFFF:
                    break
                elif c == 0xFFFE:
                    text += "\\n"
                elif c < 20 or c > 0xF000:
                    text += "\\x%04X"%c
                elif c == 0xF000:
                    try:
                        kind = decchars.pop(0)
                        count = decchars.pop(0)
                        if kind == 0xbe00 and count == 0:
                            text += "\\f"
                            continue
                        if kind == 0xbe01 and count == 0:
                            text += "\\r"
                            continue
                        text += "VAR("
                        args = [kind]
                        for k in range(count):
                            args.append(decchars.pop(0))
                    except IndexError:
                        break
                    text += ", ".join(map(str, args))
                    text += ")"
                else:
                    text += unichr(c)
            e = "%i_%i"%(i, j)
            flag = ""
            val = textflags[j]
            c = 65
            while val:
                if val&1:
                    flag += chr(c)
                c += 1
                val >>= 1
            if compressed:
                flag += "c"
            e += flag
            texts.append([e, text])
    return texts
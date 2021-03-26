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

def to_chr(v):
	try:
		return chr(v)
	except ValueError:
		return hex(v)

def parse_msg_bank(filepath, msg_bank):
	messages = ndspy.narc.NARC.fromFile(filepath)

	message = messages.files[msg_bank]
	readText = io.BytesIO(message)
	readText.seek(0x0)

	names = []

	stringNameCount = read16(readText)
	initialKey = read16(readText)

	key1 = (initialKey * 0x2FD) & 0xFFFF
	key2 = 0
	realKey = 0
	specialCharON = False
	
	currentOffset = [] # currentOffset = new int[stringNameCount];
	currentSize = [] # currentSize = new int[stringNameCount];

	car = 0
	compressed = False

	for i in range(0, stringNameCount):
		key2 = (key1 * (i + 1) & 0xFFFF)
		realKey = key2 | (key2 << 16)
		currentOffset.append( (read32(readText)) ^ realKey)
		currentSize.append((read32(readText)) ^ realKey)


	for i in range(0, stringNameCount):
		key1 = (0x91BD3 * (i + 1)) & 0xFFFF
		readText.seek(currentOffset[i])
		pokemonText = ""

		for j in range(0, currentSize[i]):
			car = read16(readText) ^ key1

			if car == 0xE000 or car == 0x25BC or car == 0x25BD or car == 0xF100 or car == 0xFFFE or car == 0xFFFF:
				
				if car == 0xE000:
					pokemonText += "\n"
				if car == 0x25BC:
					pokemonText += "\r"
				if car == 0x25BD:
					pokemonText += "\f"
				if car == 0xF100:
					compressed = True
				if car == 0xFFFE:
					pokemonText += "\v"
					specialCharON = True

			else:
				if specialCharON == True:
					pokemonText += "{0:#0{1}x}".format(car,6)[2:]
					specialCharON = False
				elif compressed == True:
					shift = 0
					trans = 0
					uncomp = ""

					while True:
						tmp = car >> shift
						tmp1 = tmp

						if shift >= 0xF:
							shift -= 0xF

							if shift > 0:
								tmp1 = (trans | ((car << (9 - shift)) & 0x1FF))

								if ((tmp1 & 0xFF) == 0xFF):
									break

								if tmp1 != 0x0 and tmp != 0x1:
									character = chr(tmp1)
									pokemonText += character

									if not character:
										pokemonText += ("(X)" + "{0:#0{1}x}".format(car,6)[2:])

						else:
							tmp1 = ((car >> shift) & 0x1FF)
							if ((tmp1 & 0xFF) ==  0xFF):
								break

							if (tmp1 != 0x0 and tmp1 != 0x1):
								character = chr(tmp1)
								pokemonText += character

								if not character:
									pokemonText += ("(X)" + "{0:#0{1}x}".format(car,6)[2:])

							shift += 9
							if shift < 0xF:
								trans = ((car >> shift) & 0x1FF)
								shift += 9

							key1 += 0x493D
							key1 &= 0xFFFF

							car = read16(readText) ^ key1
							continue

					pokemonText += uncomp

				else:

					character = chr(car)
					pokemonText += character

					if not character:
						pokemonText += ("(X)" + "{0:#0{1}x}".format(car,6)[2:])

			key1 += 0x493D
			key1 &= 0xFFFF
		
		print(pokemonText)
		names.append(pokemonText)
		compressed = False

	print(names)
	return names




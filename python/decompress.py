def decomp(car, key1):
	shift = 0
	trans= 0
	uncomp = ""
	text = "" 
	while True:
		tmp = car >> shift
		tmp1 = tmp
		print(f'{tmp}, {shift}')
		
		if shift >= 0xF:
			shift -= 0xF
			if shift > 0:
				# if shift <= 9:
				tmp1 = (trans | ((car << (9 - shift)) & 0x1FF))
				# else:
				# 	tmp1 = (trans | ((car >> (shift - 9)) & 0x1FF))
				if ((tmp1 & 0xFF) == 0xFF):
					break
				if (tmp1 != 0x0 and tmp1 != 0x1):
					character = chr(tmp1)
					text += character
					print(text)
					# if character == None:
					# 	text += "\r" + character
		else:
			tmp1 = ((car >> shift) & 0x1FF)
			print(tmp1)
			if ((tmp1 & 0xFF) == 0xFF):
				break

			if (tmp1 != 0x0 and tmp1 != 0x1):
				character = chr(tmp1)
				text += character
				print(text)
				# if character == None:
				# 	text += "\r" + character
			shift += 9
			if shift < 0xF:
				trans = ((car >> shift) & 0x1FF)
				print(f'trans: {trans}')
				shift += 9
			key1 += 0x493D
			key1 &= 0xFFFF
			car = car ^ key1
			print(car)
	return text

print(decomp(56906, 45553))


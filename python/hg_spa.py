import ndspy
import ndspy.rom, ndspy.codeCompression
import ndspy.narc

with open(f'hg.nds', 'rb') as f:
	data = f.read()

rom = ndspy.rom.NintendoDSRom(data)

data = rom.files[158]

with open(f'spas.narc', 'wb') as f:
	f.write(data)
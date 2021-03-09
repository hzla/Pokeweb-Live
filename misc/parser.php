uint16 numblocks = read16()
uint16 numentries = read16()

uint32 filesize = read32()
uint32 zero = read32()

uint32 blockoffsets[numblocks]
uint32 tableoffsets[numblocks][numentries]
uint16 charcounts[numblocks][numentries]
uint16 textflags[numblocks][numentries]

string texts[numblocks][numentries]

for i from 1 to numblocks
    blockoffsets[i] = read32()
for i from 1 to numblocks
    seek(blockoffsets[i])
    uint32 blocksize = read32()
    for j from 1 to numentries
        tableoffsets[i][j] = read32()
        charcounts[i][j] = read16()
        textflags[i][j] = read16()
    for j from 1 to numentries
        $encchars = [0]
        $decchars = [0]
        $string = texts[i][j]
        seek(blockoffsets[i] + tableoffsets[i][j])
        for k from 1 to charcounts[i][j]
            $encchars.append(read16())
        $key = $encchars[-1]
        while $encchars
            $decchars.append($encchars.pop() ^ $key)
            $key = (($key>>3)|($key<<13))&0xFFFF
        while $decchars
            $char = $decchars.pop()
            if $char is 0xFFFF
                break
            else if $char == 0xFFFE
                $string += "\n"
            else if $char == 0xF000
                $string += SPECIAL($char)
            else
                $string += unichr($char)
import re

def write_bytes(stream, n, data):
    stream += (int(data).to_bytes(n, 'little'))     
    return stream



message = open("text.txt", encoding="latin-1")
strings = []
stream = bytearray()
parsing = True

while parsing:
    l = message.readline()
    parsing = l == "END_MSG"

    if l[0] == "[":
        string = ""
        while l[-1] != "]":
            string += re.findall(r'"([^"]*)"', l)[0]
            l = message.readline()

        string += re.findall(r'"([^"]*)"', l)[0]
        string = string.replace("\\c", "\\xF000븁\\x0000");
        string = string.replace("\\l", "\\xF000븀\\x0000");
        string = string.replace("{PLAYER}", "\\xF000Ā\\x0001\\x0000");
        string = string.replace("{RIVAL}", "\\xF000Ā\\x0001\\x0001");
        strings.append(string)
    elif l[0] == "#"
        continue
    else:
        "nothin"

    write_bytes(stream, 2, 1)
    write_bytes(stream, 2, len(strings))

    sectionSize = *(4 + (8 * len(strings)))

    characterCounts = []

    for i in range(0, len(strings)):
        count = 0
        for j in range(0, strings[i]):
            match strings[i][j]:
                case '\\'
                    j += 1
                    match strings[i][j]:
                        case 'x':
                            j += 4
                            break
                        case _:
                            break
                    break
                case _:
                    break

            count += 1

        characterCounts.append(count)
        sectionSize += (count * 2)







# //             b.Write((ushort)0x1); // nSections. We only use 1.
# //             b.Write((ushort)strings.Count); // Number of entries.

# //             uint sectionSize = Convert.ToUInt32(4 + (8 * strings.Count));
# //             List<int> characterCounts = new List<int>();

# //             // Determine each string length;
# //             for (int i = 0; i < strings.Count; i++)
# //             {
# //                 int count = 0;
# //                 for (int j = 0; j < strings[i].Count(); j++)
# //                 {
# //                     switch(strings[i][j])
# //                     {
# //                         case '\\':
# //                             switch (strings[i][++j])
# //                             {
# //                                 case 'x':
# //                                     j += 4;
# //                                     break;
# //                                 default:
# //                                     break;
# //                             }
# //                             break;
# //                         default:
# //                             break;
# //                     }
# //                     count++;
# //                 }
# //                 characterCounts.Add(count);
# //                 sectionSize += Convert.ToUInt32(count * 2);
# //             }

# //             b.Write(sectionSize); // Section size.
# //             b.Write(0); // Unknown.
# //             b.Write(0x10); // Section offset.

# //             // Begin writing the section.
# //             b.Write(sectionSize); // Section size.

# //             int offset = 4 + (8 * strings.Count);
# //             for (int i = 0; i < strings.Count; i++)
# //             {
# //                 b.Write((uint)offset); // Offset.
# //                 b.Write((ushort)characterCounts[i]);
# //                 b.Write((ushort)0x0);
# //                 offset += characterCounts[i] * 0x2;
# //             }

# //             int mainKey = 0x7C89;
# //             for (int i = 0; i < strings.Count; i++)
# //             {
# //                 int key = mainKey;
# //                 for (int j = 0; j < strings[i].Length; j++)
# //                 {
# //                     switch (strings[i][j])
# //                     {
# //                         case '\\':
# //                             switch (strings[i][++j])
# //                             {
# //                                 case 'x':
# //                                     b.Write(EncryptCharacter(strings[i].Substring(j - 1, 6), key));
# //                                     j += 4;
# //                                     break;
# //                                 case 'n':
# //                                     b.Write(EncryptCharacter("\\n", key));
# //                                     break;
# //                                 default:
# //                                     b.Write(EncryptCharacter(strings[i].Substring(j, 2), key));
# //                                     break;
# //                             }
# //                             break;
# //                         default:
# //                             b.Write(EncryptCharacter(strings[i][j].ToString(), key));
# //                             break;
# //                     }
# //                     key = (key << 3 | key >> 13) & 0xFFFF;
# //                 }
# //                 mainKey += 0x2983;
# //                 mainKey = mainKey > 0xFFFF ? mainKey - 0x10000 : mainKey;
# //             }

# //             // We're done... I hope.
# //             b.Close();

# //         }
# //         public ushort EncryptCharacter(string decrypted, int key)
# //         {
# //             switch (decrypted)
# //             {
# //                 case "$":
# //                     return Convert.ToUInt16(0xFFFF ^ key);
# //                 case "\\n":
# //                     return Convert.ToUInt16(0xFFFE ^ key);
# //                 default:
# //                     if (decrypted.StartsWith('\\') && decrypted[1] == 'x')
# //                         return Convert.ToUInt16(ushort.Parse(decrypted.Substring(2),
# //                             System.Globalization.NumberStyles.HexNumber) ^ key);
# //                     else if (decrypted.StartsWith('\\'))
# //                         return Convert.ToUInt16(decrypted[1] ^ key);
# //                     else
# //                         return Convert.ToUInt16(decrypted[0] ^ key);
# //             }
# //         }
# //     }
# // }
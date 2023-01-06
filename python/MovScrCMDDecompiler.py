from struct import unpack
from setuptools import Command
from yaml import dump, load, Loader
from sys import argv

AddressesPerEntry = 0xE

CommandSet = None
with open('tools/movecommands/MOV_SCRCMD.yml', 'r') as DATA:
    CommandSet = load(DATA, Loader=Loader)
    DATA.close()

with open('B2W2_MOVSCRCMD.s', 'w') as MOVSCRCMD_INC:
    for Index, Command in CommandSet.items():
        MOVSCRCMD_INC.write(f'.macro {Command["Name"]} ')
        SpaceCharacter = " " if Command['Parameters'] is not None else ""
        if Command['Parameters'] is not None:
            for Parameter in Command['Parameters']:
                SpaceCharacter = " " if Command['Parameters'].index(Parameter) != len(Command['Parameters']) - 1 else ""
                MOVSCRCMD_INC.write(f'{Parameter["Name"]}{SpaceCharacter}')
        MOVSCRCMD_INC.write('\n')
        MOVSCRCMD_INC.write(f'.hword {Index}\n')
        if Command['Parameters'] is not None:
            for Parameter in Command['Parameters']:
                match Parameter['Type']:
                    case 'int':
                        MOVSCRCMD_INC.write(f'.word \{Parameter["Name"]}\n')
                    case _:
                        break
        
        MOVSCRCMD_INC.write(f'.endm\n')
        MOVSCRCMD_INC.write(f'\n')
    MOVSCRCMD_INC.close()


with open(argv[1], 'rb') as SCRIPT:
    Addresses = []
    Count = unpack('<L', SCRIPT.read(0x4))[0]
    print(f'.include \"B2W2_MOVSCRCMD.s\"')
    print(f'.align 4')
    print()
    print(f'.word {Count} @ Count')
    for Index in range(Count):
        Addresses += set(unpack('<' + 'L' * AddressesPerEntry, SCRIPT.read(AddressesPerEntry * 0x4)))
        for Address in Addresses:
            for Pass in range(AddressesPerEntry):
                print(f'.word SCRIPT_{Address}')
    print()
    for Address in Addresses:
        SCRIPT.seek(Address)
        print(f'SCRIPT_{Address}:')
        while True:
            CommandIndex = unpack('<H', SCRIPT.read(0x2))[0]
            CommandData = CommandSet[CommandIndex]
            ParameterData = []
            if CommandData['Parameters'] is not None:
                for Parameter in CommandData['Parameters']:
                    match Parameter['Type']:
                        case 'int':
                            ParameterData.append(unpack('<l', SCRIPT.read(0x4))[0])
                        case _:
                            break
            print(' ' * 4, CommandData["Name"], end=' ')
            print(*ParameterData, sep=', ')
            if 'End' in CommandData.keys():
                break
        print()
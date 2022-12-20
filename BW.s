@ Helper Macros
.macro script, address
.word  \address - . - 4
.endm

.macro EndHeader
.hword 0xFD13
.endm

.macro Movement x y
.hword \x
.hword \y
.endm

.macro MovementLabel label
.align 4
\label:
.endm

.macro FunctionLabel label
.align 4
\label:
.endm

@ -----------------
@ Script Commands
.macro Nop 
.hword 0
.endm
                    
.macro Nop2 
.hword 1
.endm
                    
.macro EndScript 
.hword 2
.endm
                    
.macro ReturnAfterDelay p0 
.hword 3
.hword \p0
.endm
                    
.macro CallRoutine p0 
.hword 4
.word (\p0 - .) - 4
.endm
                    
.macro EndRoutine 
.hword 5
.endm
                    
.macro DerefAndReturn 
.hword 6
.endm
                    
.macro PopDerefVar 
.hword 7
.endm
                    
.macro PushStackVar p0 
.hword 8
.hword \p0
.endm
                    
.macro PushStackDerefVar p0 
.hword 9
.hword \p0
.endm
                    
.macro PopStackVar p0 
.hword 10
.hword \p0
.endm
                    
.macro PopStack 
.hword 11
.endm
                    
.macro AddVars 
.hword 12
.endm
                    
.macro SubVars 
.hword 13
.endm
                    
.macro MultiplyVars 
.hword 14
.endm
                    
.macro DivideVars 
.hword 15
.endm
                    
.macro StoreFlag p0 
.hword 16
.hword \p0
.endm
                    
.macro CompareStackVarTo p0 
.hword 17
.hword \p0
.endm
                    
.macro AndDerefToVar p0, p1 
.hword 18
.hword \p0
.hword \p1
.endm
                    
.macro OrDerefToVar p0, p1 
.hword 19
.hword \p0
.hword \p1
.endm
                    
.macro StoreU8Global p0, p1 
.hword 20
.byte \p0
.byte \p1
.endm
                    
.macro StoreU32Global p0, p1 
.hword 21
.byte \p0
.word \p1
.endm
                    
.macro MoveGlobalVars p0, p1 
.hword 22
.byte \p0
.byte \p1
.endm
                    
.macro CompareGlobalVars p0, p1 
.hword 23
.byte \p0
.byte \p1
.endm
                    
.macro CompareGlobalToVar p0, p1 
.hword 24
.byte \p0
.hword \p1
.endm
                    
.macro CompareVarToParam p0, p1 
.hword 25
.hword \p0
.hword \p1
.endm
                    
.macro CompareVars p0, p1 
.hword 26
.hword \p0
.hword \p1
.endm
                    
.macro AddVirtualMachine p0 
.hword 27
.hword \p0
.endm
                    
.macro CallStd p0 
.hword 28
.hword \p0
.endm
                    
.macro EndStd 
.hword 29
.endm
                    
.macro UnconditionalJump p0 
.hword 30
.word (\p0 - .) - 4
.endm
                    
.macro ConditionalJump p0, p1 
.hword 31
.byte \p0
.word (\p1 - .) - 4
.endm
                    
.macro ConditionalCall p0, p1 
.hword 32
.byte \p0
.word (\p1 - .) - 4
.endm
                    
.macro SetMapEventStatusFlag p0 
.hword 33
.hword \p0
.endm
                    
.macro StoreMapTypeChange p0 
.hword 34
.hword \p0
.endm
                    
.macro SetFlag p0 
.hword 35
.hword \p0
.endm
                    
.macro ClearFlag p0 
.hword 36
.hword \p0
.endm
                    
.macro ReadAndStoreFlag p0, p1 
.hword 37
.hword \p0
.hword \p1
.endm
                    
.macro AddToVar p0, p1 
.hword 38
.hword \p0
.hword \p1
.endm
                    
.macro SubFromVar p0, p1 
.hword 39
.hword \p0
.hword \p1
.endm
                    
.macro StoreInVar p0, p1 
.hword 40
.hword \p0
.hword \p1
.endm
                    
.macro CopyVar p0, p1 
.hword 41
.hword \p0
.hword \p1
.endm
                    
.macro StoreDerefVar p0, p1 
.hword 42
.hword \p0
.hword \p1
.endm
                    
.macro MultiplyVar1 p0, p1 
.hword 43
.hword \p0
.hword \p1
.endm
                    
.macro DivideVar1 p0, p1 
.hword 44
.hword \p0
.hword \p1
.endm
                    
.macro ModulusVar1 p0, p1 
.hword 45
.hword \p0
.hword \p1
.endm
                    
.macro LockAll 
.hword 46
.endm
                    
.macro UnlockAll 
.hword 47
.endm
                    
.macro ExecuteSpecialEvent 
.hword 48
.endm
                    
.macro WaitKeypressAB 
.hword 49
.endm
                    
.macro WaitKeypress 
.hword 50
.endm
                    
.macro MusicalMessage p0 
.hword 51
.hword \p0
.endm
                    
.macro EventGrayMessage p0, p1 
.hword 52
.hword \p0
.hword \p1
.endm
                    
.macro NextEventGrayMessage p0, p1 
.hword 53
.hword \p0
.hword \p1
.endm
                    
.macro CloseEventGrayMessage 
.hword 54
.endm
                    
.macro CMD_37 p0 
.hword 55
.hword \p0
.endm
                    
.macro UnassociatedMessage p0, p1 
.hword 56
.hword \p0
.byte \p1
.endm
                    
.macro ClosePositionalMessage 
.hword 57
.endm
                    
.macro PositionalMessage p0, p1, p2, p3 
.hword 58
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro NPCMesssage p0, p1, p2, p3, p4 
.hword 60
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.hword \p4
.endm
                    
.macro NonNPCMessage p0, p1, p2, p3 
.hword 61
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro CloseSpecificMessageOnKeypress 
.hword 62
.endm
                    
.macro CloseMessageOnKeypress 
.hword 63
.endm
                    
.macro ShowMoneyBox p0, p1 
.hword 64
.hword \p0
.hword \p1
.endm
                    
.macro CloseMoneyBox 
.hword 65
.endm
                    
.macro UpdateMoneyBox 
.hword 66
.endm
                    
.macro BorderedMessage p0, p1 
.hword 67
.hword \p0
.hword \p1
.endm
                    
.macro CloseBorderedMessage 
.hword 68
.endm
                    
.macro CheckerMessage 
.hword 69
.endm
                    
.macro CloseCheckerMessage 
.hword 70
.endm
                    
.macro YesNoBox p0 
.hword 71
.hword \p0
.endm
                    
.macro GenderSpecificMessage p0, p1, p2, p3, p4, p5 
.hword 72
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.hword \p4
.hword \p5
.endm
                    
.macro VersionSpecificMessage p0, p1, p2, p3, p4, p5 
.hword 73
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.hword \p4
.hword \p5
.endm
                    
.macro SpikedMessage p0, p1 
.hword 74
.hword \p0
.byte \p1
.endm
                    
.macro CloseAllMessages 
.hword 75
.endm
                    
.macro OTNameToStrbuf p0 
.hword 76
.byte \p0
.endm
                    
.macro SetVarPartyPokemonNick p0, p1 
.hword 84
.byte \p0
.hword \p1
.endm
                    
.macro CMD_56 p0, p1 
.hword 86
.byte \p0
.hword \p1
.endm
                    
.macro SetVarPoke p0, p1 
.hword 87
.byte \p0
.hword \p1
.endm
                    
.macro SetVarNumberBound p0, p1, p2 
.hword 92
.byte \p0
.hword \p1
.hword \p2
.endm
                    
.macro ApplyMovement p0, p1 
.hword 100
.hword \p0
.word (\p1 - .) - 4
.endm
                    
.macro WaitMovement 
.hword 101
.endm
                    
.macro StoreNPCPositionDeref p0, p1 
.hword 102
.hword \p0
.hword \p1
.endm
                    
.macro StoreNPCPosition p0, p1, p2 
.hword 103
.hword \p0
.hword \p1
.hword \p2
.endm
                    
.macro StoreHeroPosition p0, p1 
.hword 104
.hword \p0
.hword \p1
.endm
                    
.macro MakeNPC p0, p1, p2, p3, p4, p5 
.hword 105
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.hword \p4
.hword \p5
.endm
                    
.macro CMD_6A p0, p1 
.hword 106
.hword \p0
.hword \p1
.endm
                    
.macro AddNPC p0 
.hword 107
.hword \p0
.endm
                    
.macro RemoveNPC p0 
.hword 108
.hword \p0
.endm
                    
.macro SetOWPosition p0, p1, p2, p3, p4 
.hword 109
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.hword \p4
.endm
                    
.macro StoreHeroOrientation p0 
.hword 110
.hword \p0
.endm
                    
.macro FacePlayer 
.hword 116
.endm
                    
.macro SoloTrainerBattle p0, p1, p2 
.hword 133
.hword \p0
.hword \p1
.hword \p2
.endm
                    
.macro DoubleTrainerBattle p0, p1, p2 
.hword 134
.hword \p0
.hword \p1
.hword \p2
.endm
                    
.macro EndBattle 
.hword 140
.endm
                    
.macro StoreBattleResult p0 
.hword 141
.hword \p0
.endm
                    
.macro DisableTrainer 
.hword 142
.endm
                    
.macro EventTrainerBattle p0, p1, p2, p3 
.hword 148
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro ChangeMusic p0 
.hword 152
.hword \p0
.endm
                    
.macro FadeToDefaultMusic 
.hword 158
.endm
                    
.macro PlaySound p0 
.hword 166
.hword \p0
.endm
                    
.macro StopSound 
.hword 167
.endm
                    
.macro WaitSound 
.hword 168
.endm
                    
.macro PlayFanfare p0 
.hword 169
.hword \p0
.endm
                    
.macro WaitFanfare 
.hword 170
.endm
                    
.macro PlayCry p0, p1 
.hword 171
.hword \p0
.hword \p1
.endm
                    
.macro WaitCry 
.hword 172
.endm
                    
.macro SetWindowText p0, p1, p2 
.hword 175
.hword \p0
.hword \p1
.hword \p2
.endm
                    
.macro PauseAndClose 
.hword 176
.endm
                    
.macro PauseAndClose2 
.hword 177
.endm
                    
.macro Menu p0, p1, p2, p3, p4 
.hword 178
.byte \p0
.byte \p1
.hword \p2
.byte \p3
.hword \p4
.endm
                    
.macro FadeScreen p0, p1, p2, p3 
.hword 179
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro WaitFade 
.hword 180
.endm
                    
.macro CheckItemBagSpace p0, p1, p2 
.hword 183
.hword \p0
.hword \p1
.hword \p2
.endm
                    
.macro FastWarp p0, p1, p2, p3 
.hword 194
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro TeleportWarp p0, p1, p2, p3, p4 
.hword 196
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.hword \p4
.endm
                    
.macro StoreRandomNumber p0, p1 
.hword 203
.hword \p0
.hword \p1
.endm
                    
.macro StoreDay p0 
.hword 207
.hword \p0
.endm
                    
.macro StoreVersion p0 
.hword 224
.hword \p0
.endm
                    
.macro StoreGender p0 
.hword 225
.hword \p0
.endm
                    
.macro CMD_E3 
.hword 227
.endm
                    
.macro ActivateRelocator p0 
.hword 231
.hword \p0
.endm
                    
.macro AddMoney p0 
.hword 249
.hword \p0
.endm
                    
.macro TakeMoney p0 
.hword 250
.hword \p0
.endm
                    
.macro CheckMoney p0, p1 
.hword 251
.hword \p0
.hword \p1
.endm
                    
.macro StoreSpecies p0, p1 
.hword 254
.hword \p0
.hword \p1
.endm
                    
.macro StoreIfFormChange p0, p1 
.hword 255
.hword \p0
.hword \p1
.endm
                    
.macro CMD_103 p0, p1 
.hword 259
.hword \p0
.hword \p1
.endm
                    
.macro HealPokemon 
.hword 260
.endm
                    
.macro RenamePokemon p0, p1, p2 
.hword 261
.hword \p0
.hword \p1
.hword \p2
.endm
                    
.macro GivePokemon p0, p1, p2, p3 
.hword 268
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro StorePokemonSex p0, p1, p2 
.hword 272
.hword \p0
.hword \p1
.hword \p2
.endm
                    
.macro CMD_127 p0, p1, p2, p3 
.hword 295
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro CMD_128 p0 
.hword 296
.hword \p0
.endm
                    
.macro CMD_129 p0, p1 
.hword 297
.hword \p0
.hword \p1
.endm
                    
.macro CMD_12A p0 
.hword 298
.hword \p0
.endm
                    
.macro CMD_13B p0 
.hword 315
.hword \p0
.endm
                    
.macro MakeCamera 
.hword 319
.endm
                    
.macro StopCamera 
.hword 320
.endm
                    
.macro LockCamera 
.hword 321
.endm
                    
.macro ReleaseCamera 
.hword 322
.endm
                    
.macro MoveCamera p0, p1, p2, p3, p4, p5, p6 
.hword 323
.hword \p0
.hword \p1
.word \p2
.word \p3
.word \p4
.word \p5
.hword \p6
.endm
                    
.macro CMD_144 p0 
.hword 324
.hword \p0
.endm
                    
.macro EndCamera 
.hword 325
.endm
                    
.macro ResetCamera p0 
.hword 327
.hword \p0
.endm
                    
.macro CallEnd 
.hword 330
.endm
                    
.macro CallStart 
.hword 331
.endm
                    
.macro ShowDiploma p0, p1 
.hword 337
.hword \p0
.hword \p1
.endm
                    
.macro CMD_153 p0 
.hword 339
.hword \p0
.endm
                    
.macro OpenInterpoke p0, p1 
.hword 341
.hword \p0
.hword \p1
.endm
                    
.macro CMD_175 p0 
.hword 373
.hword \p0
.endm
                    
.macro CMD_197 p0, p1 
.hword 407
.byte \p0
.byte \p1
.endm
                    
.macro CMD_19A p0 
.hword 410
.hword \p0
.endm
                    
.macro SetStatusCG p0 
.hword 411
.hword \p0
.endm
                    
.macro CMD_1A0 p0 
.hword 416
.hword \p0
.endm
                    
.macro FlashBlackInstant 
.hword 419
.endm
                    
.macro Xtransciever4 
.hword 420
.endm
                    
.macro Xtransciever5 
.hword 421
.endm
                    
.macro CMD_1A6 p0, p1 
.hword 422
.hword \p0
.hword \p1
.endm
                    
.macro Xtransciever7 
.hword 423
.endm
                    
.macro FadeIntoBlack 
.hword 428
.endm
                    
.macro SetVarAffinityCheck p0 
.hword 471
.hword \p0
.endm
                    
.macro CMD_1D8 p0, p1, p2, p3 
.hword 472
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro CMD_1F2 
.hword 498
.endm
                    
.macro CMD_209 p0, p1 
.hword 521
.hword \p0
.hword \p1
.endm
                    
.macro CMD_227 p0, p1 
.hword 551
.hword \p0
.hword \p1
.endm
                    
.macro DetachNPCPair p0, p1, p2, p3, p4, p5 
.hword 591
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.hword \p4
.hword \p5
.endm
                    
.macro CMD_253 p0 
.hword 595
.byte \p0
.endm
                    
.macro CMD_262 p0, p1 
.hword 610
.hword \p0
.hword \p1
.endm
                    
.macro CMD_263 p0 
.hword 611
.hword \p0
.endm
                    
.macro CMD_276 p0, p1 
.hword 630
.hword \p0
.hword \p1
.endm
                    
.macro CMD_290 p0 
.hword 656
.byte \p0
.endm
                    
.macro CMD_29F p0 
.hword 671
.hword \p0
.endm
                    
.macro CMD_2D1 p0 
.hword 721
.hword \p0
.endm
                    
.macro GenerateHollowFromVars p0, p1, p2, p3 
.hword 741
.hword \p0
.hword \p1
.hword \p2
.hword \p3
.endm
                    
.macro Prop2EE p0, p1 
.hword 750
.hword \p0
.hword \p1
.endm
                    
.macro CMD_3E8 
.hword 1000
.endm
                    
.macro CMD_3F3 
.hword 1011
.endm
                    

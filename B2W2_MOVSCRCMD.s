.macro MoveCamera p0 p1 p2 p3 p4
.hword 0
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.endm

.macro ZoomCamera p0 p1 p2 p3 p4 p5 p6 p7 p8 p9
.hword 1
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.endm

.macro CMD_2 p0 p1 p2 p3 p4 p5
.hword 2
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro ShakeScreen p0 p1 p2 p3 p4 p5
.hword 3
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro CMD_4 p0 p1
.hword 4
.word \p0
.word \p1
.endm

.macro CMD_5 
.hword 5
.endm

.macro LoadSPA p0
.hword 6
.word \p0
.endm

.macro DoSPAAnimation p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10
.hword 7
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.word \p10
.endm

.macro DoSPAScreenAnimation p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12 p13 p14
.hword 8
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.word \p10
.word \p11
.word \p12
.word \p13
.word \p14
.endm

.macro DoSPAAnimation2 p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10
.hword 9
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.word \p10
.endm

.macro CMD_a p0 p1 p2 p3 p4 p5 p6 p7 p8 p9
.hword 10
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.endm

.macro CMD_b p0
.hword 11
.word \p0
.endm

.macro DoSPAProjectileAnimation p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10
.hword 12
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.word \p10
.endm

.macro DoSPAProjectileAnimation2 p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12
.hword 13
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.word \p10
.word \p11
.word \p12
.endm

.macro DoSPAProjectileAnimation3 p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10
.hword 14
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.word \p10
.endm

.macro CMD_f p0 p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12
.hword 15
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.word \p10
.word \p11
.word \p12
.endm

.macro DoSPACircleAnimation p0 p1 p2 p3 p4 p5 p6 p7 p8 p9
.hword 16
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.word \p9
.endm

.macro CMD_11 p0 p1 p2 p3 p4 p5 p6
.hword 17
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro ShakeSprite p0 p1 p2 p3 p4 p5 p6
.hword 18
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro MoveSprite p0 p1 p2 p3 p4 p5 p6 p7 p8
.hword 19
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.endm

.macro CMD_14 p0 p1 p2 p3 p4 p5
.hword 20
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro DistortSprite p0 p1 p2 p3 p4 p5 p6
.hword 21
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro TiltSprite p0 p1 p2 p3 p4 p5
.hword 22
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro SpriteOpacity p0 p1 p2 p3 p4 p5
.hword 23
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro CMD_18 p0 p1 p2 p3 p4 p5
.hword 24
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro CMD_19 p0 p1 p2 p3
.hword 25
.word \p0
.word \p1
.word \p2
.word \p3
.endm

.macro FreezeSprite p0 p1
.hword 26
.word \p0
.word \p1
.endm

.macro ChangeColor p0 p1 p2 p3 p4
.hword 27
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.endm

.macro ChangeVisibility p0 p1
.hword 28
.word \p0
.word \p1
.endm

.macro CMD_1d p0 p1
.hword 29
.word \p0
.word \p1
.endm

.macro CMD_1e p0 p1 p2 p3 p4 p5 p6
.hword 30
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro CMD_1f p0
.hword 31
.word \p0
.endm

.macro CMD_20 p0 p1 p2 p3 p4
.hword 32
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.endm

.macro CMD_21 p0 p1 p2 p3 p4 p5 p6 p7
.hword 33
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.endm

.macro CMD_22 p0 p1
.hword 34
.word \p0
.word \p1
.endm

.macro CMD_23 p0
.hword 35
.word \p0
.endm

.macro LoadBackground p0
.hword 36
.word \p0
.endm

.macro MoveBackground p0 p1 p2 p3 p4 p5
.hword 37
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro DistortBackground p0 p1 p2 p3 p4 p5
.hword 38
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro CMD_27 p0 p1
.hword 39
.word \p0
.word \p1
.endm

.macro CMD_28 p0
.hword 40
.word \p0
.endm

.macro CMD_29 p0 p1 p2 p3 p4 p5
.hword 41
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro ChangeBackgroundColor p0 p1 p2 p3 p4
.hword 42
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.endm

.macro ApplyBackground p0 p1
.hword 43
.word \p0
.word \p1
.endm

.macro CMD_2c p0 p1 p2 p3 p4 p5 p6
.hword 44
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro CMD_2d p0 p1 p2 p3 p4 p5 p6
.hword 45
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro CMD_2e p0 p1 p2 p3 p4 p5 p6
.hword 46
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro CMD_2f p0 p1 p2 p3 p4 p5 p6
.hword 47
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro CMD_30 p0 p1
.hword 48
.word \p0
.word \p1
.endm

.macro CMD_31 p0 p1 p2 p3 p4
.hword 49
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.endm

.macro CMD_32 p0
.hword 50
.word \p0
.endm

.macro CMD_33 p0 p1
.hword 51
.word \p0
.word \p1
.endm

.macro PlaySound p0 p1 p2 p3 p4 p5 p6 p7 p8
.hword 52
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.endm

.macro CMD_35 p0
.hword 53
.word \p0
.endm

.macro SwitchAudioSide p0 p1 p2 p3 p4 p5 p6 p7
.hword 54
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.endm

.macro StopSound p0 p1 p2 p3 p4 p5 p6 p7 p8
.hword 55
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.word \p7
.word \p8
.endm

.macro LetCMDsFinish p0
.hword 56
.word \p0
.endm

.macro Wait p0
.hword 57
.word \p0
.endm

.macro AudioContainer p0
.hword 58
.word \p0
.endm

.macro CheckMoveuser p0 p1 p2 p3
.hword 59
.word \p0
.word \p1
.word \p2
.word \p3
.endm

.macro CMD_3c p0 p1 p2 p3
.hword 60
.word \p0
.word \p1
.word \p2
.word \p3
.endm

.macro CMD_3d p0 p1 p2
.hword 61
.word \p0
.word \p1
.word \p2
.endm

.macro CMD_3e p0
.hword 62
.word \p0
.endm

.macro CMD_3f p0
.hword 63
.word \p0
.endm

.macro CMD_40 p0 p1
.hword 64
.word \p0
.word \p1
.endm

.macro CMD_41 p0 p1 p2
.hword 65
.word \p0
.word \p1
.word \p2
.endm

.macro CMD_42 
.hword 66
.endm

.macro PlayPokemonCry p0 p1 p2 p3 p4 p5 p6
.hword 67
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.word \p6
.endm

.macro CMD_44 p0
.hword 68
.word \p0
.endm

.macro CMD_45 p0 p1 p2 p3 p4 p5
.hword 69
.word \p0
.word \p1
.word \p2
.word \p3
.word \p4
.word \p5
.endm

.macro CMD_46 p0 p1 p2
.hword 70
.word \p0
.word \p1
.word \p2
.endm

.macro CMD_47 
.hword 71
.endm

.macro CheckMoveUserElse p0
.hword 72
.word \p0
.endm

.macro CMD_49 
.hword 73
.endm

.macro CallMoveAnimation p0
.hword 74
.word \p0
.endm

.macro CMD_4b p0
.hword 75
.word \p0
.endm

.macro CMD_4c p0
.hword 76
.word \p0
.endm

.macro TerminateMoveScript 
.hword 77
.endm


.syntax unified
.global main

.type main, %function
main:
  bl init
  bl BSP_AUDIO_Buffer
  b playSequenceWithSequencer_Loop
.size main, .-main

playSequenceWithSequencer_Loop:
@ play the sequence and loop it
  mov r0, 38
  ldr r1, =firstsequences
  bl newSequencer
  b playSequenceWithSequencer_Loop


newSequencer:
@ Param:
@ r0 = number 
@ r1 = frequence address
  push {lr,r0-r10}
  
  add r2, r1, r0, lsl 2 @ r2 amptitude address
  add r3, r2, r0, lsl 2 @ r3 waveform address
  add r4, r3, r0, lsl 2 @ r4 duration address

  mov r5, 0 @ r5 index = 0

  newPlayNotesLoop:
    cmp r5, r0
    beq newFinally

    ldr r6, [r1,r5, lsl 2] @ r6 = the frequence of the note
    
    cmp r6, 0
    beq newSilencePart

    cmp r6, 0x20000000
    bge changePart
    b newAudioPart

      changePart:
        ldrb r6, [r1,r5, lsl 2]
        push {r0-r2}
        mov r0, r6
        bl MIDI_To_Frequency
        mov r6, r0
        pop {r0-r2}

    newAudioPart:
      ldr r7, [r3,r5, lsl 2] @ r7 = (tem) the waveform of the note
      cmp r7, 0xa
      beq TriangleNote
      cmp r7, 0xb
      beq SquareNote
      cmp r7, 0xc
      beq SawtoothNote

      TriangleNote:
        ldr r7, [r4,r5,lsl 2] @ r7 = the duration of the note
        ldr r8, [r2,r5,lsl 2] @ r8 = the amptitude of the note
        push {r0-r2}
        mov r0, r6
        mov r1, r7
        mov r2, r8
        bl TriangleSynth
        pop {r0-r2}
        b new_Rest_Of_Sequencer

      SquareNote:
        ldr r7, [r4,r5,lsl 2] @ r7 = the duration of the note
        ldr r8, [r2,r5,lsl 2] @ r8 = the amptitude of the note
        push {r0-r2}
        mov r0, r6
        mov r1, r7
        mov r2, r8
        bl SquareSynth
        pop {r0-r2}
        b new_Rest_Of_Sequencer

      SawtoothNote:
        ldr r7, [r4,r5,lsl 2] @ r7 = the duration of the note
        ldr r8, [r2,r5,lsl 2] @ r8 = the amptitude of the note
        push {r0-r2}
        mov r0, r6
        mov r1, r7
        mov r2, r8
        bl SawtoothSynth
        pop {r0-r2}
        b new_Rest_Of_Sequencer

    newSilencePart:
      ldr r6, [r4,r5, lsl 2]
      push {r0-r2}
      mov r0, r6
      bl silenceWithDuration
      pop {r0-r2}
      b new_Rest_Of_Sequencer

    new_Rest_Of_Sequencer:
      add r5, 1
      b newPlayNotesLoop

  newFinally:
    pop {lr,r0-r10}
    bx lr

SquareSynth:
@ Param:
@ r0 = frquence
@ r1 = duration
@ r2 = amptitute
  push {lr,r0-r9}
  ldr r3, =24030
  udiv r4, r3, r0 @ r4 = how many dots in half of the cycle
  mov r7, r4 @ r7 == r4

  mul r1, r1, r0
  ldr r5, =1000
  udiv r5, r1, r5 @ r5 = duration

  ldr r6, =2
  udiv r6, r2, r6 @ r6 = amptitute / 2 
  mov r8, -1
  mul r8, r8, r6 @ r6 = - amptitute / 2 

  Duration_square:
    cmp r5, 0
    beq rest_Of_Duration_Square
    sub r5, 1
    b LowLoop_Square

  LowLoop_Square:
      cmp r4, 0
      beq TopLoop_Square
      sub r4, 1 
      mov r0, r6 
      bl BSP_AUDIO_OUT_Play_Sample
      b LowLoop_Square

  TopLoop_Square:
      cmp r4, r7
      beq Duration_square
      adds r4, 1
      mov r0, r8
      bl BSP_AUDIO_OUT_Play_Sample     
      b TopLoop_Square

  rest_Of_Duration_Square:
    pop {lr,r0-r9}
    bx lr

SawtoothSynth:
@ Param:
@ r0 = frquence
@ r1 = duration
@ r2 = amptitute
  push {lr,r0-r9}
  ldr r3, =48060
  udiv r4, r3, r0 @ r4 == r5 = how many dots in half of the cycle
  mov r5, r4

  mul r1, r0, r1
  ldr r6, =1000
  udiv r6, r1, r6 @ r6 = duration

  ldr r7, =2
  udiv r7, r2, r7 @ r7 = amplitude / 2
  mov r9, r7
  udiv r8, r2, r5 @ r8 = how many bits to be subtracted

  Duration_Sawtooth:
    cmp r6, 0
    beq rest_Of_Duration_Sawtooth
    sub r6, 1
    mov r4, r5
    mov r7, r9
    
    b subtractLoop

  subtractLoop:
    cmn r4, 0
    beq Duration_Sawtooth
    sub r4, 1
    subs r7, r8 
    mov r0, r7 
    bl BSP_AUDIO_OUT_Play_Sample
    b subtractLoop

  rest_Of_Duration_Sawtooth:
    pop {lr,r0-r9}
    bx lr

TriangleSynth:
@ Param:
@ r0 = frquence
@ r1 = duration
@ r2 = amptitute
  push {lr,r0-r9}
  ldr r3, =24030
  udiv r4, r3, r0 @ r4 == r5 = how many dots in half of the cycle
  mov r5, r4

  mul r1, r0, r1
  ldr r6, =1000
  udiv r6, r1, r6 @ r6 Duration_Triangle

  ldr r7, =2
  udiv r7, r2, r7 @ r7 == r9 = amplitude / 2
  mov r9, r7
  udiv r8, r2, r5 @ r8 = how many bits to be subtracted

  Duration_Triangle:
    cmp r6, 0
    beq rest_Of_Duration_Triangle
    sub r6, 1
    mov r4, r5
    mov r7, r9
    b LowLoop_Tri

  LowLoop_Tri:
    cmp r4, 0 
    beq TopLoop_Tri
    sub r4, 1
    subs r7, r8
    mov r0, r7 
    bl BSP_AUDIO_OUT_Play_Sample 
    b LowLoop_Tri

  TopLoop_Tri:
    cmp r4, r5 
    beq Duration_Triangle
    add r4, 1
    adds r7, r8 
    mov r0, r7
    bl BSP_AUDIO_OUT_Play_Sample
    b TopLoop_Tri

  rest_Of_Duration_Triangle:
    pop {lr,r0-r9}
    bx lr   

silenceWithDuration:
@ Param:
@ r0 = time (ms)
  push {lr,r0-r9}
  ldr r1, =15109 
  mul r0, r0, r1 
  subLoop:
    cmp r0, 0
    beq rest_subLoop
    sub r0, 1
    b subLoop
  rest_subLoop:
    pop {lr,r0-r9}
    bx lr 

MIDI_To_Frequency:
@ Param:
@ r0 MIDI number (0-127)
  push {lr,r1-r10}
  cmp r0, 69
  bge Note_Ge_69
  Note_Lt_69:
    @ x < 69
    cmp r0, 57
    bgt Note_Gt_57
    Note_Lt_57:
      @ x <= 57
      rsb r0, 69
      mov r1, 12
      udiv r0, r0, r1
      mov r1, 440
      lsr r0, r1, r0
      b return_Frequency

    Note_Gt_57:
      @ 57 < x < 69 (numerate the frequence hard to calculate)
      sub r0, 58
      ldr r1, =Note_To_frequency_58_68
      ldr r0, [r1,r0, lsl 2] 
      b return_Frequency

  Note_Ge_69:
    @ 69 <= x  
    cmp r0, 81
    bge Note_Ge_81
    Note_Lt_81:
      @ 69 <= x < 81
      sub r0, 69
      ldr r1, =Note_To_frequency_69_80
      ldr r0, [r1,r0, lsl 2] 
      b return_Frequency

    Note_Ge_81:
      @ 81 <= x
      sub r0, 69
      mov r1, 12
      udiv r0, r0, r1
      mov r1, 440
      lsl r0, r1, r0
      b return_Frequency

  return_Frequency:
    pop {lr,r1-r10}
    bx lr


.data
firstsequences:
@ 1.Frequency (hz) -- can also use the format of MIDI code
@ 2.amptitude (bit)
@ 3.waveform (0xa = triangle wave, 0xb = square wave, 0xc = sawtooth wave)
@ 4.duration (ms)
  .word 261,   0,   261,   0,   392,   0,   392,   0,   440,   0,   440,   0,   392,   0,   349,   0,   349,   0,   329,   0,   329,   0,   293,   0,   293,   0,   261,   261,   261,   0,    0x2000002d, 0,   0x20000039, 0,   0x20000045, 0,   0x20000051, 0
  .word 54000, 0,   54000, 0,   54000, 0,   54000, 0,   20000, 0,   20000, 0,   54000, 0,   20000, 0,   20000, 0,   20000, 0,   20000, 0,   54000, 0,   54000, 0,   54000, 54000, 54000, 0,    20000,      0,   10000,      0,   53900,      0,   50000,      0
  .word 0xa,   0,   0xa,   0,   0xa,   0,   0xa,   0,   0xb,   0,   0xb,   0,   0xa,   0,   0xc,   0,   0xc,   0,   0xc,   0,   0xc,   0,   0xa,   0,   0xa,   0,   0xa,   0xa,   0xa,   0,    0xc,        0,   0xb,        0,   0xa,        0,   0xa,        0
  .word 250,   250, 250,   250, 250,   250, 250,   250, 250,   250, 250,   250, 500,   500, 250,   250, 250,   250, 250,   250, 250,   250, 250,   250, 250,   250, 250,   250,   500,   2000, 250,        250, 250,        250, 250,        250, 250,        3000

@ This are just the frequences of the MIDI code which is hard to be translated to frequence
Note_To_frequency_69_80:
  .word 440, 466, 494, 523, 554, 587, 622, 659, 699, 740, 784, 831
Note_To_frequency_58_68:
  .word 233, 247, 262, 277, 294, 311, 330, 349, 370, 392, 415

.text
  addi x10, x0, 0
  addi x11, x0, 0x10
  jal x1, sort
  jal x1, output
  add x0, x0, x0    # breakpoint here

output:
  lw x5, 0x40(x0)  # x5 = 0xff00
  addi x5, x5, 0xc  # 0xff0c
  addi x6, x0, 0
loopshow:
  blt x6, x11, show_en
  jalr x0, 0(x1)
show_en:
  lw x7, 0x40(x0)  # x7 = 0xff00
  addi x7, x7, 8   # 0xff08
  lw x7, 0(x7)
  addi x31, x0, 1
  beq x31, x7, show_ready
  jal x0, show_en
show_ready:
  add x7, x6, x6
  add x7, x7, x6
  add x7, x7, x6
  add x7, x7, x10
  lw x28, 0(x7)    # get sorting number
  sw x28, 0(x5)
  addi x6, x6, 1
  jal x0, loopshow

swap:	# x5 is temporary, x10 is nums[] address, x11 is the index of changing number
  add  x6, x11, x11
  add  x6, x6, x11
  add  x6, x6, x11
  add  x6, x10, x6	# acquire address of number
  lw   x5, 0(x6)
  lw   x7, 4(x6)
  sw   x7, 0(x6)
  sw   x5, 4(x6)
  jalr x0, 0(x1)
  
sort:  # x10 is nums[] address, x11 is the size "n"
  addi sp, sp, -4
  sw  x1,  0(sp)
  addi  x18, x11, 0	# move "n" to x18
  addi  x19, x0, 0	# i
  loop1:
    blt x19, x18, next
    addi x11, x18, 0
    lw   x1, 0(sp)
    addi sp, sp, 4
    jalr x0, 0(x1)
  next:
    addi x20, x19, -1 # j = i - 1
    loop2:
      blt  x20, x0, continue
      add x5, x20, x20
      add x5, x5, x20
      add x5, x5, x20
      add x5, x10, x5
      lw   x6, 0(x5)	# nums[j]
      lw   x7, 4(x5)	# nums[j+1]
      blt  x6, x7, continue
      beq  x6, x7, continue
      addi x11, x20, 0
      jal  x1, swap
      addi x20, x20, -1
      jal  x0, loop2
  continue:
    addi x19, x19, 1
    jal  x0, loop1
    
.data
    0xf
    0xe
    0xd
    0xc
    0xb
    0xa
    0x9
    0x8
    0x7
    0x6
    0x5
    0x4
    0x3
    0x2
    0x1
    0x0
    0xff00
.data
  led_data: .word 0xffff
  swt_data: .word 0x0001

      
# init   -> 0xffff
# sw     -> 0x0000
# lw     -> 0x0001
# add    -> 0x0002
# addi   -> 0x0003
# sub    -> 0x0004   
# jal    -> 0x0005
# jalr   -> 0x0006
# beqIf  -> 0x0007
# beqEs  -> 0x0008
# bltIf  -> 0x0009
# bltEs  -> 0x000a  
# auipc  -> 
           
.text
  # test sw
  sw x0, 0(x0)  # show 0x0000
  nop
  nop
  nop
  # test lw
  lw t0, 4(x0)
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0001
  nop
  nop
  nop
  # test add
  add t0, t0, t0
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0002
  nop
  nop
  nop
  # test addi
  addi t0, x0, 0x0003
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0003
  nop
  nop
  nop
  # test sub
  addi t0, x0, 0x5
  nop
  nop
  nop
  addi t1, x0, 0x1
  nop
  nop
  nop
  sub t0, t0, t1
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0004
  nop
  nop
  nop
  # test jal
  jal x1, TEST_JARL
  nop
  nop
  nop
  addi t0, x0, 0x0006
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0006
  nop
  nop
  nop
  # test beq
  beq x0, x0, BEQ_IF
  nop
  nop
  nop
  addi t0, x0, -1
  nop
  nop
  nop
  sw t0, 0(x0)  # fail 0xffff
  nop
  nop
  nop
BEQ_IF:
  addi t0, x0, 0x0007
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0007
  nop
  nop
  nop
  beq x0, t0, BEQ_ELSE
  nop
  nop
  nop
  addi t0, x0, 0x0008
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0008
  nop
  nop
  nop
  jal x0, NEXT
  nop
  nop
  nop
BEQ_ELSE:
  addi t0, x0, -1
  nop
  nop
  nop
  sw t0, 0(x0)  # fail 0xffff
  nop
  nop
  nop
NEXT:
  # test blt
  addi t0, x0, 0x1
  nop
  nop
  nop
  addi t1, x0, 0x2
  nop
  nop
  nop
  blt t0, t1, BLT_IF
  nop
  nop
  nop
  addi t0, x0, -1
  nop
  nop
  nop
  sw t0, 0(x0)  # fail 0xffff
  nop
  nop
  nop
BLT_IF:
  addi t0, x0, 0x0009
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0009
  nop
  nop
  nop
  blt t0, t1, BLT_ELSE
  nop
  nop
  nop
  addi t0, x0, 0x000a
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x000a
  nop
  nop
  nop
  jal x0, NEXT2
  nop
  nop
  nop
BLT_ELSE:
  addi t0, x0, -1
  nop
  nop
  nop
  sw t0, 0(x0)  # fail 0xffff
  nop
  nop
  nop
NEXT2:
  # test auipc
  auipc t0, 1
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x4098
  nop
  nop
  nop
  sw x0, 0(x0)	# show 0x0000
  nop
  nop
  nop
  
TEST_JARL:
  addi t0, x0, 0x0005
  nop
  nop
  nop
  sw t0, 0(x0)  # show 0x0005
  nop
  nop
  nop
  # test jalr
  jalr x0, 0(x1)
  nop
  nop
  nop

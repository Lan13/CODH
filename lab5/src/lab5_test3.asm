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
  # test lw
  lw t0, 4(x0)
  sw t0, 0(x0)  # show 0x0001
  # test add
  add t0, t0, t0
  sw t0, 0(x0)  # show 0x0002
  # test addi
  addi t0, x0, 0x0003
  sw t0, 0(x0)  # show 0x0003
  # test sub
  addi t0, x0, 0x5
  addi t1, x0, 0x1
  sub t0, t0, t1
  sw t0, 0(x0)  # show 0x0004
  # test jal
  jal x1, TEST_JARL
  addi t0, x0, 0x0006
  sw t0, 0(x0)  # show 0x0006
  # test beq
  beq x0, x0, BEQ_IF
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
BEQ_IF:
  addi t0, x0, 0x0007
  sw t0, 0(x0)  # show 0x0007
  beq x0, t0, BEQ_ELSE
  addi t0, x0, 0x0008
  sw t0, 0(x0)  # show 0x0008
  jal x0, NEXT
BEQ_ELSE:
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
NEXT:
  # test blt
  addi t0, x0, 0x1
  addi t1, x0, 0x2
  blt t0, t1, BLT_IF
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
BLT_IF:
  addi t0, x0, 0x0009
  sw t0, 0(x0)  # show 0x0009
  blt t0, t1, BLT_ELSE
  addi t0, x0, 0x000a
  sw t0, 0(x0)  # show 0x000a
  jal x0, NEXT2
BLT_ELSE:
  addi t0, x0, -1
  sw t0, 0(x0)  # fail 0xffff
NEXT2:
  # test auipc
  auipc t0, 1
  sw t0, 0(x0)  # show 0x4098
  sw x0, 0(x0)	# show 0x0000
  
TEST_JARL:
  addi t0, x0, 0x0005
  sw t0, 0(x0)  # show 0x0005
  # test jalr
  jalr x0, 0(x1)

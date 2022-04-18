# Lab3 实验报告

[TOC]

## 1. 10条指令功能的简单测试

### 1.1 逻辑设计

为了方便人工检查，将下列指令测试成功的显示结果定义如下：

```assembly
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
# auipc  -> 0x4098
```

**其中由于 `auipc` 和 PC 有关，所以这条指令的测试结果在 Rars 中和后续 CPU 中可能会不同。**

接下来便是按照这个顺序进行测试，因为所有指令都需要借助 LED 来判断是否操作成功，所以首先需要对 `sw` 进行测试。接着对 `lw`  , `add` 和 `addi`进行测试，可以方便后续输出特定结果。剩下的测试顺序也没有什么讲究。

不过在测试条件分支指令时，对分支的两种情况都进行了判断：满足分支条件时的跳转执行和不满足分支条件的顺序执行。

### 1.2 核心代码

```assembly
.data
  led_data: .word 0xffff
  swt_data: .word 0x0001
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
  sw x0, 0(x0)  # show 0x0000, BreakPoint at this line
  
TEST_JARL:
  addi t0, x0, 0x0005
  sw t0, 0(x0)  # show 0x0005
  # test jalr
  jalr x0, 0(x1)
```

### 1.3 测试结果

初始时，LED 会全亮：

<img src="..\images\test_ffff.png" width="500"/>

接着再每一步测试中，LED 都会发生变化：

<img src="..\images\test_0.png" width="500"/>

<img src="..\images\test_1.png" width="500"/>

<img src="..\images\test_2.png" width="500"/>

<img src="..\images\test_3.png" width="500"/>



## 2. 数组排序的简单测试

### 2.1 逻辑设计

常见的排序算法有许多种，例如冒泡排序，选择排序，快速排序等等。本次实验采用冒泡排序，原因是其比较简单，使用汇编语言能够比较容易的实现，参考课本给出的排序算法：

```c
void swap (long long int v[], size_t int k)
{
    long long int temp;
    temp = v[k];
    v[k] = v[k + 1];
    v[k + 1] = temp;
}
void sort (long long int v[], size_t int n)
{
	size_t i, j;
    for (i = 0; i < n; i += 1) {
        for (j = i - 1; j >= 0 && v[j] > v[j + 1]; j -= 1) {
            swap(v, j);
        }
    }
}
```

接下来就是将上述代码转化为汇编代码的过程，下面将采用注释的方式进行阐述。其中初始化数据为：

``` assembly
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
    0x7f00
```

总而言之就是前16个为数据，第17个数据为 `0x7f00`，**下面代码有些特定地址就是视这个数据而定**。完整调用程序的代码请看代码文件。

### 2.2 核心代码

#### 2.2.1 交换和排序

```assembly
swap:	# x5 and x7 are temporary register, x10 is nums[] address, x11 is the index
  add  x6, x11, x11
  add  x6, x6, x11
  add  x6, x6, x11  # shift left 2
  add  x6, x10, x6	# get real address of number
  lw   x5, 0(x6)
  lw   x7, 4(x6)
  sw   x7, 0(x6)    # swap
  sw   x5, 4(x6)    # swap
  jalr x0, 0(x1)    # return
  
sort:  # x10 is nums[] address, x11 is the size "n"
  addi sp, sp, -4
  sw  x1,  0(sp)    # store return address because swap would change x1
  addi  x18, x11, 0	# move "n" to x18 beacuse swap would change x11
  addi  x19, x0, 0	# x19 is "i"
  loop1:
    blt x19, x18, next  # if "i < n"
    addi x11, x18, 0    # reload "n" to x11
    lw   x1, 0(sp)      # reload return address
    addi sp, sp, 4
    jalr x0, 0(x1)      # return
  next:
    addi x20, x19, -1   # x20 is j "= i - 1"
    loop2:
      blt  x20, x0, continue  # if "j < 0" then continue i++
      add x5, x20, x20  
      add x5, x5, x20
      add x5, x5, x20   # shift left 2
      add x5, x10, x5   # get real address of number
      lw   x6, 0(x5)	# nums[j]
      lw   x7, 4(x5)	# nums[j+1]
      blt  x6, x7, continue  # if "v[j] < v[j+1]" then continue i++
      beq  x6, x7, continue  # if "v[j] = v[j+1]" then continue i++
      addi x11, x20, 0    # set argument to swap nums[j] and nums[j+1]
      jal  x1, swap       # swap
      addi x20, x20, -1   # j = j - 1
      jal  x0, loop2      # inner loop
  continue:
    addi x19, x19, 1      # i = i + 1
    jal  x0, loop1        # outer loop
```

#### 2.2.2 显示到MMIO

```assembly
# address 0x0040 stores 0x7f00 where MMIO works
# x10 is nums[] address, x11 is the size "n"
output:
  lw x5, 0x40(x0)
  addi x5, x5, 0xc  # get x5 = 0x7f0c
  addi x6, x0, 0    # x6 is counter
loopshow:
  blt x6, x11, show_en  # if "x6 < (size) 'n'" then show enable
  jalr x0, 0(x1)    # output is finished, return
show_en:
  lw x7, 0x40(x0)
  addi x7, x7, 8    # get x7 = 0x7f08
  lw x7, 0(x7)		# get ready bit in 0x7f08
  addi x31, x0, 1
  beq x31, x7, show_ready  # if ready bit = 1, ready to show
  jal x0, show_en   # wait until enable to show
show_ready:
  add x7, x6, x6
  add x7, x7, x6
  add x7, x7, x6    # shift left 2
  add x7, x7, x10
  lw x28, 0(x7)     # get number
  addi x29, x0, 0xa  
  blt x28, x29, zeroTonine  # if number < 10
  addi x28, x28, 55     # if number is between "a" and "f", add 55
  jal x0, show
zeroTonine:
  addi x28, x28, 0x30   # add 48
show:
  sw x28, 0(x5)		# show number
  addi x6, x6, 1 	# x6 = x6 + 1
  jal x0, loopshow
```

#### 2.2.3 键盘输入后排序

```assembly
# x10 is nums[] address, x11 is the size "n"
write_sort:
  addi x6, x0, 0	# x6 is counter
  addi x10, x0, 0x44
  lw x5, 0x40(x0)
  addi x5, x5, 0x4  # get x5 = 0x7f04
  jal x1, write_en
  lw x11, 0(x5)		# get first number "n"
  addi x11, x11, -0x30	# change ascii code to real number
write_loop:
  blt x6, x11, write_data	# if "x6 < n" then write
  jal x1, sort			# input is finished, then sort
  jal x1, output		# sort is finished, then output
  add x0, x0, x0  # WHEN SIMULATING, TO SHOW LAST NUMBER
  add x0, x0, x0  # END END END END END END END breakpoint here
write_data:
  jal x1, write_en	 # test whether ready or not
  lw x7, 0(x5)
  addi x7, x7, -0x30  # get number
  add x28, x6, x6
  add x28, x28, x6
  add x28, x28, x6   # shift left 2
  add x28, x28, x10  
  sw x7, 0(x28)		 # store input number to memory
  addi x6, x6, 1	 # x6 = x6 + 1
  jal x0, write_loop

write_en:
  lw x7, 0x40(x0)   # get x7 = 0x7f00
  lw x7, 0(x7)		# get ready bit in 0x7f00
  addi x31, x0, 1
  beq x31, x7, ready  # if ready bit = 1, ready to input
  jal x0, write_en	# wait until enable to input
ready:
  jalr x0, 0(x1)  	# return
```

### 2.3 测试结果

刚开始时，MMIO中没有任何显示：

<img src="..\images\sort_begin.png" width="800"/>

接着排序完后：

<img src="..\images\sort_sortfirst.png" width="800"/>

再接着输入数据后，将会进行排序并输出：

<img src="..\images\sort_sortinput.png" width="800"/>

## 3. 实验总结

1. 本次实验与以往不同，主要进行的是 RISC-V 汇编语言的设计。本次实验了解到了汇编程序的基本结构，学习了 RISC-V 常用指令的功能，以及熟练使用 Rars 对汇编程序进行仿真和调试，加强了对 RISC-V 汇编语言的理解与应用。
2. 建议：无

# 实验步骤

1. 设计单周期CPU，将CPU和PDU整合后下载至FPGA，进行逐条指令功能测试
   - 指令存储器和数据存储器采用IP例化的分布式存储器，容量均为256x32位，使用LabH3实验步骤1生成的COE文件初始化
   - 寄存器堆和数据存储器各增加一个用于调试的读端口
   - MMIO的起始地址为0

2. 将CPU和PDU整合后下载至FPGA，进行排序程序测试
   - 使用LabH3实验步骤2生成的COE文件初始化
   - MMIO的起始地址为0xff00
   - 查看电路资源使用情况和电路性能

3. 选项：扩展单周期CPU设计，实现更多条指令功能，并对扩展指令进行下载测试
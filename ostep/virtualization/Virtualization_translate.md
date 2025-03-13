### 内存的虚拟化（中）———— 实现

#### 地址转换
这一节简单谈谈虚拟化的实现。虚拟化实现的核心是**地址转化**，那么是谁转换成谁呢？程序所使用的地址被转换为可访问内存的物理地址，前者因无法直接访问内存被称为**虚拟地址**。由虚拟地址构成的内存空间称为**虚拟内存空间**。虚拟内存空间是一个起始地址为0的线性数组。这个空间模型很简单，因而使用时很方便。

##### 线性转换
最简单的转化方式与数学里的一次函数一样，使用$physical_addr = virtual_addr + base_addr$来计算物理地址，其中`base_addr`是程序在物理内存中的起始地址，存放在基址寄存器中，同时存在一个界限寄存器，其值用于检验虚拟地址是否越界，其实这个值就是程序所占物理内存的大小。大致工作过程：在CPU执行访问内存的操作时，CPU会先用界限寄存器的值判断虚拟地址是否越界，再使用上述的转换公式计算出物理地址，最后通过计算结果（物理地址）来访问物理内存。  
挒如：A程序的基址是`0x00001100`，内存大小是`0x1000000`。当CPU执行`mov 0x0(0x00001000) %rax`时，会执行以下行为：
```c
    if ( virtual_addr < limit_value) {
        physical_addr = base_addr + virtual_addr;
        value = memory(physical_addr);
        write_register(value, rax);
    } else {
        system_except("Access out of bounds");
    }
```
为了描述更简洁、清晰，这里我使用了c语言来表达。

##### 分段转换
线性转换虽简单的实现了虚拟化，但是新的问题也随之来。为了解决这些问题，我们需要新的转换方式。我们知道一个进程的内存空间可以分为几个部分————代码段、数据段、栈、堆。并称这些部分为段。分段转换的核心思想是以段为映射对象，与线性转换相比，在分段转换之下，进程的段与段可以在物理内存空间中是非连续。分段转换的实现要比线性转换复杂，它需要一个段表，每项记录一个段的基址、界限、访问权限等信息。同时需要虚拟地址的最高两位来确定使用哪项来执行转换操作。  
例如：CPU执行`mov 0x0(0x00001000) %rax`时，会执行以下行为：  
```c
    segment_number = (virtual_addr & mask0) >> SHIFT;
 *  segment_offset = (virtual_addr & mask1);
    segment_entry = access_segment_table(segment_number);
    
    if ( segment_offset < segment_entry -> limit_value) {
        physical_addr = segment_entry -> base_addr + segment_offset;
        value = memory(physical_addr);
        write_register(value, rax);
    } else {
        system_except("Access out of bounds");
    }
```

##### 分页转换
分页转换在实现上比分段转换更复杂，其核心思想是视特定大小的内存块为转换对象。在本文中使用512B为一块，在虚拟空间与物理空间中这些块被称为虚拟页与物理页。要实现分页转换首先需要一个页表，页表每一项记录一个物理页基址、访问权限等信息。因为页表比较大，无法存储在寄存器中，所以需要一个页表寄存器指向内存中的页表，为了通过虚拟地址找到页表中的某一项，在32位地址中，需要高23位作为表项索引，低9位用于页内索引。  
为什么是23位与9位呢？我们来算一下，页大小是512B，因此要索引页内每一个字节，我们需要512个数，而在二进制中要表达512个数需要$2^9 = 512$9位。总共32位，去掉9位还剩23位。  
例如：CPU执行`mov 0x0(0x00001000) %rax`时，会执行以下行为：  
```c
    page_number = (virtual_addr & mask0) >> SHIFT;
    page_offset = (virtual_addr & mask1);
    page_entry = access_pagetable(page_number);
    physical_addr = page_entry -> physical_addr + page_offset;
    value = memory(physical_addr);
    write_register(value, rax); 
```

#### 探究
在简单介绍三种地址转换后，现在回过头来看看为什么虚拟化解决了多道程序驻留内存中的问题？  

- 问题1：程序内存访问控制  
在增加一道转化操作后，便可以通过界限寄存器简单的实现访问控制。在下一篇中我们会聊到在不同的地址转换中，控制内存访问的能力有强弱之别。  
- 问题2：开发负担大  
在使用物理内存地址进行开发时，开发者必需熟悉物理内存的结构，而物理内存的结构往往是多样且复杂的，这无疑增大了开发门槛。使用地址转换之后，开发者只需关注简单的虚拟内存即可。

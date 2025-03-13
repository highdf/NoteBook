### bomb实验（中）

<!-- vim-markdown-toc GFM -->

* [phase_1解题思路](#phase_1解题思路)
* [phase_2解题思路](#phase_2解题思路)
* [phase_3解题思路](#phase_3解题思路)

<!-- vim-markdown-toc -->

#### phase_1解题思路
现在我们开始解题，在vim中输入`/phase_1<enter>`找到phase_1的代码块。  
```asm
sub    $0x8,%rsp
mov    $0x402400,%esi
call   401338 <strings_not_equal>
test   %eax,%eax
je     400ef7 <phase_1+0x17>
call   40143a <explode_bomb>
add    $0x8,%rsp
ret
```
我们来看第一行代码`sub 0x8 %rsp`，这行代码的意思是在栈空间中分配8个字节的空间，而2～3行是一个函数调用，从代码中可以看出调用的函数为`strings_not_equal`，从名称上看，这个函数的作用应该是比较字符串是否相等。那么，第2行就是调用前的参数传递了，不过，这里我们有一个疑问，既然是比较字符串是否相等，不是应该传递两个参数吗，可为什么只有一个呢[^1]？  
我们继续看4～5行,eax寄存器存放的是函数调用的返回值，而test指令是对其进行测试，根据代码，若为0,则跳转到爆炸指令之后，反之，则执行爆炸函数。因此，我们的输入只要和phase_1内部定义的字符串相等就可以了。  
我们怎样才能得到这个字符串呢？我们需要用gdb来调试bomb获取该字符串，先回到终端，输入`gdb bomb`,`break phase_1`,`run`进入调试，再输入`x/s 0x402400`就可以得到结果了。  
![image][phase_1-1]
最后，我给出了等价的C语言代码
```c
void phase_1(char *input){
    char *key = "Border relations with Canada have never been better.";

    if(strings_not_equal(input,key) != 0) {
        explode_bomb();
    }
}
```

---

#### phase_2解题思路
我们来看`phase_2`，在vim中输入`/phase_2`，再通过`n`定位代码段`phase_2`，如图：
![image][phase_2-0]
执行`sub    $0x28,%rsp`在栈上分配了40字节的内存块。  
```asm
mov    %rsp,%rsi
#call   40145c <read_six_numbers>
```
两行代码是一个的函数调用，第一行将栈顶地址（%rsp的值）作为参数进行传递，从函数名字可以大概看出这个函数的作用是读六个整数，我们来看这个函数到底做了什么？  
用`/read_six_numbers`跳转到定义代码块处，如图：
![image][phase_2-1]
`mov    %rsp,%rsi`我们可以知道这个函数的参数是phase_2的栈顶指针。  
```asm
mov    %rsi,%rdx
lea    0x4(%rsi),%rcx
lea    0x14(%rsi),%rax
mov    %rax,0x8(%rsp)
lea    0x10(%rsi),%rax
mov    %rax,(%rsp)
lea    0xc(%rsi),%r9
lea    0x8(%rsi),%r8
mov    $0x4025c3,%esi
mov    $0x0,%eax
call   400bf0 <__isoc99_sscanf@plt>
```
一大段乍看起来有一点可怕，但我们仔细一看会发现这其实是一个函数调用，只不过调用的参数比较多，一共有6个，并且，调用的函数是scanf，这个函数我们就熟悉了，它会读取用户的输入，并将读到的值写入参数指定的内存块中。最后，我们来看这些值会写入到哪里？因为rsi的值是phase_2的栈顶指针，所以，读入的值被写入到了离栈顶偏移量为0,4,8,12,16,20的位置。
回到phase_2我们继续看接下来发生了什么？  
```asm
cmpl   $0x1,(%rsp)
je     400f30 <phase_2+0x34>
call   40143a <explode_bomb>
```
函数返回后，对栈顶元素与1进行的比较，若相等，则跳转到`400f30`处，反之，执行`call   40143a <explode_bomb>`，引爆炸弹。因此，结合`read_six_number`的行为，我们可以知道我们有输入的第一个数是1。我们接着看`400f30`处的代码。  
```asm
lea    0x4(%rsp),%rbx
lea    0x18(%rsp),%rbp
jmp    400f17 <phase_2+0x1b>
```
两行代码分别获取了栈顶偏移量为4与24的地址，并跳转到`400f17`处，我们接着看`400f17`处的代码。  
```asm
mov    -0x4(%rbx),%eax
add    %eax,%eax
cmp    %eax,(%rbx)
je     400f25 <phase_2+0x29>
call   40143a <explode_bomb>
```
`0x4(%rbx)`的值刚好是栈顶元素，因此，这块代码的行为是取栈顶元素，并乘以2后与栈顶偏移量是4的元素比较，若相等，则跳转到`400f25`处，反之，则爆炸。我们来看`400f25`处的代码。  
```asm
add    $0x4,%rbx
cmp    %rbp,%rbx
jne    400f17 <phase_2+0x1b>
jmp    400f3c <phase_2+0x40>
```
这段代码更新了rbx寄存器的值，再测试了rbp与rbx是否相等，若相等，则执行：
```asm
add    $0x28,%rsp
pop    %rbx
pop    %rbp
ret
```
很显然这段代码回收了分配的空间，并执行ret返回给调用者。若不相等，则：  
```asm
mov    -0x4(%rbx),%eax
add    %eax,%eax
cmp    %eax,(%rbx)
je     400f25 <phase_2+0x29>
```
这段代码在之前执行过一次，但与之前一次不同的是rbx的值增加了4字节，因此，这段代码的行为是测试rbx与前一个值是否为2倍的关系，若是，则增加rbx，再测试，直到测试完第六个数为止。反之，则爆炸。  
综合一下，phase_2的行为就是用户读入6个数，要求第一个数是1，并且，后面5个数按公比为2的等比数列递增。  
最后，我给出等价的C语言实现。  
```c
int a[6];

scanf("%d%d%d%d%d%d",&a[0],&a[1],&a[2],&a[3],&a[4],&a[5]);

if(a[0] != 1) {
    explode_bomb();
}

for(int i = 1;i < 6;i ++) {
    if(a[i] != a[i-1] * 2) {
        explode_bomb();
    }
}
```

---

#### phase_3解题思路
打开bomb.s文件，然后，通过输入`/phase_3`查找`phase_3`的代码段，如图：
![image][phase_3-0]
接着，我们开始读代码吧！  
开头的第一行:`sub    $0x18，%rsp`这行指令用于来完成栈分配的。接下来：
```asm
lea    0xc(%rsp),%rcx
lea    0x8(%rsp),%rdx
mov    $0x4025cf,%esi
mov    $0x0,%eax
call   400bf0 <__isoc99_sscanf@plt>
```
`call   400bf0 <__isoc99_sscanf@plt>`这其实就是对scanf的调用，同时，从2到4行的参数准备中可以看出，scanf会读入两个值。那读入这两个值是干什么的呢？我们接着往下看：  
```asm
cmp    $0x1,%eax
jg     400f6a <phase_3+0x27>
call   40143a <explode_bomb>
```
这里，测试了返回值，若返回值大于1，则跳转到`400f6a`处，反之，则引爆炸弹。这里，之所以这样做，是为了测试用户是否读入2个数，如果没有，就引爆炸弹。我们来看`400f6a`那里发生了什么？  
```asm
cmpl   $0x7,0x8(%rsp)
ja     400fad <phase_3+0x6a>
mov    0x8(%rsp),%eax
jmp    *0x402470(,%rax,8)
```
这里测试了读入的第一个值与7的大小关系，如果大于7,则跳转到`400fad`处，
```asm
400fad:	e8 88 04 00 00       	call   40143a <explode_bomb>
```
这里，他引爆了炸弹。因此，第一个输入值不能大于7。  
如果小于7，接着就进行了间接跳转，跳转目标存储在`0x402470(,%rax,8)`内存地址处，此时，我们要想知道这个跳转地址是什么
就需要使用gdb来调试它了，回到终端，输入`gdb bomb`进入gdb，再输入`break phase_3`与`run answer`来设置断点与运行程序，再随便输入0与1，结果如图
![image][phase_3-1]
再输入`x/8xg 0x402470`，它就输出了7个地址值，
![image][phase_3-2]
而这些地址我们都可以在汇编代码中发现它们，我们选择其中 一个来查看
![image][phase_3-3]
从图中我们看到有一个分支行为，若`0xc(%rsp)`处的值不等于0xcf， 则爆炸，反之，则回收内存，离开函数。所以，`phase_3`的行为就是根据用户输入第一个的0~7的值，执行不同的分支，测试不同的第二个输入。  
最后，给出与phase_3行为相同的C语言代码：
```c
int num1,num2;
int n = scanf("%d%d",&num1,&num2);

if(n == 2) {
    switch(num1) {
        case 0: if (num2 != 207) explode_bomb(); break;
        case 1: if (num2 != 707) explode_bomb(); break;
        case 2: if (num2 != 256) explode_bomb(); break;
        case 3: if (num2 != 389) explode_bomb(); break;
        case 4: if (num2 != 206) explode_bomb(); break;
        case 5: if (num2 != 682) explode_bomb(); break;
        case 6: if (num2 != 327) explode_bomb(); break;
        case 7: if (num2 != 311) explode_bomb(); break;
        default: explode(); // 实际由ja指令处理
    }
} else {
    explode_bomb();
}

return 0;
```

[^1]:为什么只要一个参数传递呢？因为我们输入字符串是通过参数传递进入phase_1的，在寄存器%rdi中，因此另一个参数（也就是我们的输入）已经存放%rdi里了，因此，不需要再传递了，只需要传递答案字符串的地址给%rsi即可。  

[phase_1-0]: https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_1-0.png
[phase_1-1]: https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_1-1.png
[phase_2-0]:https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_2-0.png
[phase_2-1]:https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_2-1.png
[phase_3-0]: https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_3-0.png
[phase_3-1]: https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_3-1.png
[phase_3-2]: https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_3-2.png
[phase_3-3]: https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_3-3.png

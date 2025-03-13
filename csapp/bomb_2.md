### bomb实验（下）

<!-- vim-markdown-toc GFM -->

* [phase_4解题思路](#phase_4解题思路)
* [phase_5解题思路](#phase_5解题思路)

<!-- vim-markdown-toc -->

#### phase_4解题思路
现在就要开始上强度了，问题难度再增加了一节，上代码：
```asm
sub    $0x18,%rsp
lea    0xc(%rsp),%rcx
lea    0x8(%rsp),%rdx
mov    $0x4025cf,%esi
mov    $0x0,%eax
call   400bf0 <__isoc99_sscanf@plt>
```
这里和之前的问题一样，分配了24字节的内存块，然后，传递了两个参数，调用scanf读取两个整数，接下来：
```asm
cmp    $0x2,%eax
jne    401035 <phase_4+0x29>
```
这里测试了返回值，若不为2,即没有读两个数，就跳转到`explode_bomb`引爆炸弹。反之，则执行：
```asm
cmpl   $0xe,0x8(%rsp)
jbe    40103a <phase_4+0x2e>
call   40143a <explode_bomb>
```
对读入的第一个数进行了测试，若大于0xe或小于0[^2]，则执行`<explode_bomb`引爆炸弹。  
若小于等于0xe，则执行跳转，我们来看`0x40103a`处有什么？  
```asm
mov    $0xe,%edx
mov    $0x0,%esi
mov    0x8(%rsp),%edi
call   400fce <func4>
```
这里显然是一个函数调用，传递的参数分别是读入第一个数,0x0与0xe，我们先不深入了解`func`的行为，看看返回后发生了什么？  
```asm
test   %eax,%eax
jne    401058 <phase_4+0x4c>
cmpl   $0x0,0xc(%rsp)
je     40105d <phase_4+0x51>
call   40143a <explode_bomb>
```
测试返回值若非0则爆炸，否则检查第二个输入值是否非0,若为0,则爆炸。反之，跳转到`40105d`：
```asm
40105d:	48 83 c4 18          	add    $0x18,%rsp
```
回收内存块，退出函数。好了,现在我们可以确定有输入的第二个值是0，现在我们只需要确定第一个值了。因为，先前读入的第一个值被作为参数传递给了`func`函数，并要求func4返回值是0，那么，我们来看在`func`里发生了什么？  
输入`/func4`命令的定位函数，如图：

![image][phase_4-0]

先看第一块：
```asm
mov    %edx,%eax
sub    %esi,%eax
mov    %eax,%ecx
shr    $0x1f,%ecx
add    %ecx,%eax
```
开始的两行用参数edx-esi并将结果写入eax,ecx中，然后右移ecx31位再加上eax，用C语言描述就是：
```c
int eax = edx - esi;
eax = (eax >> 31) + eax;
```
这里进行第二步运算是在对eax进行向0取整，至于为什么这么做？我也不知道，若读者知道，望不吝指点。  
```asm
sar    $1,%eax
lea    (%rax,%rsi,1),%ecx
cmp    %edi,%ecx
jle    400ff2 <func4+0x24>
```
这里对eax进行了右移1位的操作，等价于对其进行除以2的运算，接着更新ecx的数值为eax+rsi，再对ecx与edi(即用户读入的第一个数)进行了测试，若小于等于，则跳转到`400ff2`处，
```asm 
mov    $0x0,%eax
cmp    %edi,%ecx
jge    401007 <func4+0x39>
```
这里又测试了edi与ecx，若大于等于0,则，跳转`401007`处，我们来看：
```asm
add    $0x8,%rsp
ret
```
显然，这段的作用是退出该函数，因此，我们可以得到一个结论，当且仅当，edi与ecx相等时，会退出该函数。那么,在edi分别大于或小于ecx时，发生了什么？我们又回到此处代码块：
```asm
sar    $1,%eax
lea    (%rax,%rsi,1),%ecx
cmp    %edi,%ecx
jle    400ff2 <func4+0x24>
```
由此处可知，若edi大于ecx会发生跳转到：
```asm 
mov    $0x0,%eax
cmp    %edi,%ecx
jge    401007 <func4+0x39>
```
在第三行代码处，由于ecx小于edi因此不会发生跳转，所以，将执行：
```asm
lea    0x1(%rcx),%esi
call   400fce <func4>
lea    0x1(%rax,%rax,1),%eax
```
在这里更新了原始参数esi为rcx+1其余的不变，再递归调用了函数func4，最后返回后，更新返回值为`2 * eax + 1`，此时我们已经有一点混乱了，这都是什么和是什么？所以先让自己放松一下，理理思路！！  
接下来看，ecx大于edi的情况：
```asm
lea    -0x1(%rcx),%edx
call   400fce <func4>
add    %eax,%eax
jmp    401007 <func4+0x39>
```
若ecx大于edi，则会更更新原始参数edx，然后递归调用func，接着更新返回值为`2 * eax`，最后，跳转到`401007`处，退出函数。
综合起来看func的行为就是递归二分查找法找【esi,edx】(初始值是0与0xe)之间的一个值，其中esi存放的是查找区间的下限，edx存放查找区间的上限，edi是用户的输入作为查找项，以下是等价的c代码：
```c
int eax = ( edx - esi ) / 2;
//edx 上限，esi 下限
int ecx = (esi + eax);
int re;

if(edi > ecx) {
    re = func(edi,ecx + 1,edx);        
    re = re * 2 + 1;
} else if(edi < ecx) {
    re = func(edi,esi,ecx - 1);
    re = re * 2;
} else {
    re = 0;
}
```
在phase_4中要求func的返回值为0,才不会爆炸，那么edi为多少时,func会返回0呢？  
最后，我给出phase_4的C语言代码：
```c
{
    int a, b;
    if (sscanf(input, "%d %d", &a, &b) != 2 || a > 14 || b != 0) 
        explode_bomb();

    if (func4(a, 0, 14) != 0)
        explode_bomb();
}
```

#### phase_5解题思路
```asm
push   %rbx
sub    $0x20,%rsp
mov    %rdi,%rbx
mov    %fs:0x28,%rax
                             
mov    %rax,0x18(%rsp)
xor    %eax,%eax
call   40131b <string_length>
```
开始时，phase_5与其他的差不多，分配了栈空间，准备调用参数%rbx，调用函数`string_length`，从函数名中我们可以大致知道这个函数的作用是验证参数字符串的长度。我们看看返回后发生了什么？
```asm
cmp    $0x6,%eax
je     4010d2 <phase_5+0x70>
call   40143a <explode_bomb>
```
函数返回后，测试返回值与6的大小关系，如果等于6,则跳转到`0x4010d2`处，反之，则引爆炸弹。看看`0x4010d2`处有什么？  
```asm
mov    $0x0,%eax
jmp    40108b <phase_5+0x29>
```
这里，将%eax的值置于0，然后跳转到`0x40108b`处。  
```asm
movzbl (%rbx,%rax,1),%ecx
mov    %cl,(%rsp)
mov    (%rsp),%rdx
and    $0xf,%edx
```
%rbx是指向输入字符串的指针，因此，这条指令的含义是读第%rax（rax的初始值是0）个字符，写入%rcx中。  
cl寄存器是rcx寄存器的后8位，因此结合上一条指令我们可以知道这块代码读取了输入字符串的第rax个字符，并将其写入到了rdx寄存器中，然后，执行and指令，这条指令的含义是将寄存器edx中数据的后四位取出到rdx中，那么，取出的四位机器吗是用来干什么的呢？接着往下看：
```asm
movzbl 0x4024b0(%rdx),%edx
mov    %dl,0x10(%rsp,%rax,1)
add    $0x1,%rax
cmp    $0x6,%rax
jne    40108b <phase_5+0x29>
```
取出基址是0x4024b0，以输入字符的低4位作为偏移量,从地址`0x4024b0 + rdx`读取数据，写入到edx中，然后，再将其写入到离栈顶元素的偏移是rax+0x10的地方，将rax加1，最后测试rax的值。  
当小于6时，跳转到40108b，我们来看40108b那里有什么，
```asm
movzbl (%rbx,%rax,1),%ecx
mov    %cl,(%rsp)
mov    (%rsp),%rdx
and    $0xf,%edx
movzbl 0x4024b0(%rdx),%edx
mov    %dl,0x10(%rsp,%rax,1)
add    $0x1,%rax
cmp    $0x6,%rax
jne    40108b <phase_5+0x29>
```
又回到了这里，很显然，这块代码是一个循环体，它的行为是依次取出输入字符串的各位，然后将这个字符的后四位机器码解释为int类型，作为基址是4024b0的偏移量rax，并将这个地址上的数据依次写入离栈顶元素偏移量是0x10的地方，接着来看写完6个值后，程序做了什么？  
```asm
movb   $0x0,0x16(%rsp)
mov    $0x40245e,%esi
lea    0x10(%rsp),%rdi
call   401338 <strings_not_equal>
```
第一行代码将0写入栈顶偏移量为22的地方，它为什么这么做呢？因为在之前程序用循环向栈顶偏移16的位置写入了6个字符，因此，这行指令是为了给这六个字符构成的字符串加上一个字符串结束符。剩下的代码是一个参数调用，传递的参数分别是0x40245e与16+%rsp，从名称上看出函数的作用是比较两个字符串是否相等，因此，我们可以知道两个参数都是某两个字符串的地址值。而其中一个是由循环写入的，至于另一个字符串是什么？我们等会在看，先看返回后发生了什么？  
```asm
test   %eax,%eax
je     4010d9 <phase_5+0x77>
call   40143a <explode_bomb>
```
返回后，测试了返回值，若为0,则跳转到4010d9处，反之，则引爆炸弹。那么，4010d9处有什么呢？
```asm
mov    0x18(%rsp),%rax
xor    %fs:0x28,%rax
                                     
je     4010ee <phase_5+0x8c>
call   400b30 <__stack_chk_fail@plt>
add    $0x20,%rsp
pop    %rbx
ret
```
显然，这块代码是函数返回。  那么，phase_5的行为我们就能确定了，先读取六个字符，然后，用这六个字符机器码的后四位为偏移量从内存地址0x4024b0处取六个字符，写入栈顶偏移为0x10处，构成一个长度为6的字符串，最后，将其与地址是0x40245e的字符串比较，若相等，则，离开函数，反之，引爆炸弹。  
综上，要解题就要知道0x401338处的字符串和0x4024b0处的字符,从而推出使用的偏移量，再根据偏移量求出字符即可。  
最后，给出等价的C语言代码：
```c
char charset[16] = {读者需通过gdb查看};
char input[7];
char target0[7];
char *target1 = "读者需通过gdb查看";

scanf("%s",input);

for(int i = 0;i < 6;i ++) {
    int a = input[i] & 0xf;
    target0[i] = charset[a];
}
target0[6] = '\0';

if(strings_not_equal(target0,target1) != 0) {
    explode_bomb;
}

return 0;
```

[phase_4-0]: https://raw.githubusercontent.com/highdf/Picture/refs/heads/main/bomb/phase_4-0.png

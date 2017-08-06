// scan not函数，是个副词，修饰动词（函数）的，该副词长这样 \

二元函数 f(x,y) 作用在list L上，得到结果记为T
T0 =  L0
T1 = f(T0,L1)
T2 = f(T1,L2)
example,f(x,y) = 10*x+y Q_Form is: ({y+10*x}\)
L:0 1 2 3 4f
T0 = 0;
T1 = 10*0+1 =1
T2 = 10*1+2 =12
T3 = 10*12+3 = 123

三元函数 f(x,y,z) 作用在三个list L M N上（其中L应为单变量,也可以不是单变量），得到结果记为T
T0 = f(L,M0,N0)
T1 = f(T0,M1,N1)
T2 = f(T1,M2,N2)
T3 = f(T2,M3,N3)
example,f(x,y) = x*y+z Q_Form is: ({z+x*y}\)
L=1;M=1 2 3 4;N=5 6 7 8;
T0 = 5+1*1 = 6
T1 = 6+2*6 = 18
T2 = 7+3*18 = 61
({z+x*y}\)[1f;1 2 3 4f; 5 6 7 8f]

新增一个有趣的例子
sw:{{1 _ x, y}\[x#0;y]}
它是把x作为一个整体参数，y作为一个List 挨个使用
sw[2;1 2 3 4] result is
0 1 (1_ 0 0 1)
1 2 (1_ 0 1 2)
2 3
3 4

// mom 的计算
swin:{[f;w;s] f each { 1_x,y }\[w#1f;s]};

#import "@preview/tablex:0.0.7": tablex, cellx, rowspanx, colspanx

== 7.3.1 在监视方向过程信息的应用服务数据单元

== 7.3.1.1 类型标识 1 : M_SP_NA_1

不带时标的单点信息

信息对象序列（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [0], [0], [0], [0], [0], [1], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], colspanx(7)[信息元素数 i], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(2)[信息对象 1],
  [IV], [NT], [SB], [BL], [0], [0], [0], [SP1], [SIQ=带品质描述词的单点信息（在 7.2.6.1 中定义）], (),
  colspanx(8)[…], […], [],
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(2)[信息对象 i],
  [IV], [NT], [SB], [BL], [0], [0], [0], [SP1], [SIQ=带品质描述词的单点信息（在 7.2.6.1 中定义）], () 
)

单个信息对象中顺序的信息元素（SQ = 1）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [0], [0], [0], [0], [0], [1], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [1], colspanx(7)[信息元素数 j], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址 A], rowspanx(4)[信息对象],
  [IV], [NT], [SB], [BL], [0], [0], [0], [SP1], [SIQ=带品质描述词的单点信息（在 7.2.6.1 中定义）#linebreak()属于信息对象地址 A], (),
  colspanx(8)[…], […], (),
  [IV], [NT], [SB], [BL], [0], [0], [0], [SP1], [SIQ=带品质描述词的单点信息（在 7.2.6.1 中定义）#linebreak()属于信息对象地址 A+j-1], ()
)

== 7.3.2 在控制方向过程信息的应用服务数据单元

== 7.3.2.1 类型标识 45 : C_SC_NA_1

单命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [1], [0], [1], [1], [0], [1], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(2)[信息对象],
  colspanx(2)[S/E], colspanx(4)[QU], [0], [SCS], [SCO=单命令（在 7.2.6.15 中定义）], ()
)

== 7.3.2.2 类型标识 46 : C_DC_NA_1

双命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [1], [0], [1], [1], [1], [0], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(2)[信息对象],
  colspanx(2)[S/E], colspanx(4)[QU], [0], [DCS], [DCO=双命令（在 7.2.6.16 中定义）], ()
)

== 7.3.2.3 类型标识 47 : C_RC_NA_1

步调节命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [1], [0], [1], [1], [1], [1], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(2)[信息对象],
  colspanx(2)[S/E], colspanx(4)[QU], colspanx(2)[RCS], [RCO=步调节命令（在 7.2.6.17 中定义）], ()
)

== 7.3.2.4 类型标识 48 : C_SE_NA_1

设定命令, 归一化值

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [1], [1], [0], [0], [0], [0], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(4)[信息对象],
  colspanx(8)[值], rowspanx(2)[NVA=标度化值（在 7.2.6.6 中定义）], (),
  [S], colspanx(7)[值], (), (),
  [S/E], colspanx(7)[QL], [QOS=设定命令限定词（在 7.2.6.39 中定义）], ()
)

== 7.3.2.5 类型标识 49 : C_SE_NB_1

设定命令, 标度化值

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [1], [1], [0], [0], [0], [1], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(4)[信息对象],
  colspanx(8)[值], rowspanx(2)[SVA=标度化值（在 7.2.6.7 中定义）], (),
  [S], colspanx(7)[值], (), (),
  [S/E], colspanx(7)[QL], [QOS=设定命令限定词（在 7.2.6.39 中定义）], ()
)


== 7.3.2.6 类型标识 50 : C_SE_NC_1

设定命令, 短浮点数

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [1], [1], [0], [0], [1], [0], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(5)[信息对象],
  colspanx(8)[小数], rowspanx(4)[IEEE STD 754 短浮点数（在 7.2.6.8 中定义）], (),
  colspanx(8)[小数], (), (),
  [E], colspanx(7)[小数], (), (),
  [S], colspanx(7)[指数], (), (),
  [S/E], colspanx(7)[QL], [QOS=设定命令限定词（在 7.2.6.39 中定义）], ()
)

== 7.3.2.7 类型标识 51 : C_BO_NA_1

32 比特串

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [0], [1], [1], [0], [0], [1], [1], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(5)[信息对象],
  colspanx(8)[比特串], rowspanx(4)[BSI=二进制状态信息, 32bit（在 7.2.6.13 中定义）], (),
  colspanx(8)[比特串], (), (),
  colspanx(8)[比特串], (), (),
  colspanx(8)[比特串], (), ()
)

== 7.3.3 在监视方向系统信息的应用服务数据单元
类型标识 70 : M_EI_NA_1

初始化结束

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [0], [0], [0], [1], [1], [0], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(2)[信息对象],
  colspanx(8)[CP8], [COI=初始化原因（在 7.2.6.21 中定义）], ()
)

== 7.3.4 在控制方向系统信息的应用服务数据单元

== 7.3.4.1 类型标识 100 : C_IC_NA_1

召唤命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [0], [1], [0], [0], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(2)[信息对象],
  colspanx(8)[CP8], [QOI=召唤限定词（在 7.2.6.22 中定义）], ()
)

== 7.3.4.2 类型标识 101 : C_CI_NA_1

计数量召唤命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [0], [1], [0], [1], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(2)[信息对象],
  colspanx(8)[CP8], [QCC=计数量召唤命令限定词（在 7.2.6.23 中定义）], (),
)

== 类型标识 102 : C_RD_NA_1

读命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [0], [1], [1], [0], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], [信息对象],
)

== 7.3.4.4 类型标识 103 : C_CS_NA_1

时钟同步命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [0], [1], [1], [1], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(2)[信息对象],
  colspanx(8)[CP56Time2a 在 7.2.6.18 中定义], [七个八位位组二进制时间（从毫秒至年的日期和时钟时间）], ()
)

== 7.3.4.5 类型标识 104 : C_TS_NA_1

测试命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [1], [0], [0], [0], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(3)[信息对象],
  [1], [0], [1], [0], [1], [0], [1], [0], rowspanx(2)[FBP=固定测试字（在 7.2.6.14 中定义）], (),
  [0], [1], [0], [1], [0], [1], [0], [1], (), (),
)

== 7.3.4.6 类型标识 105 : C_RP_NA_1

复位进程命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [1], [0], [0], [1], [类型标识 (TYP)], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词 (VSQ)], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因 (COT)], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(2)[信息对象],
  colspanx(8)[UI8], [GRP=复位进程命令限定词（在 7.2.6.27 中定义）], ()
)

== 7.3.4.7 类型标识 106 : C_CD_NA_1

延时获得命令

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [1], [0], [1], [0], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(2)[信息对象],
  colspanx(8)[CP16Time2a 在 7.2.6.20 中定义], [两个八位位组二进制时间（毫秒至秒）], ()
)

== 在控制方向参数的应用服务数据单元

== 7.3.5.1 类型标识 110 : P_ME_NA_1

测量值参数, 归一化值

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [1], [1], [1], [0], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(4)[信息对象],
  colspanx(8)[值], rowspanx(2)[NVA=归一化值（在 7.2.6.6 中定义）], (),
  [S], colspanx(7)[值], (), (),
  colspanx(8)[CP8], [QPM=测量值参数限定词（在 7.2.6.24 中定义）], ()
)

== 7.3.5.2 类型标识 111 : P_ME_NB_1

测量值参数, 标度化值

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [0], [1], [1], [1], [1], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址=0], rowspanx(4)[信息对象],
  colspanx(8)[值], rowspanx(2)[SVA=标度化值（在 7.2.6.7 中定义）], (),
  [S], colspanx(7)[值], (), (),
  colspanx(8)[CP8], [QPM=测量值参数限定词（在 7.2.6.24 中定义）], ()
)

== 7.3.5.3 类型标识 112 : P_ME_NC_1

测量值参数, 短浮点数

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [1], [0], [0], [0], [0], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(6)[信息对象],
  colspanx(8)[小数], rowspanx(4)[SVA=标度化值（在 7.2.6.7 中定义）], (),
  colspanx(8)[小数], (), (),
  [E], colspanx(7)[小数], (), (),
  [S], colspanx(7)[指数], (), (),
  colspanx(8)[UI8], [QPM=测量值参数限定词（在 7.2.6.24 中定义）], ()
)

== 7.3.5.4 类型标识 113 : P_AC_NA_1

参数激活

单个信息对象（SQ = 0）

#tablex(
  columns: 10,
  align: center + horizon,
  stroke: (thickness: 0.3pt, paint: black),
  [0], [1], [1], [1], [0], [0], [0], [1], [类型标识（TYP）], rowspanx(4)[数据单元标识符#linebreak()在 7.1 中定义],
  [0], [0], [0], [0], [0], [0], [0], [1], [可变结构限定词（VSQ）], (),
  colspanx(8)[在 7.2.3 中定义], [传送原因（COT）], (),
  colspanx(8)[在 7.2.4 中定义], [应用服务数据单元公共地址], (),
  colspanx(8)[在 7.2.5 中定义], [信息对象地址], rowspanx(2)[信息对象],
  colspanx(8)[UI8], [QPA=参数激活限定词（在 7.2.6.25 中定义）], ()
)

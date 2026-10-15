# 任意 n 个生成元的两族例子

取 epsilon=1 或 -1，q_ii=epsilon，q_ij q_ji=1。任意选择下三角的 n(n-1)/2 个非零参数。定义一次生成元 x_i 和二次生成元 z_ji (i<j)：

1. x_j x_i = q_ji x_i x_j + z_ji；
2. z_ji x_k = q_jk q_ik x_k z_ji；
3. z_ji z_lk = q_jl q_jk q_il q_ik z_lk z_ji。

下标范围：i<j，k<l（第三式）；第二式 k=1,...,n。第二、三式的双向版本互为等价，不是额外约束。

所有 z 先生成一个量子多项式代数 B，然后依次添加 x_1,...,x_n。第 j 步使用 sigma_j(z_lk)=q_jl q_jk z_lk，sigma_j(x_i)=q_ji x_i，delta_j(z_lk)=0，delta_j(x_i)=z_ji (i<j)。利用 q_ij q_ji=1（包括 q_ii^2=1）可验证 sigma 为自同构，delta 为 sigma-导子。因此这是有 n(n+1)/2 个变量的连通分次迭代 Ore 扩张。

所以该代数具有 PBW 基，是 noetherian domain，并且 AS 正则，全局维数与 GK 维数为 n(n+1)/2；Hilbert 级数为 (1-t)^(-n)(1-t^2)^(-n(n-1)/2)。PBW 基可按 Lyndon 顺序 x_1,z_21,x_2,z_31,z_32,x_3,... 排列。

每对一次生成元给出齐次 down-up 子代数，参数 alpha=(1+epsilon)q_ji，beta=-epsilon q_ji^2，gamma=0。

对应闭集是所有单字母及所有二字母 Lyndon 词 ji (j>i)，取 f_w=w（TailMode=None）。本构造给出原三生成元第一分支中再加 q_13 q_31=1 的子族。任意公共对角 s 的全部分支没有在这里推广；不能把 epsilon 任意改为 s 后沿用本证明。

## 运行例子

在单独的输入单元中先运行：

```wolfram
Get["C:/Users/刘唯/Documents/Wolfram/mathematica/mathematica/ArbitraryGenerators.wl"]
```

然后：

```wolfram
data4 = TwoStepConstruction[4, 2, 1];
GroebnerConditions[data4]["Condition"]
CheckTwoStepFamily[4, 2, 60, -1]
```

TwoStepConstruction[n,p,epsilon] 取 q_ji=p (j>i)，q_ij=1/p (i<j)。此脚本面向精确数值参数，例如 p=2；不要在此函数中传入符号分母，核心包要求构造矩阵为多项式。

## 实际验证

在 Mathematica 14.2 下，以 p=2 分别取 epsilon=1,-1，n=2,3,4,5，八个例子的全部临界余式均为零。两份报告分别为 arbitrary-generators-checks.wl 和 arbitrary-generators-minus-checks.wl。

| n | PBW 生成元 | 首词数 | 临界歧义数 |
|---|---|---|---|
| 2 | 3 | 2 | 1 |
| 3 | 6 | 9 | 16 |
| 4 | 10 | 24 | 85 |
| 5 | 15 | 50 | 290 |

Ore 扩张的同调依据可参见 Liu–Wang–Wu, Twisted Calabi–Yau property of Ore extensions, https://arxiv.org/abs/1205.0893 。本例的具体 sigma/delta 和参数族由上述关系直接给出，不是该文对本例作出的分类。

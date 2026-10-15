# 从 Lyndon 闭集构造 AS 正则代数

实现 `main.tex` 当前的**多重次数齐次 Kharchenko 构造**。字母数量、顺序、次数和辫子矩阵均可修改。程序不修改论文文件。

## 运行

新增超级字母算法：运行 `RunConstructionSuper.wl`，按引理 3.3 在扩大的生成元集上检查三元重叠；六元素闭集检查 20 个三元式，并验证原关系的兼容性。配置、检查点恢复和性能说明见 [SUPER-ALGORITHM.zh.md](SUPER-ALGORITHM.zh.md)。该入口无需 NCAlgebra，配置独立于旧入口。

- `LyndonAS.wl`：算法和 NCAlgebra 接口。
- `RunConstruction.wl`：配置、逐步输出、参数求解。
- `Start.nb`：Mathematica notebook 启动入口。
- `Examples.wl`：四元素闭集的参数分类，以及包含真正尾项参数的五元素闭集。
- `Tests.wlt`：Mathematica 测试，最后一个测试需要 NCAlgebra。

先按照 [NCAlgebra 官方说明](https://github.com/NCAlgebra/NC#installing-ncalgebra)安装 NCAlgebra 6。官方目前提供：

```wolfram
PacletInstall["https://github.com/NCAlgebra/NC/blob/master/NCAlgebra-6.0.5.paclet?raw=true"]
```

打开 `Start.nb`，或在 Mathematica 中运行：

```wolfram
Get["/你的项目路径/mathematica/RunConstruction.wl"]
```

建议使用新内核，避免已有的字母或参数赋值影响结果。程序不会自动安装包。若暂未安装 NCAlgebra，可将入口中的 `loadNCAlgebra = False`，仍能计算词、稀疏括号多项式和参数条件。全部精确中间结果同时保存到 `construction-result.wl`，可用 `Get` 恢复。

## 配置

```wolfram
alphabetSize = 2;
letters = Table[Symbol["Global`x" <> ToString[i]], {i, alphabetSize}];
letterDegrees = ConstantArray[1, alphabetSize];
U = {{1}, {2, 1}, {2, 2, 1}, {2}};
braidingMatrix = Automatic;
tailMode = "Kharchenko";
runReduce = True;
reduceTimeLimit = 60;
```

词 `{2,2,1}` 表示 x₂x₂x₁，编号按字母从小到大排列。`Automatic` 默认生成 `Global` 上下文中的参数 `q11,q12,q21,q22`，分别表示 q₁₁、q₁₂、q₂₁、q₂₂，通常输出不带上下文前缀。可以直接使用 `q11` 等符号编写附加条件和替换规则；运行前请清除这些符号的旧赋值，或启动新内核。`c3x1` 表示按程序次序排列的第 3 个首词的第 1 个尾词系数，具体对应关系输出为表格。仍可用 `"ParameterContext"` 指定独立上下文。字母数量超过 9 时，为避免索引重名，使用 `q1x11` 等带分隔符的名称。

增加为三个字母时修改数量，并选取包含三个单字母的闭集，例如：

```wolfram
alphabetSize = 3;
U = {{1}, {2}, {3}};
```

函数也可以独立使用：

```wolfram
data = BuildConstruction[U, "AlphabetSize" -> 3];
data["Phi"]
data["TailWords"]
nc = NCExpressions[data];
nc["F"]
nc["G"]
report = GroebnerConditions[data];
SolveCoefficientConditions[report, True, 60]
```

`"TailMode"` 另有 `"None"`、`"TriangularKharchenko"`、`"QuasiTriangularKharchenko"`，分别对应无尾项和定义中的两种更强条件。

## 数学约定与算法

1. **词序**：Lyndon 词大于所有真后缀；左 quasi-lex 序中真前缀更大，例如 `21 < 2`。Gröbner 约化使用次数优先、同次数左字典序。
2. **闭性检查**：每个字母都在 U 中，每个词的每个 Lyndon 因子也在 U 中。否则返回 `Failure`，列出缺失因子，不擅自补全输入。
3. **Φ(U)**：枚举 U 中两个词的拼接，保留不在 U 中、且所有真 Lyndon 因子都在 U 中的 Lyndon 词。这是完整枚举，因为最小禁词的两个 Shirshov 因子都在 U 中。不是只检查两个 Shirshov 因子的 Φ̄(U)。
4. **尾项**：枚举每个首词 w 的所有同字母次数词 v，保留每个 Lyndon atom 都严格小于 w 的词，给每个尾词配置一个独立标量参数。允许参数为零；不额外要求这些原子在 U 中。
5. **括号**：Lyndon 词按 Shirshov 分解递归；其他词按非降 Lyndon 分解取括号的乘积。辫子系数由两词的字母次数和矩阵 q 相乘得到。NCAlgebra 接口通过 `NCExpand` 独立计算另一份括号结果，与稀疏算法核对。
6. **Gröbner 条件**：枚举交叠及包含歧义，计算 S-polynomial 并完全约化。全部余式的每个系数同时为零，当且仅当原 G 是 Gröbner 基。同时加入所有 qᵢⱼ 非零。
7. **AS 正则性**：在满足条件的分支上，使用论文的 Kharchenko 命题及 triangular PBW 定理，得到全局维数和 GK 维数均为 |U|，Hilbert 级数为所有 u∈U 的 (1−t^{deg u})⁻¹ 的乘积。`ConstructionInvariants` 明确将结论标为以 Gröbner 条件和文中定理为前提；它没有另外计算自由分解或 Ext。

## 参数分类与 NCMakeGB 的分工

不能直接把含参数的 `NCMakeGB` 输出当作全部参数分支的分类：符号计算若除以可能为零的参数表达式，会漏掉相应分支。

这里原关系的首项系数恒为 1，约化只使用这些首一关系，**不除以参数表达式，也不把非零余式加入新的关系集**。因此条件覆盖全部特化，包括尾项系数为零的情形。程序区分“原 G 已是 Gröbner 基”和“给 G 添加关系后获得 Gröbner 基”。

`SolveCoefficientConditions` 对完整条件调用 `Reduce[..., Complexes]`，针对特征零的复数参数。精确多项式方程保留在报告中。求解超时返回 `Missing["TimeLimit"]` 和原方程，不把未完成的求解当作无解。

辫子矩阵须为精确多项式，不接受符号分母或机器小数。若要设 q₁₂=1/p，保留独立 q₁₂，在求解时加上 p q₁₂=1。尾项数量可能随次数快速增长，程序不会默默截断枚举。大型问题可先设 `runReduce=False` 查看方程。

## 当前四元素闭集

对 U={1,21,221,2}，程序给出 Φ(U)={211,22121,2221}。三个允许尾词列表都是空集。因此，**按当前定义及多重次数齐次要求，这个 U 只能产生 f_w=w**。

独立精确计算给出 3 个临界交叠。记 a=q₁₁、d=q₂₂、h=q₁₂q₂₁，在所有辫子参数非零时，系数条件等价于：

```text
a h = 1，且
    a = d²
或者
    a = d 且 d²+d+1 = 0。
```

`Examples.wl` 用 `Reduce` 检查程序输出与此条件的等价性，并提供参数点 q={{4,1},{1/4,2}} 的 NCAlgebra 验证入口。

另外提供 U′={1,211,21,221,2}。其首词 `2211` 允许尾词 `2121`，即 f₂₂₁₁=2211+c·2121。在 flip braiding、其他尾项为零的切片中，独立精确求解得 c=0。这是求解结果，不是枚举时预先删除了尾项；一般辫子参数可以继续求解。

## 验证

在 Mathematica 中运行测试：

```wolfram
TestReport["/你的项目路径/mathematica/Tests.wlt"]
```

对一个具体参数点：

```wolfram
VerifySpecialization[data, parameterRules]
VerifyWithNCAlgebra[data, parameterRules, 20]
```

后者只接受完全特化的精确参数，调用 `NCMakeGB` 并检查所得基的首词仍为 Φ(U)。达到迭代上限或出现消息时，不返回交叉验证成功。`SetMonomialOrder[letters]` 中 letters 是一个列表，表示 graded lex；不使用表示消元序的逐个参数形式。所有关系多重次数齐次，因此即使字母具有不同正次数，每条关系内部的首词也与该 graded lex 序一致。参见 [NCAlgebra Gröbner 文档](https://github.com/NCAlgebra/NC/blob/master/DOCUMENTATION/MANUAL/NCGB.md)。

本次环境没有 Mathematica/Wolfram 内核和 NCAlgebra，**尚未实际执行 `.wl`、`.wlt` 或 NCAlgebra 集成测试**。已执行的独立 SymPy 检查在 `../verification/check_lyndon_as.py`，报告在 `../verification/lyndon_as_checks.json`，覆盖：

- 14 个两字母闭集的 Φ(U)，与有证明长度界内的逐词穷举比较；
- braided bracket 的显式公式；
- 当前四元素闭集的全部符号临界余式及成立、不成立的参数点；
- 三字母量子多项式代数的三重交叠；
- 五元素闭集的尾项参数切片。

这些检查验证算法和数学结果，不能替代 Mathematica 的真实运行测试。

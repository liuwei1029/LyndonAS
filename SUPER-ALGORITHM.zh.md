# 超级字母算法：引理 3.3

对应 Zhou–Lu, *Lyndon words for Artin-Schelter regular algebras*, arXiv:1403.0385v1，第 12–13 页的 Lemma 3.3。

## 直接使用

建议使用新的 Mathematica 内核，然后运行：

```wolfram
Get["C:/Users/刘唯/Documents/Wolfram/mathematica/mathematica/RunConstructionSuper.wl"]
```

此入口独立配置，**不会读取旧入口中的配置**。默认是

```wolfram
alphabetSize = 3;
U = {{1}, {2, 1}, {2}, {3, 1}, {3, 2}, {3}};
braidingMatrix = Automatic;
tailMode = "Kharchenko";
extraConditions = True;
```

这里 `Length[U] == 6`，目标全局维数为 6；它不是指代数作为向量空间只有六维。
若想加入共同对角参数条件，改为

```wolfram
extraConditions = q11 == q22 && q22 == q33;
```

六元素的二生成元例子可以改成：

```wolfram
alphabetSize = 2;
U = {{1}, {2}, {2, 1}, {2, 1, 1},
     {2, 1, 1, 1}, {2, 1, 1, 1, 1}};
letterDegrees = ConstantArray[1, alphabetSize];
```

其他闭集见 `closed-sets-n2-size6.md`。`tailMode` 与旧程序保持一致：`"Kharchenko"`、`"TriangularKharchenko"`、`"QuasiTriangularKharchenko"`、`"None"`。选 `"None"` 会改变所考察的参数族，而不仅仅是一个性能开关。

## 在现有 construction 上使用

```wolfram
Get["C:/Users/刘唯/Documents/Wolfram/mathematica/mathematica/LyndonASSuper.wl"];

super = BuildSuperConstruction[construction];
If[FailureQ[super], Print[super]; Abort[]];

report = SuperGroebnerConditions[super];
If[FailureQ[report], Print[report]; Abort[]];

compressed = SaturateCoefficientConditions[
  report, construction["BraidingMatrix"], extraConditions, 600];
If[FailureQ[compressed], Print[compressed]; Abort[]];

solution = SolveCoefficientConditions[compressed, extraConditions, 600];
```

`construction` 是旧函数 `BuildConstruction` 返回的 Association，不是闭集本身。
不需要 NCAlgebra；旧模块的 NCAlgebra 交叉检查仍可在具体参数点使用。

## 输出与恢复

入口只打印交换关系、方程数量、`Solution` 的实际结果和计算状态。完整数据仍保存在结果文件中。`Completed` 表示最终求解已完成（或未请求求解时，条件已生成），`TimedOut` 表示是否有阶段超时，`TimedOutStages` 列出超时阶段。若饱和超时后使用原始方程成功求解，可以同时出现 `Completed -> True` 和 `TimedOut -> True`。`Solution: False` 表示已证无解，不表示超时。

- `super["U"]`：排序后的 Lyndon 词；新算法内部的整数指向此表的位置。
- `super["SuperRules"]`：`Head -> Tail` 的稀疏交换规则。
- `super["PairTails"][[i,j]]`：`[x_u,x_v] = h_(u,v)` 中的 `h`，`i>j`。
- `SuperExpression[p,super]`：把稀疏多项式显示为 `x` 的下标记号和非交换乘积。
- `report["Triples"]`：按 `super["U"]` 的索引表示的所有降序三元组。
- `report["Remainders"]`：对应三元式的完全约化余式。
- `report["CompatibilityRemainders"]`：原定义关系在超级字母规则下的余式。
- `report["Condition"]`：上述两类余式的系数同时为零，加上所有 `q_ij != 0`。
- `super["BuildStatistics"]`、`report["CheckStatistics"]`：耗时、缓存词数和规则应用次数。

入口保存三个独立文件，不覆盖旧算法的结果：

1. `super-construction-checkpoint.wl`：转换完成后保存，可以跳过重新构造。
2. `super-conditions-checkpoint.wl`：饱和处理之前的原始系数条件。
3. `construction-result-super.wl`：本次最终结果，包括 `"Solution"`。

恢复并延长求解时间：

```wolfram
dir = "C:/Users/刘唯/Documents/Wolfram/mathematica/mathematica";
Get[FileNameJoin[{dir, "LyndonASSuper.wl"}]];
super = Get[FileNameJoin[{dir, "super-construction-checkpoint.wl"}]];
report = Get[FileNameJoin[{dir, "super-conditions-checkpoint.wl"}]];
compressed = SaturateCoefficientConditions[report,
  super["BraidingMatrix"], q11 == q22, 1200];
SolveCoefficientConditions[compressed, q11 == q22, 1200]
```

每个检查点只在对应阶段成功结束后更新；如果新运行在此前失败，旧检查点仍然属于旧运行。最终结果中的 `"Status"` 和 `"Stage"` 用于识别本次失败。

`"Solved" -> True, "Result" -> False` 仍表示条件无解，**不是超时**。
`Missing["TimeLimit"]` 或 `Failure["TimeLimit",...]` 表示未算完。
入口的 `"Status" -> "ConditionsComputed"` 表示条件已生成，但没有完成参数分类或未请求分类。
构造/检查失败时，入口保存 `"Status" -> "Incomplete"`，不输出 Gröbner 判定。
饱和超时遵循旧函数的行为：保留原始方程继续求解，并记录 `"SaturationSucceeded" -> False`。

## 实现方式与等价性

新算法有两个阶段。

**转换阶段**仍使用原始字母，但对单词的约化结果、Lyndon 括号以及 PBW 基变换做缓存。对每一对 `u>v`，计算 `[[u],[v]]` 的一个原规则余式，再以单位三角消元写成有序超级字母的线性组合 `h_(u,v)`。整个过程不除以参数。

因此每个新交换关系都是原理想与定义关系 `x_u=[u]` 的推论。程序还检查标准 Shirshov 分解确实给出定义关系。

**判定阶段**完全在超级字母上工作。对全部 `u>v>w` 构造引理 3.3 的 `J(u,v,w)`，用新交换规则约化。六元素闭集有 15 条交换规则、20 个三元式。

由于旧程序只给出 `Phi(U)` 上的关系，且尾项可能含有不属于 `U` 的 Lyndon 因子，新程序额外约化原关系的超级字母提升。该兼容性检查保证原理想也包含在新理想中，不强加 `PhiBar(U)\Phi(U)` 上的零括号。

精确性依据：

1. 新关系是原关系的推论，且包含超级字母的定义关系。
2. 三元余式为零保证新规则合流，其标准基是有序超级字母单词。
3. 原关系的兼容性余式为零保证两种表示定义同一个代数。
4. 有序超级字母基与原始 `Phi(U)`-不可约单词之间是单位三角变换，因此原关系也构成 Gröbner 基。
5. 反过来，若原关系构成 Gröbner 基，原 PBW 基独立性保证上述两类余式全部为零。

条件对原参数族是必要且充分的。新旧程序输出的多项式列表不必相同；应比较非零 `q_ij` 条件下的解集或饱和理想。

## 性能与限制

- 新方法加速的是交换关系生成与非交换一致性检查；不保证交换系数的 `GroebnerBasis` 或 `Reduce` 总能迅速完成。
- 构造阶段仍会展开原始括号，`BuildConstruction` 的尾项枚举也仍使用旧实现。特别大的闭集仍可能在这些阶段变慢。
- 每个阶段单独限时；可修改入口的 `buildTimeLimit`、`superBuildTimeLimit`、`superCheckTimeLimit`、`saturationTimeLimit` 和 `reduceTimeLimit`。
- `"MaxReductions"` 限制整个阶段对未缓存单词应用规则的总次数，默认一百万；这与旧 `NormalForm` 的单个余式步数限制不同。
- 想先查看方程，可以设置 `runReduce = False`；想跳过系数饱和，则设置 `runSaturation = False`。
- `SuperGroebnerConditions[super, "KeepRemainders" -> False]` 可减少结果文件体积，不影响所得到的方程。

初次实测见 `super-benchmark-results.wl`。同一内核中的一次运行，含转换的新检查阶段与旧检查阶段比较：

| 例子 | 新转换+检查（秒） | 旧检查（秒） | 新/旧系数多项式数 |
|---|---:|---:|---:|
| 四元素二生成元 | 0.040 | 0.056 | 3 / 17 |
| 六元素三生成元 | 0.074 | 0.222 | 13 / 64 |
| 六元素二生成元，词为 `21,211,2111,21111` | 0.167 | 7.290 | 19 / 178 |

这些数字不包括共同的 `BuildConstruction`、系数饱和或 `Reduce`，不是完整运行的加速倍数。前两个例子完成了饱和理想的双向包含核对；第三个例子的该项核对在初始时间预算内未完成，不能把超时当作已验证。

## 测试

```wolfram
TestReport[FileNameJoin[{dir, #}] & /@
  {"Tests.wlt", "SaturationTests.wlt", "SuperTests.wlt"}]
```

包含原算法回归测试、新旧小例子的全部参数分支对比、含非 `U` 尾项的六元素例子的饱和理想对比，以及全部 15 个二字母六元素闭集的精确参数点交叉检查。

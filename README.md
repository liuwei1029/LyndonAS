# LyndonAS

用 Wolfram Language / Mathematica 从 Lyndon 闭集构造多重次数齐次的带参数代数，计算 PBW / Gröbner 条件，并求解参数。

提供原始字母算法，以及基于 Zhou–Lu 引理 3.3 的超级字母算法。超级字母算法在六元素闭集上检查 20 个三元式，并额外验证原定义关系的兼容性，以保留原来的参数族。

## 快速开始

在 Mathematica 中打开 `RunConstructionSuper.wl`，修改开头的配置并运行。也可以在新内核中执行：

```wolfram
Get["/path/to/LyndonAS/RunConstructionSuper.wl"]
```

将路径替换为本机仓库位置。主要配置为：

```wolfram
alphabetSize = 3;
U = {{1}, {2, 1}, {2}, {3, 1}, {3, 2}, {3}};
letterDegrees = ConstantArray[1, alphabetSize];
braidingMatrix = Automatic;
tailMode = "Kharchenko";
extraConditions = True;
```

仓库中的入口保存的是当前工作配置；上面是可自行选用的六元素例子。修改 `alphabetSize` 时也需要修改 `U` 和 `letterDegrees`。

`q11 == q22` 等附加关系可写入 `extraConditions`。`"None"` 尾项模式会改变考察的参数族，不只是性能选项。

入口只打印交换关系、方程数量、解和完成/超时状态。完整计算结果与检查点保存在本地，不纳入版本控制。`Solution: False` 表示无解，超时会单独标明。

## 文件

| 文件 | 用途 |
|---|---|
| `LyndonAS.wl` | Lyndon 词、原始字母约化、系数饱和与参数求解 |
| `LyndonASSuper.wl` | 缓存约化、超级字母交换规则和三元条件 |
| `RunConstructionSuper.wl` | 推荐的运行入口 |
| `RunConstructionSaturated.wl` | 原始算法与非零参数饱和 |
| `RunConstruction.wl` | 原始运行入口 |
| `ArbitraryGenerators.wl` | 任意生成元数的示例族 |
| `EnumerateClosedSets.wl` | 有限 Lyndon 闭集枚举 |
| `Tests.wlt`, `SaturationTests.wlt`, `SuperTests.wlt` | 回归和交叉验证 |

详细说明：[超级字母算法](SUPER-ALGORITHM.zh.md)、[原程序说明](README.zh.md)、[饱和处理](SATURATION.zh.md)、[任意生成元示例](ARBITRARY-GENERATORS.zh.md)、[二字母六元素闭集](closed-sets-n2-size6.md)。部分详细说明中的绝对路径是开发机器上的示例，使用时请替换。

## 环境和验证

已在 Mathematica 14.2 中验证。超级字母入口不依赖 NCAlgebra；原测试中的独立交叉检查使用 NCAlgebra 6。

```wolfram
dir = "/path/to/LyndonAS";
TestReport[FileNameJoin[{dir, #}] & /@
  {"Tests.wlt", "SaturationTests.wlt", "SuperTests.wlt"}]
```

最近验证为 40 项测试通过，包括全部 15 个二字母六元素闭集的 30 个精确参数点交叉检查。性能记录见 `super-benchmark-results.wl`；其中超时项目明确标为 `Missing["SaturationTimeLimit"]`，不代表验证成功。

系数条件的生成、交换系数的 Gröbner 基计算以及 `Reduce` 分别可能耗时。维数与 AS 正则性结论以相应数学假设和 Gröbner 条件成立为前提。

## 文献

- G.-S. Zhou, D.-M. Lu, [Lyndon words for Artin-Schelter regular algebras](https://arxiv.org/abs/1403.0385), Lemma 3.3.
- T. Gateva-Ivanova, [Algebras defined by Lyndon words and Artin-Schelter regularity](https://arxiv.org/abs/1905.11281).

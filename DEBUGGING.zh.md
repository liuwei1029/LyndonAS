# 调试结果（2026-10-12）

已修复 `LyndonAS.wl` 和 `Tests.wlt`。使用本机 Mathematica 14.2.0、NCAlgebra 6.0.3 实际验证，26 项测试全部通过，详见 `test-results.wl`。

## 重新运行

1. 在 Mathematica 中退出旧内核：Evaluation → Quit Kernel → Local。
2. 打开同目录 `Start.nb`，选中第一个输入单元，按 Shift+Enter。
3. 应得到 `Phi(U) = {{2,1,1},{2,2,1,2,1},{2,2,2,1}}`，三个尾词列表均为空，临界交叠数为 3。

也可以在新内核的独立输入单元中运行：

```wolfram
Get["C:/Users/刘唯/Documents/Wolfram/mathematica/mathematica/RunConstruction.wl"]
```

独立执行测试：

```wolfram
TestReport["C:/Users/刘唯/Documents/Wolfram/mathematica/mathematica/Tests.wlt"]
```

本机已安装 NCAlgebra，无需重新安装。完整执行过 `RunConstruction.wl`、`Examples.wl`；原有的错误 `construction-result.wl` 已由成功运行的精确结果更新。入口原本只保存构造、条件和不变量，参数求解结果仍通过变量 `solutionReport` 查看。

## 修复原因

- **Lyndon 词序误判**：`Do` 内的 `Return` 只退出循环，后面的长度比较覆盖了首个不同字母的比较结果，导致 `21`、`221` 被误判为非 Lyndon 词。现在先找出首个不同字母，在循环外完成比较。
- **非零余式被错误清空**：`NormalForm` 在 `While` 内使用 `Return`，使非零余式或步数超限失败被函数结尾的 `{}` 覆盖。现在用独立标签的 `Catch`/`Throw` 返回，避免错误判定 Gröbner 基。
- **失败未正确传递**：`GroebnerConditions` 现在正确传递约化失败；构造中的首词检查移到 `Table` 外，避免局部返回掩盖错误。
- **参数特化没有执行**：`AssociateTo` 原来接收了多个独立规则参数，触发参数个数错误。改为规则列表，实际更新矩阵、关系、约化规则及非零约束。
- **测试无法独立加载**：`TestReport` 中 `$InputFileName` 为空。测试现在优先使用 `$TestFileName`，新内核无需预先加载算法包。

## 验证范围

原有 19 项测试在修复前有 13 项失败，修复后全部通过。新增 7 项测试涵盖首个不同字母的比较、不可约非零余式、约化后非零余式、约化超限、失败向上传递、有效/无效/零辫子参数的精确特化，以及 U4 全部复数参数分支。

额外完整运行确认：

- 默认 U4 的稀疏括号与 NCAlgebra 独立计算的三个括号全部一致。
- `Examples.wl` 的 U4 分类反例搜索返回 `False`，即与 README 的分类等价。
- U5 在 flip braiding 下的尾项参数解为 `c3x1 == 0`。
- `q={{4,1},{1/4,2}}` 的三个临界余式均为零；NCMakeGB 返回三个关系，首词匹配，`CrossCheckPassed -> True`。

原 README 的“尚未实际执行”是旧记录，现以本说明和 `test-results.wl` 为准。原压缩包未包含其引用的 `../verification` 文件；本次验证直接使用真实 Wolfram 内核。

## 论文例 5.1

`main.pdf` 第 11 页例 5.1 列出的三个 f 都是单项式，却在结论中出现了未写入这三个式子的参数 b。按当前列出的关系和第 4 节定义，`q={{-1,1},{1,-1}}` 的临界余式不全为零，不能判定为 Gröbner 基。README 中 U4 的另一组参数分类已通过精确验证。若要得到该例声称的 D 型代数，需要另行核对例子是否漏写了关系项。

原 README 与 RunConstruction.wl 的附加更新被 Windows 文件权限拒绝，因此保留原文件；正常的 Get/Start.nb 入口已通过验证。本说明不依赖那些未能保存的附加改动。

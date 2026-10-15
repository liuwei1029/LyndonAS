# 系数方程的饱和 Gröbner 基

新增 `SaturateCoefficientConditions[report, q, extra, seconds]`。对系数多项式生成的理想 I，加入辅助变量 z 及 `z Product[qij] - 1`，以 z 为首变量按字典序计算交换 Gröbner 基，再取不含 z 的元素，得到饱和理想 `I : Product[qij]^Infinity` 的生成元。z 内部使用唯一符号，不占用 Hilbert 级数中的 t。

消元后的方程仍与 `qij != 0` 联用；单独删除非零条件会引入边界点。`extra` 中通过 And 连接的多项式等式会参与 Gröbner 基计算，其他逻辑约束保留在最终 Condition 中。

## 使用

重新加载 LyndonAS.wl 后，在已有 conditionReport 和 construction 的内核中执行：

```wolfram
compactReport = SaturateCoefficientConditions[
  conditionReport, construction["BraidingMatrix"], q11 == q22, 60];
compactReport["Equations"] // Column
compactReport["SaturationStatus"]
SolveCoefficientConditions[compactReport, True, 600]
```

不添加额外等式时，将 `q11 == q22` 改为 `True`。成功状态为 `"Completed"`。若返回 `Missing["TimeLimit"]`，报告会保留原方程和约束，不把未完成的计算当作已简化或无解。

## 自动入口

原 RunConstruction.wl 在编辑时无法写入，所以新增 RunConstructionSaturated.wl。新入口复制了当时的配置 `U={{1},{2,1},{2}}`，在显示方程和调用 Reduce 前自动执行饱和步骤。后续修改配置请编辑新入口，两份入口不会自动同步。

```wolfram
Get["C:/Users/刘唯/Documents/Wolfram/mathematica/mathematica/RunConstructionSaturated.wl"]
```

新入口保存到 construction-result-saturated.wl，包括 Solution 字段。`saturationTimeLimit=60` 限制系数 Gröbner 基计算，`reduceTimeLimit=600` 限制后续 Reduce，两者分别计时。

## 实测

Mathematica 14.2 / NCAlgebra 6.0.3 下，原 26 项测试和新增 4 项饱和测试全部通过。新增测试文件为 SaturationTests.wlt。

对当前三个词的闭集，原 3 个系数方程压缩成 `q11-q22==0`；保留非零条件后与原条件等价（Reduce 已验证），参数解为 `q22==q11 && q11!=0 && q12!=0 && q21!=0`。这是三个词闭集的结果，不是此前六个词闭集的结果。

原始系数方程保存在 `OriginalCoefficientPolynomials`，原始完整条件保存在 `OriginalCondition`；交叠及余式字段保留用于核查。饱和 Gröbner 基不保证对所有输入都减少方程数或计算时间。

Get[FileNameJoin[{DirectoryName[$TestFileName], "LyndonAS.wl"}]];
VerificationTest[
 Module[{r, s}, r = <|"Parameters" -> {a, b}, "CoefficientPolynomials" -> {a b},
   "Equations" -> {a b == 0}, "BraidingCondition" -> a != 0,
   "Condition" -> a b == 0 && a != 0|>;
  s = SaturateCoefficientConditions[r, {{a}}, True, 10];
  {s["SaturationSucceeded"], s["CoefficientPolynomials"],
   Reduce[Xor[r["Condition"], s["Condition"]], {a, b}, Complexes]}],
 {True, {b}, False}, TestID -> "saturate-nonzero-factor"]
VerificationTest[
 Module[{r, s}, r = <|"Parameters" -> {a}, "CoefficientPolynomials" -> {a},
   "BraidingCondition" -> a != 0, "Condition" -> a == 0 && a != 0|>;
  s = SaturateCoefficientConditions[r, {{a}}, True, 10];
  {s["CoefficientPolynomials"], s["Condition"]}],
 {{1}, False}, TestID -> "saturation-detects-empty-open-set"]
VerificationTest[
 Module[{d, r, s}, d = BuildConstruction[{{1}, {2,1}, {2,2,1}, {2}}];
  r = GroebnerConditions[d];
  s = SaturateCoefficientConditions[r, d["BraidingMatrix"], q11 == q22, 20];
  {s["SaturationSucceeded"],
   Reduce[Xor[r["Condition"] && q11 == q22, s["Condition"]], d["Parameters"], Complexes]}],
 {True, False}, TestID -> "saturation-preserves-extra-equation-branches"]
VerificationTest[
 Module[{d, r, s}, d = BuildConstruction[{{1}, {2,1}, {2,2,1}, {2}}];
  r = GroebnerConditions[d];
  s = SaturateCoefficientConditions[r, d["BraidingMatrix"], True, 0];
  {s["SaturationSucceeded"], s["SaturationStatus"],
   s["Condition"] === r["Condition"], s["CoefficientPolynomials"] === r["CoefficientPolynomials"]}],
 {False, Missing["TimeLimit"], True, True}, TestID -> "saturation-timeout-retains-original"]

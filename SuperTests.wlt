Get[FileNameJoin[{DirectoryName[If[StringQ[$TestFileName] && $TestFileName =!= "",
  $TestFileName, $InputFileName]], "LyndonASSuper.wl"}]];

VerificationTest[
  Module[{d, s, r}, d = BuildConstruction[{{1}, {2}}]; s = BuildSuperConstruction[d];
    r = SuperGroebnerConditions[s]; {Length[s["SuperRules"]], r["TripleCount"], r["CoefficientPolynomials"]}],
  {1, 0, {}}, TestID -> "super-quantum-plane-no-triples"]

VerificationTest[
  Module[{d, s, r}, d = BuildConstruction[{{1}, {2, 1}, {2}}]; s = BuildSuperConstruction[d];
    r = SuperGroebnerConditions[s];
    Reduce[Xor[r["Condition"], GroebnerConditions[d]["Condition"]], d["Parameters"], Complexes]],
  False, TestID -> "super-U3-exact-all-branches"]

VerificationTest[
  Module[{d, s, r}, d = BuildConstruction[{{1}, {2, 1}, {2, 2, 1}, {2}}];
    s = BuildSuperConstruction[d]; r = SuperGroebnerConditions[s];
    Reduce[Xor[r["Condition"], GroebnerConditions[d]["Condition"]], d["Parameters"], Complexes]],
  False, TestID -> "super-U4-exact-all-branches"]

VerificationTest[
  Module[{d, s}, d = BuildConstruction[{{1}, {2, 1}, {2}}];
    s = BuildSuperConstruction[d, "MaxReductions" -> 0]; s[[1]]],
  "SuperReductionLimit", TestID -> "super-build-limit-is-failure"]

VerificationTest[
  Module[{d, s}, d = BuildConstruction[{{1}, {2, 1}, {2}}]; s = BuildSuperConstruction[d];
    SuperGroebnerConditions[s, "MaxReductions" -> 0][[1]]],
  "SuperReductionLimit", TestID -> "super-check-limit-is-failure"]

VerificationTest[
  Module[{d, s, r}, d = BuildConstruction[{{1}, {2, 1}, {2}}, "LetterDegrees" -> {2, 3}];
    s = BuildSuperConstruction[d]; r = SuperGroebnerConditions[s];
    {s["SuperDegrees"], Reduce[Xor[r["Condition"], GroebnerConditions[d]["Condition"]], d["Parameters"], Complexes]}],
  {{2, 5, 3}, False}, TestID -> "super-weighted-degrees"]

VerificationTest[
  Module[{d, s, a, b, ga, gb, vars},
    d = BuildConstruction[{{1}, {2, 1}, {2}, {3, 1}, {3, 2}, {3}}, "AlphabetSize" -> 3];
    s = BuildSuperConstruction[d]; vars = d["Parameters"];
    a = SaturateCoefficientConditions[GroebnerConditions[d], d["BraidingMatrix"], True, 60];
    b = SaturateCoefficientConditions[SuperGroebnerConditions[s], d["BraidingMatrix"], True, 60];
    If[!TrueQ[a["SaturationSucceeded"]] || !TrueQ[b["SaturationSucceeded"]], False,
      ga = GroebnerBasis[a["CoefficientPolynomials"], vars];
      gb = GroebnerBasis[b["CoefficientPolynomials"], vars];
      And @@ (Last[PolynomialReduce[#, ga, vars]] === 0 & /@ gb) &&
        And @@ (Last[PolynomialReduce[#, gb, vars]] === 0 & /@ ga)]],
  True, TestID -> "super-U6-non-U-tails-and-PhiBar-gap-preserve-saturated-ideal"]

VerificationTest[
  Module[{root, sets, d, s, r, answers, oldVerdict},
    root = DirectoryName[If[StringQ[$TestFileName] && $TestFileName =!= "", $TestFileName, $InputFileName]];
    sets = Get[FileNameJoin[{root, "closed-sets-n2-size6.wl"}]];
    (* At exact numeric points one nonzero ambiguity already disproves the GB
       property. Use the ORIGINAL reducer, checking shorter witnesses first. *)
    oldVerdict[data_] := Module[{amb, polynomial, nf, tag = Unique["verdict"]},
      amb = SortBy[CriticalAmbiguities[data["Phi"]], Length[#["Word"]] &];
      Catch[Do[polynomial = Join[
        ({Join[a["LeftPrefix"], First[#], a["LeftSuffix"]], Last[#]} & /@ data["G"][[a["LeftIndex"]]]),
        ({Join[a["RightPrefix"], First[#], a["RightSuffix"]], -Last[#]} & /@ data["G"][[a["RightIndex"]]])];
        nf = NormalForm[polynomial, data["Rules"], data["LetterDegrees"]];
        If[FailureQ[nf], Throw[nf, tag]];
        If[nf =!= {}, Throw[False, tag]], {a, amb}]; True, tag]
    ];
    answers = Flatten[Table[TimeConstrained[
      d = BuildConstruction[u, "TailMode" -> "None", "BraidingMatrix" -> q];
      s = BuildSuperConstruction[d]; If[FailureQ[s], False,
        r = SuperGroebnerConditions[s]; If[FailureQ[r], False,
          SameQ[r["Condition"], oldVerdict[d]]]], 20, False],
      {u, sets}, {q, {{{1, 1}, {1, 1}}, {{-1, 1}, {1, -1}}}}]];
    {Length[answers], And @@ answers}],
  {30, True}, TestID -> "super-all-15-U6-sets-two-exact-specializations"]

VerificationTest[
  Module[{d, s, r}, d = BuildConstruction[{{1}, {2, 1}, {2}}, "BraidingMatrix" -> {{1, 2}, {1/2, 1}}];
    s = BuildSuperConstruction[d]; r = SuperGroebnerConditions[s]; r["Condition"]],
  True, TestID -> "super-exact-rational-braiding"]

VerificationTest[
  Module[{d, s, r}, d = BuildConstruction[{{1}, {2, 1}, {2}}]; s = BuildSuperConstruction[d];
    r = SuperGroebnerConditions[s, "KeepRemainders" -> False];
    {KeyExistsQ[r, "Remainders"], KeyExistsQ[r, "CompatibilityRemainders"], Length[r["Equations"]]}],
  {False, False, 1}, TestID -> "super-compact-report-retains-equations"]

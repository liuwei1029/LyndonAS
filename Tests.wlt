(* Run in Mathematica: TestReport["/absolute/path/mathematica/Tests.wlt"] *)
(* TestReport sets $TestFileName; $InputFileName is empty in a fresh test run. *)
Get[FileNameJoin[{DirectoryName[If[StringQ[$TestFileName] && $TestFileName =!= "",
  $TestFileName, $InputFileName]], "LyndonAS.wl"}]];

VerificationTest[
  {LyndonLess[{1}, {2}], LyndonLess[{2}, {1}],
   LyndonLess[{2, 1}, {2, 2}], LyndonLess[{2, 1}, {2, 1}],
   LyndonWordQ[{2, 1}], LyndonWordQ[{2, 2, 1}]},
  {True, False, True, False, True, True}, TestID -> "first-different-letter-order"]

VerificationTest[
  NormalForm[{{{1, 2}, 3}}, {}, {1, 1}],
  {{{1, 2}, 3}}, TestID -> "irreducible-nonzero-remainder-is-preserved"]

VerificationTest[
  NormalForm[{{{2, 1}, 1}},
    {<|"Head" -> {2, 1}, "Tail" -> {{{1, 2}, 2}}|>}, {1, 1}],
  {{{1, 2}, 2}}, TestID -> "reduction-preserves-final-nonzero-remainder"]

VerificationTest[
  NormalForm[{{{2, 1}, 1}},
    {<|"Head" -> {2, 1}, "Tail" -> {{{1, 2}, 2}}|>}, {1, 1}, 0][[1]],
  "ReductionLimit", TestID -> "normal-form-limit-is-a-failure"]

VerificationTest[
  Module[{d}, d = BuildConstruction[{{1}, {2, 1}, {2, 2, 1}, {2}}];
    GroebnerConditions[d, 0][[1]]],
  "ReductionLimit", TestID -> "critical-pair-limit-propagates"]

VerificationTest[
  Module[{d, q}, d = BuildConstruction[{{1}, {2, 1}, {2, 2, 1}, {2}}];
    q = Flatten[d["BraidingMatrix"]];
    {VerifySpecialization[d, Thread[q -> {4, 1, 1/4, 2}]]["IsGroebnerBasis"],
     VerifySpecialization[d, Thread[q -> {-1, 1, 1, -1}]]["IsGroebnerBasis"],
     VerifySpecialization[d, Thread[q -> {1, 1, 0, 1}]]["IsGroebnerBasis"]}],
  {True, False, False}, TestID -> "exact-specialization-updates-all-data"]

VerificationTest[
  Module[{d, q, expected}, d = BuildConstruction[{{1}, {2, 1}, {2, 2, 1}, {2}}];
    q = d["BraidingMatrix"];
    expected = And @@ (# != 0 & /@ Flatten[q]) &&
      q[[1, 1]] q[[1, 2]] q[[2, 1]] == 1 &&
      (q[[1, 1]] == q[[2, 2]]^2 ||
        (q[[1, 1]] == q[[2, 2]] && q[[2, 2]]^2 + q[[2, 2]] + 1 == 0));
    TimeConstrained[Reduce[Xor[GroebnerConditions[d]["Condition"], expected],
      d["Parameters"], Complexes], 60, $Aborted]],
  False, TestID -> "U4-all-parameter-branches"]

VerificationTest[
  {LyndonLess[{2, 1}, {2}], LyndonLess[{2}, {2, 1}]},
  {True, False}, TestID -> "proper-prefix-is-greater"]

VerificationTest[
  LyndonDecomposition[{1, 2, 1, 2, 2, 1, 2}],
  {{1}, {2, 1}, {2, 2, 1}, {2}}, TestID -> "CFL-maximal-convention"]

VerificationTest[
  ShirshovSplit[{2, 2, 1, 2, 1}],
  {{2, 2, 1}, {2, 1}}, TestID -> "longest-proper-Lyndon-suffix"]

VerificationTest[
  ValidateClosedSet[{{1}, {2}, {2, 2, 1}}, 2][[1]],
  "NotClosed", TestID -> "missing-21-rejected"]

VerificationTest[
  Sort[PhiClosedSet[{{1}, {2, 1}, {2, 2, 1}, {2}}, 2]],
  Sort[{{2, 1, 1}, {2, 2, 2, 1}, {2, 2, 1, 2, 1}}], TestID -> "Phi-U4"]

VerificationTest[
  Sort[PhiClosedSet[{{1}, {2}, {3}}, 3]],
  Sort[{{2, 1}, {3, 1}, {3, 2}}], TestID -> "three-letter-configuration"]

VerificationTest[
  KharchenkoTails[{2, 1}, 2], {}, TestID -> "quantum-plane-no-Kharchenko-tails"]

VerificationTest[
  KharchenkoTails[{2, 2, 1, 1}, 2], {{2, 1, 2, 1}},
  TestID -> "genuine-Kharchenko-tail-2211"]

VerificationTest[
  Module[{u}, u = {{1}, {2}, {2, 1}, {2, 2, 1}, {2, 2, 1, 2, 1}};
    MemberQ[PhiClosedSet[u, 2], {2, 2, 2, 1, 2, 1}]],
  False, TestID -> "Phi-is-not-Phi-bar"]

VerificationTest[
  Length[CriticalAmbiguities[{{2, 1, 2, 1}}]], 1,
  TestID -> "self-overlap-enumeration"]

VerificationTest[
  Count[CriticalAmbiguities[{{2, 1, 1}, {1, 1}}], a_Association /; a["Kind"] === "Inclusion"],
  1, TestID -> "inclusion-enumeration"]

VerificationTest[
  Sort[BraidedBracket[{2, 2, 1}, {{aa, bb}, {cc, dd}}]],
  Sort[{{{2, 2, 1}, 1}, {{2, 1, 2}, -cc - cc dd}, {{1, 2, 2}, cc^2 dd}}],
  TestID -> "braided-221-formula"]

VerificationTest[
  Module[{d, r}, d = BuildConstruction[{{1}, {2}}, "BraidingMatrix" -> {{1, 1}, {2, 1}}];
    r = GroebnerConditions[d]; {Length[r["Ambiguities"]], r["Condition"]}],
  {0, True}, TestID -> "quantum-plane-Diamond"]

VerificationTest[
  Module[{d, r}, d = BuildConstruction[{{1}, {2}, {3}}, "AlphabetSize" -> 3,
      "BraidingMatrix" -> {{1, 2, 3}, {5, 1, 7}, {11, 13, 1}}];
    r = GroebnerConditions[d]; {Length[r["Ambiguities"]], r["Condition"]}],
  {1, True}, TestID -> "quantum-three-space-triple-overlap"]

VerificationTest[
  Module[{d}, d = BuildConstruction[{{1}, {2, 1}, {2, 2, 1}, {2}},
    "TailMode" -> "None", "BraidingMatrix" -> ConstantArray[1, {2, 2}]];
    GroebnerConditions[d]["Condition"]],
  True, TestID -> "U4-flip-zero-tail-is-GB"]

VerificationTest[
  Module[{d}, d = BuildConstruction[{{1}, {2, 1}, {2, 2, 1}, {2}},
    "TailMode" -> "None", "BraidingMatrix" -> {{-1, 1}, {1, -1}}];
    GroebnerConditions[d]["Condition"]],
  False, TestID -> "U4-old-parameter-claim-is-not-GB"]

VerificationTest[
  Module[{d, r, p}, d = BuildConstruction[{{1}, {2}}, "BraidingMatrix" -> {{1, 1}, {qq, 1}}];
    r = GroebnerConditions[d]; p = SolveCoefficientConditions[r, True, 10];
    {p["Solved"], FullSimplify[p["Result"] \[Equivalent] (qq != 0)]}],
  {True, True}, TestID -> "Reduce-retains-nonzero-braiding"]

VerificationTest[
  Module[{d}, d = BuildConstruction[{{1}, {2}}];
    FailureQ[VerifyWithNCAlgebra[d, {}]]],
  True, TestID -> "NC-cross-check-rejects-unassigned-parameters"]

(* This integration test requires NCAlgebra 6 / NCGBX, unlike the tests above. *)
VerificationTest[
  Module[{d, check}, d = BuildConstruction[{{1}, {2}},
    "BraidingMatrix" -> {{1, 1}, {2, 1}}];
    check = VerifyWithNCAlgebra[d, {}, 10];
    If[FailureQ[check], check, check["CrossCheckPassed"]]],
  True, TestID -> "NCAlgebra-integration-quantum-plane"]

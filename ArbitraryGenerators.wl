(* Arbitrary-rank, cocycle-twisted free two-step nilpotent family.
   Existing configurations/results are not changed. Use exact p != 0. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "LyndonAS.wl"}]];

TwoStepClosedSet[n_Integer?Positive] := Join[
  List /@ Range[n], Flatten[Table[{j, i}, {j, 2, n}, {i, 1, j - 1}], 1]];

(* For symbolic parameters, use independent polynomial q_ij in the main
   package, then impose q_ii==1 and q_ij q_ji==1. Here p is exact numeric. *)
TwoStepConstruction[n_Integer?Positive, p_: 2, epsilon_: 1] := BuildConstruction[
  TwoStepClosedSet[n], "AlphabetSize" -> n, "TailMode" -> "None",
  "BraidingMatrix" -> Table[Which[i == j, epsilon, i > j, p, True, 1/p], {i, n}, {j, n}]];

CheckTwoStepFamily[n_Integer?Positive, p_: 2, seconds_: 60, epsilon_: 1] := Module[{d, r, elapsed},
  d = TwoStepConstruction[n, p, epsilon];
  If[FailureQ[d], Return[d]];
  {elapsed, r} = AbsoluteTiming[TimeConstrained[GroebnerConditions[d], seconds, Missing["TimeLimit"]]];
  If[!AssociationQ[r], Return[<|"n" -> n, "p" -> p, "Result" -> r, "Seconds" -> elapsed|>]];
  <|"n" -> n, "p" -> p, "Epsilon" -> epsilon, "PBWGenerators" -> Length[d["U"]],
    "Relations" -> Length[d["Phi"]], "Ambiguities" -> Length[r["Ambiguities"]],
    "IsGroebnerBasis" -> TrueQ[r["Condition"]], "Seconds" -> elapsed|>
];

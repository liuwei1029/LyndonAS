(* Evaluate in a fresh kernel. NCAlgebra is needed only in the optional final block. *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "LyndonAS.wl"}]];

(* Example 1: the manuscript's U4, all generic diagonal braidings. *)
u4 = {{1}, {2, 1}, {2, 2, 1}, {2}};
d4 = BuildConstruction[u4];
r4 = GroebnerConditions[d4];
q4 = d4["BraidingMatrix"];
expected4 = And @@ (# != 0 & /@ Flatten[q4]) &&
  q4[[1, 1]] q4[[1, 2]] q4[[2, 1]] == 1 &&
  (q4[[1, 1]] == q4[[2, 2]]^2 ||
    (q4[[1, 1]] == q4[[2, 2]] && q4[[2, 2]]^2 + q4[[2, 2]] + 1 == 0));

(* False means the two conditions have no counterexample to equivalence. *)
classificationCounterexample = TimeConstrained[
  Reduce[Xor[r4["Condition"], expected4], d4["Parameters"], Complexes], 60, Missing["TimeLimit"]];
Print["U4 classification counterexample (expected False): ", classificationCounterexample];
Print["U4 admissible tails (expected {{},{},{}}): ", d4["TailWords"]];

(* Example 2: a closed set with one genuine Kharchenko tail. *)
u5 = {{1}, {2, 1, 1}, {2, 1}, {2, 2, 1}, {2}};
d5 = BuildConstruction[u5, "BraidingMatrix" -> ConstantArray[1, {2, 2}],
  "ParameterContext" -> "U5Parameters`"];
r5 = GroebnerConditions[d5];
Print["U5 Phi and tails: ", Transpose[{d5["Phi"], d5["TailWords"]}]];
Print["Flip braiding tail-coefficient solutions (coefficient must be zero): ",
  SolveCoefficientConditions[r5, True, 60]];

(* Optional: uncomment AFTER installing NCAlgebra.
sample4 = Thread[Flatten[q4] -> {4, 1, 1/4, 2}];
VerifyWithNCAlgebra[d4, sample4, 20]
*)

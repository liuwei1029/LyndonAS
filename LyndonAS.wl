(* ::Package:: *)
(* Exact, specialization-safe Lyndon/Kharchenko construction.
   Words are lists of letter indices; sparse polynomials are {{word, coefficient}, ...}.
   NCAlgebra 6 is loaded only by NCExpressions / VerifyWithNCAlgebra.
   Coefficient equations are computed over Q[parameters], never its fraction field. *)

BeginPackage["LyndonAS`"];

LyndonLess::usage = "LyndonLess[u,v] compares words in left quasi-lex order: a proper prefix is greater.";
LyndonWordQ::usage = "LyndonWordQ[w] tests the maximal Lyndon convention of the manuscript.";
LyndonDecomposition::usage = "LyndonDecomposition[w] gives nondecreasing Lyndon atoms.";
ShirshovSplit::usage = "ShirshovSplit[w] returns the left factor and longest proper Lyndon suffix.";
ValidateClosedSet::usage = "ValidateClosedSet[U,n] returns True or a Failure explaining why U is not closed.";
PhiClosedSet::usage = "PhiClosedSet[U,n] computes the complete finite set Phi(U), with no length cutoff.";
KharchenkoTails::usage = "KharchenkoTails[w,n,mode] enumerates ALL same-multidegree tails satisfying mode (default Kharchenko).";
BraidedBracket::usage = "BraidedBracket[w,q] returns the sparse polynomial [w]_c for diagonal braiding q.";
BuildConstruction::usage = "BuildConstruction[U, options] builds every generic f_w and its bracket, with monic rules.";
CriticalAmbiguities::usage = "CriticalAmbiguities[heads] enumerates intersection, self-overlap and inclusion ambiguities.";
NormalForm::usage = "NormalForm[p,rules,degrees,maxSteps] completely reduces a sparse polynomial using monic rules.";
GroebnerConditions::usage = "GroebnerConditions[data,maxSteps] returns necessary and sufficient polynomial conditions for the ORIGINAL G to be a Groebner basis.";
SolveCoefficientConditions::usage = "SolveCoefficientConditions[report,extra,seconds] applies Reduce over Complexes to all parameters, including q_ij != 0.";
SaturateCoefficientConditions::usage = "SaturateCoefficientConditions[report,q,extra,seconds] compresses coefficient equations using t Product[q_ij]-1 and eliminates t, retaining nonzero constraints. Timeout preserves the original equations.";
VerifySpecialization::usage = "VerifySpecialization[data,rules] substitutes parameters and recomputes all critical remainders.";
ToNCExpression::usage = "ToNCExpression[sparse,letters] converts a sparse polynomial to an NCAlgebra expression (load NCAlgebra first).";
NCExpressions::usage = "NCExpressions[data] loads NCAlgebra, constructs f and braided G directly with NCExpand, and checks against the sparse calculation.";
VerifyWithNCAlgebra::usage = "VerifyWithNCAlgebra[data,exactParameterRules,iterations] checks an exact specialization using both critical pairs and NCMakeGB.";
ConstructionInvariants::usage = "ConstructionInvariants[data,t] gives the PBW Hilbert series and dimensions, conditional on the Groebner conditions.";

Begin["`Private`"];

LyndonLess[u_List, v_List] := Module[{i = 1, m = Min[Length[u], Length[v]]},
  (* Return inside Do exits Do, not this Module. Compare outside the loop. *)
  While[i <= m && u[[i]] === v[[i]], i++];
  If[i <= m, u[[i]] < v[[i]], Length[u] > Length[v]]
];

LyndonWordQ[w_List] := Length[w] > 0 &&
  And @@ Table[LyndonLess[Drop[w, i], w], {i, Length[w] - 1}];

LyndonDecomposition[{}] := {};
LyndonDecomposition[w_List] := Module[{k},
  (* The last atom is the longest Lyndon suffix, including w itself. *)
  k = First@Select[Range[0, Length[w] - 1], LyndonWordQ[Drop[w, #]] &];
  Append[LyndonDecomposition[Take[w, k]], Drop[w, k]]
];

ShirshovSplit[w_List] := Module[{k},
  If[Length[w] < 2 || !LyndonWordQ[w],
    Return[Failure["NotCompositeLyndon", <|"Word" -> w|>]]];
  k = First@Select[Range[1, Length[w] - 1], LyndonWordQ[Drop[w, #]] &];
  {Take[w, k], Drop[w, k]}
];

subwords[w_List] := DeleteDuplicates@Flatten[
  Table[Take[w, {i, j}], {i, Length[w]}, {j, i, Length[w]}], 1];
properLyndonFactors[w_List] := Select[subwords[w], # =!= w && LyndonWordQ[#] &];
multidegree[w_List, n_Integer] := Table[Count[w, i], {i, n}];
wordDegree[w_List, degrees_List] := Total[degrees[[w]]];
degreeLess[u_List, v_List, degrees_List] := With[
  {a = wordDegree[u, degrees], b = wordDegree[v, degrees]},
  If[a == b, LyndonLess[u, v], a < b]];

ValidateClosedSet[u_List, n_Integer] := Module[{bad, missing},
  If[n < 1 || u === {} || !And @@ (ListQ /@ u),
    Return[Failure["InvalidClosedSet", <|"U" -> u, "AlphabetSize" -> n|>]]];
  bad = Select[u, # === {} || !And @@ (IntegerQ[#] && 1 <= # <= n & /@ #) &];
  If[bad =!= {}, Return[Failure["InvalidWords", <|"Words" -> bad|>]]];
  If[Length[DeleteDuplicates[u]] != Length[u],
    Return[Failure["DuplicateWords", <|"U" -> u|>]]];
  bad = Select[u, !LyndonWordQ[#] &];
  If[bad =!= {}, Return[Failure["NotLyndon", <|"Words" -> bad|>]]];
  missing = Select[List /@ Range[n], !MemberQ[u, #] &];
  missing = Union[missing, Select[DeleteDuplicates@Flatten[
    properLyndonFactors /@ u, 1], !MemberQ[u, #] &]];
  If[missing === {}, True, Failure["NotClosed", <|"MissingLyndonFactors" -> missing|>]]
];

PhiClosedSet[u_List, n_Integer] := Module[{valid, candidates},
  valid = ValidateClosedSet[u, n]; If[FailureQ[valid], Return[valid]];
  (* If p is minimal outside U, both its Shirshov factors belong to U.
     Thus U.U contains every possible p; filtering all proper factors is essential. *)
  candidates = DeleteDuplicates@Flatten[Table[Join[a, b], {a, u}, {b, u}], 1];
  Sort[Select[candidates, LyndonWordQ[#] && !MemberQ[u, #] &&
    And @@ (MemberQ[u, #] & /@ properLyndonFactors[#]) &], LyndonLess]
];

multisetWords[counts_List] := If[Total[counts] == 0, {{}},
  Flatten[Table[If[counts[[i]] == 0, {},
    Prepend[#, i] & /@ multisetWords[ReplacePart[counts, i -> counts[[i]] - 1]]],
    {i, Length[counts]}], 1]];

KharchenkoTails[w_List, n_Integer, mode_: "Kharchenko"] := Module[{bound},
  If[!LyndonWordQ[w], Return[Failure["NotLyndon", <|"Word" -> w|>]]];
  If[mode === "None", Return[{}]];
  bound = Switch[mode,
    "Kharchenko", w,
    "TriangularKharchenko", If[Length[w] < 2, Return[{}], First@ShirshovSplit[w]],
    "QuasiTriangularKharchenko", If[Length[w] < 2, Return[{}], Last@ShirshovSplit[w]],
    _, Return[Failure["UnknownTailMode", <|"Mode" -> mode|>]]];
  Sort[Select[multisetWords[multidegree[w, n]],
    # =!= w && LyndonLess[#, w] &&
      And @@ (LyndonLess[#, bound] & /@ LyndonDecomposition[#]) &], LyndonLess]
];

(* Sparse polynomial operations: never divide by a parameter expression. *)
normalize[p_List] := Select[
  ({#[[1, 1]], Expand[Total[#[[All, 2]]]]} & /@ GatherBy[p, First]), Last[#] =!= 0 &];
scale[p_List, s_] := normalize[({First[#], s Last[#]} & /@ p)];
add[p_List, q_List] := normalize[Join[p, q]];
multiply[p_List, q_List] := normalize@Flatten[
  Table[{Join[a[[1]], b[[1]]], a[[2]] b[[2]]}, {a, p}, {b, q}], 1];
surround[p_List, left_List, right_List] :=
  ({Join[left, First[#], right], Last[#]} & /@ p);
braid[u_List, v_List, q_List] := Times @@ Flatten[Table[q[[i, j]], {i, u}, {j, v}]];

BraidedBracket[w_List, q_List] := Module[{br},
  br[{}] = {{{}, 1}};
  br[a_List] := br[a] = Module[{split, left, right, atoms},
    If[Length[a] == 1, Return[{{a, 1}}]];
    If[LyndonWordQ[a],
      split = ShirshovSplit[a]; left = br[split[[1]]]; right = br[split[[2]]];
      add[multiply[left, right], scale[multiply[right, left], -braid[split[[1]], split[[2]], q]]],
      atoms = LyndonDecomposition[a]; Fold[multiply, {{{}, 1}}, br /@ atoms]]
  ];
  br[w]
];

Options[BuildConstruction] = {"AlphabetSize" -> 2, "Letters" -> Automatic,
  "LetterDegrees" -> Automatic, "BraidingMatrix" -> Automatic,
  "TailMode" -> "Kharchenko", "ParameterContext" -> "Global`"};

BuildConstruction[u_List, OptionsPattern[]] := Module[
  {n = OptionValue["AlphabetSize"], letters = OptionValue["Letters"],
   degrees = OptionValue["LetterDegrees"], q = OptionValue["BraidingMatrix"],
   mode = OptionValue["TailMode"], context = OptionValue["ParameterContext"],
   valid, phi, tails, parameters, f, g, rules, variables, bad},
  If[!IntegerQ[n] || n < 1, Return[Failure["InvalidAlphabetSize", <||>]]];
  valid = ValidateClosedSet[u, n]; If[FailureQ[valid], Return[valid]];
  If[!StringQ[context] || !StringEndsQ[context, "`"],
    Return[Failure["InvalidParameterContext", <||>]]];
  If[letters === Automatic, letters = Table[Symbol["Global`x" <> ToString[i]], {i, n}]];
  If[Length[letters] != n || !And @@ (MatchQ[#, _Symbol] & /@ letters) ||
      Length[DeleteDuplicates[letters]] != n,
    Return[Failure["InvalidLetters", <|"Letters" -> letters|>]]];
  If[degrees === Automatic, degrees = ConstantArray[1, n]];
  If[!ListQ[degrees] || Length[degrees] != n ||
      !And @@ (IntegerQ[#] && # > 0 & /@ degrees),
    Return[Failure["InvalidLetterDegrees", <||>]]];
  (* Single-digit indices use q11, q12, ... for readable notebook output.
     Keep a separator for larger alphabets to avoid q1,11 / q11,1 collisions. *)
  If[q === Automatic, q = Table[Symbol[context <> "q" <> ToString[i] <>
    If[n <= 9, "", "x"] <> ToString[j]], {i, n}, {j, n}]];
  If[Dimensions[q] =!= {n, n}, Return[Failure["InvalidBraidingMatrix", <||>]]];
  If[!FreeQ[q, _Real | Indeterminate | _DirectedInfinity] || !FreeQ[q, Alternatives @@ letters] ||
      !And @@ (MatchQ[#, _Symbol] & /@ Variables[Flatten[q]]) ||
      !And @@ (PolynomialQ[#, Variables[{#}]] & /@ Flatten[q]),
    Return[Failure["PolynomialExactBraidingRequired", <|
      "Hint" -> "Use symbolic q_ij and impose rational identities as extra polynomial equations; do not use floating point."|>]]];
  If[MemberQ[Expand /@ Flatten[q], 0], Return[Failure["ZeroBraidingEntry", <||>]]];
  phi = PhiClosedSet[u, n];
  tails = KharchenkoTails[#, n, mode] & /@ phi;
  If[AnyTrue[tails, FailureQ], Return[First@Select[tails, FailureQ]]];
  parameters = Table[Table[Symbol[context <> "c" <> ToString[i] <> "x" <> ToString[j]],
    {j, Length[tails[[i]]]}], {i, Length[phi]}];
  If[!And @@ (MatchQ[#, _Symbol] & /@ Flatten[parameters]),
    Return[Failure["AssignedTailParameters", <|"Hint" -> "Clear the parameter context or use a fresh context."|>]]];
  If[!FreeQ[parameters, Alternatives @@ letters],
    Return[Failure["ParameterLetterCollision", <||>]]];
  f = Table[Join[{{phi[[i]], 1}}, MapThread[List, {tails[[i]], parameters[[i]]}]], {i, Length[phi]}];
  g = (Fold[add, {}, scale[BraidedBracket[First[#], q], Last[#]] & /@ #] &) /@ f;
  bad = Select[Range[Length[phi]], Function[i,
    Select[g[[i]], First[#] === phi[[i]] &] =!= {{phi[[i]], 1}} ||
      !And @@ (degreeLess[First[#], phi[[i]], degrees] & /@
        Select[g[[i]], First[#] =!= phi[[i]] &])]];
  If[bad =!= {}, Return[Failure["LeadingWordChanged", <|"Word" -> phi[[First[bad]]]|>]]];
  rules = Table[With[{p = g[[i]], w = phi[[i]]},
    <|"Head" -> w, "Tail" -> scale[Select[p, First[#] =!= w &], -1]|>], {i, Length[phi]}];
  variables = DeleteDuplicates@Join[Variables[Flatten[q]], Flatten[parameters]];
  <|"U" -> Sort[u, LyndonLess], "AlphabetSize" -> n, "Letters" -> letters,
    "LetterDegrees" -> degrees, "BraidingMatrix" -> q, "TailMode" -> mode,
    "Phi" -> phi, "TailWords" -> tails, "TailParameters" -> parameters,
    "Parameters" -> variables, "F" -> f, "G" -> g, "Rules" -> rules,
    "BraidingCondition" -> And @@ (# != 0 & /@ Flatten[q])|>
];

CriticalAmbiguities[heads_List] := Module[{out = {}, u, v, k, p},
  Do[u = heads[[i]]; v = heads[[j]];
    Do[If[Take[u, -k] === Take[v, k],
      AppendTo[out, <|"Kind" -> "Intersection", "LeftIndex" -> i, "RightIndex" -> j,
        "Word" -> Join[u, Drop[v, k]], "LeftPrefix" -> {}, "LeftSuffix" -> Drop[v, k],
        "RightPrefix" -> Drop[u, -k], "RightSuffix" -> {}|>]],
      {k, 1, Min[Length[u], Length[v]] - 1}];
    Do[If[Take[u, {p, p + Length[v] - 1}] === v && !(i == j && p == 1),
      AppendTo[out, <|"Kind" -> "Inclusion", "LeftIndex" -> i, "RightIndex" -> j,
        "Word" -> u, "LeftPrefix" -> {}, "LeftSuffix" -> {},
        "RightPrefix" -> Take[u, p - 1], "RightSuffix" -> Drop[u, p + Length[v] - 1]|>]],
      {p, 1, Length[u] - Length[v] + 1}],
    {i, Length[heads]}, {j, Length[heads]}]; out
];

NormalForm[polynomial_List, rules_List, degrees_List, maxSteps_: 100000] := Module[
  {p = normalize[polynomial], steps = 0, hit, w, coefficient, head, location, term,
   done = Unique["normalForm"]},
  Catch[While[p =!= {},
    p = Sort[p, degreeLess[First[#2], First[#1], degrees] &];
    hit = Catch[
      Do[w = p[[i, 1]]; head = rules[[j]]["Head"];
        Do[If[Take[w, {k, k + Length[head] - 1}] === head,
          Throw[{i, j, k}, "hit"]], {k, 1, Length[w] - Length[head] + 1}],
        {i, Length[p]}, {j, Length[rules]}]; None, "hit"];
    If[hit === None, Throw[p, done]];
    If[++steps > maxSteps, Throw[Failure["ReductionLimit", <|"Steps" -> steps,
      "Hint" -> "No Groebner verdict was made; increase maxSteps."|>], done]];
    term = hit[[1]]; location = hit[[3]]; w = p[[term, 1]]; coefficient = p[[term, 2]];
    head = rules[[hit[[2]]]]["Head"];
    p = add[Delete[p, term], scale[surround[rules[[hit[[2]]]]["Tail"],
      Take[w, location - 1], Drop[w, location + Length[head] - 1]], coefficient]];
  ]; {}, done]
];

GroebnerConditions[data_Association, maxSteps_: 100000] := Module[
  {ambiguities, remainders = {}, compositions = {}, s, nf, polynomials, condition,
   reductionResult, failed = Unique["criticalPair"]},
  ambiguities = CriticalAmbiguities[data["Phi"]];
  reductionResult = Catch[Do[s = add[surround[data["G"][[a["LeftIndex"]]], a["LeftPrefix"], a["LeftSuffix"]],
      scale[surround[data["G"][[a["RightIndex"]]], a["RightPrefix"], a["RightSuffix"]], -1]];
    nf = NormalForm[s, data["Rules"], data["LetterDegrees"], maxSteps];
    If[FailureQ[nf], Throw[nf, failed]];
    AppendTo[compositions, s]; AppendTo[remainders, nf], {a, ambiguities}], failed];
  If[FailureQ[reductionResult], Return[reductionResult]];
  polynomials = DeleteDuplicates[Factor /@ Flatten[(Last /@ # &) /@ remainders]];
  polynomials = Select[polynomials, # =!= 0 &];
  condition = (And @@ (# == 0 & /@ polynomials)) && data["BraidingCondition"];
  <|"Parameters" -> data["Parameters"], "Ambiguities" -> ambiguities,
    "Compositions" -> compositions, "Remainders" -> remainders,
    "CoefficientPolynomials" -> polynomials, "Equations" -> (# == 0 & /@ polynomials),
    "BraidingCondition" -> data["BraidingCondition"], "Condition" -> condition,
    "Meaning" -> "Necessary and sufficient for the original monic G to be a Groebner basis; q_ij are nonzero."|>
];

SaturateCoefficientConditions[report_Association, q_List, extra_: True, seconds_: 60] := Module[
  {out = report, auxiliary = Unique["inverseBraiding"], product = Times @@ Flatten[q],
   clauses, equalities, variables, gb, reduced, originalCondition},
  clauses = If[Head[extra] === And, List @@ extra, {extra}];
  equalities = (Subtract @@ # &) /@ Select[clauses, MatchQ[#, _Equal] && Length[#] == 2 &];
  variables = DeleteDuplicates@Join[report["Parameters"], Cases[Variables[equalities], _Symbol]];
  (* Only conjunctive polynomial equalities enter the ideal; other restrictions
     are retained in Condition, not converted into a different logical formula. *)
  equalities = Select[equalities, PolynomialQ[#, variables] &];
  If[!PolynomialQ[product, variables] || !FreeQ[{product, equalities}, _Real],
    Return[Failure["ExactPolynomialSaturationRequired", <||>]]];
  originalCondition = report["Condition"] && extra;
  gb = TimeConstrained[
    Check[GroebnerBasis[Join[report["CoefficientPolynomials"], equalities,
      {auxiliary product - 1}], Prepend[variables, auxiliary],
      MonomialOrder -> Lexicographic], $Failed], seconds, Missing["TimeLimit"]];
  AssociateTo[out, {"OriginalCoefficientPolynomials" -> report["CoefficientPolynomials"],
    "OriginalCondition" -> originalCondition, "Parameters" -> variables,
    "Condition" -> originalCondition, "ExtraConditions" -> extra,
    "SaturationSucceeded" -> ListQ[gb]}];
  If[!ListQ[gb], AssociateTo[out, "SaturationStatus" -> gb]; Return[out]];
  reduced = Factor /@ Select[gb, FreeQ[#, auxiliary] &];
  (* Elimination gives I : product^Infinity; keep nonzero constraints to exclude
     boundary points introduced by taking the algebraic closure. *)
  AssociateTo[out, {"SaturationStatus" -> "Completed",
    "CoefficientPolynomials" -> reduced, "Equations" -> (# == 0 & /@ reduced),
    "Condition" -> ((And @@ (# == 0 & /@ reduced)) && report["BraidingCondition"] && extra)}];
  out
];

SolveCoefficientConditions[report_Association, extra_: True, seconds_: 60] := Module[{answer},
  answer = TimeConstrained[
    Reduce[report["Condition"] && extra, report["Parameters"], Complexes],
    seconds, Missing["TimeLimit"]];
  <|"Result" -> answer, "Solved" -> (FreeQ[answer, _Reduce | _Missing] && answer =!= $Failed && answer =!= $Aborted),
    "ExactInputCondition" -> (report["Condition"] && extra), "Domain" -> Complexes|>
];

specialize[data_Association, substitutions_List] := Module[{d = data, g, q},
  q = data["BraidingMatrix"] /. substitutions;
  g = normalize /@ (data["G"] /. substitutions);
  AssociateTo[d, {"BraidingMatrix" -> q, "F" -> (normalize /@ (data["F"] /. substitutions)),
    "G" -> g, "Rules" -> Table[<|"Head" -> data["Phi"][[i]],
      "Tail" -> scale[Select[g[[i]], First[#] =!= data["Phi"][[i]] &], -1]|>, {i, Length[g]}],
    "BraidingCondition" -> And @@ (# != 0 & /@ Flatten[q]),
    "Parameters" -> Variables[Join[Flatten[q], Flatten[(Last /@ # &) /@ g]]]}];
  d
];

VerifySpecialization[data_Association, substitutions_List] := Module[{d, report, verdict},
  If[!And @@ (MatchQ[#, Rule[_Symbol, _]] & /@ substitutions),
    Return[Failure["SymbolParameterRulesRequired", <||>]]];
  d = specialize[data, substitutions];
  If[!FreeQ[{d["G"], d["BraidingMatrix"]}, _Real | Indeterminate | _DirectedInfinity],
    Return[Failure["ExactFiniteCoefficientsRequired", <||>]]];
  report = GroebnerConditions[d];
  If[FailureQ[report], Return[report]];
  verdict = FullSimplify[report["Condition"]];
  <|"IsGroebnerBasis" -> Which[TrueQ[verdict], True, verdict === False, False, True, Missing["Undetermined"]],
    "ResidualCondition" -> verdict, "Report" -> report|>
];

(* Resolve NCAlgebra exports AFTER loading its contexts; avoid creating shadow symbols. *)
nc[name_String] := ToExpression[name, InputForm];
loadNC[] := Module[{},
  Quiet[Needs["NCAlgebra`"]];
  If[!MemberQ[$Packages, "NCAlgebra`"],
    Quiet[Check[Get["NC`"], Null]];
    Quiet[Needs["NCAlgebra`"]];
    If[!MemberQ[$Packages, "NCAlgebra`"],
      Return[Failure["NCAlgebraNotInstalled", <|"Documentation" -> "https://github.com/NCAlgebra/NC#installing-ncalgebra"|>]]]];
  Quiet[Needs["NCGBX`"]];
  If[!MemberQ[$Packages, "NCGBX`"],
    Return[Failure["NCGBXNotInstalled", <||>]]]; True
];
ncWord[{}, letters_List] := 1;
ncWord[w_List, letters_List] := If[Length[w] == 1, letters[[First[w]]],
  NonCommutativeMultiply @@ letters[[w]]];
ToNCExpression[p_List, letters_List] := Total[(Last[#] ncWord[First[#], letters] & /@ p)];

NCExpressions[data_Association] := Module[{loaded, letters, q, b, f, g, checks, coefficients},
  loaded = loadNC[]; If[FailureQ[loaded], Return[loaded]];
  letters = data["Letters"]; q = data["BraidingMatrix"];
  Apply[nc["SetNonCommutative"], letters];
  coefficients = DeleteDuplicates@Join[data["Parameters"], Variables[Flatten[q]]];
  If[coefficients =!= {}, Apply[nc["SetCommutative"], coefficients]];
  b[{}] = 1;
  b[w_List] := b[w] = Module[{s, left, right},
    If[Length[w] == 1, Return[letters[[First[w]]]]];
    If[LyndonWordQ[w], s = ShirshovSplit[w]; left = b[s[[1]]]; right = b[s[[2]]];
      nc["NCExpand"][left ** right - braid[s[[1]], s[[2]], q] right ** left],
      nc["NCExpand"][NonCommutativeMultiply @@ (b /@ LyndonDecomposition[w])]]];
  f = ToNCExpression[#, letters] & /@ data["F"];
  g = (nc["NCExpand"][Total[(Last[#] b[First[#]] & /@ #)]] &) /@ data["F"];
  checks = MapThread[TrueQ[Expand[nc["NCExpand"][#1 - ToNCExpression[#2, letters]]] === 0] &, {g, data["G"]}];
  If[!And @@ checks, Return[Failure["BracketImplementationsDisagree", <|"Checks" -> checks|>]]];
  <|"F" -> f, "G" -> g, "PBWGenerators" -> (b /@ data["U"]), "BracketChecks" -> checks|>
];

VerifyWithNCAlgebra[data_Association, substitutions_List, iterations_: 20] := Module[
  {d, test, expressions, gb, headsMatch},
  If[!And @@ (MatchQ[#, Rule[_Symbol, _]] & /@ substitutions),
    Return[Failure["SymbolParameterRulesRequired", <||>]]];
  d = specialize[data, substitutions];
  If[d["Parameters"] =!= {} || !FreeQ[{d["G"], d["BraidingMatrix"]}, _Real],
    Return[Failure["ExactSpecializationRequired", <|
      "RemainingParameters" -> d["Parameters"],
      "Hint" -> "Assign exact values to all parameters for this NCMakeGB cross-check. Symbolic branches are described by GroebnerConditions."|>]]];
  test = VerifySpecialization[d, {}]; If[FailureQ[test], Return[test]];
  If[!TrueQ[test["IsGroebnerBasis"]], Return[test]];
  expressions = NCExpressions[d]; If[FailureQ[expressions], Return[expressions]];
  nc["ClearMonomialOrder"][];
  (* ONE list means graded lex. Passing the letters as separate arguments would mean elimination order. *)
  Apply[nc["SetMonomialOrder"], {d["Letters"]}];
  gb = Check[nc["NCMakeGB"][expressions["G"], iterations], $Failed];
  If[gb === $Failed || !ListQ[gb] || !And @@ (MatchQ[#, _Rule] & /@ gb),
    Return[Failure["NCMakeGBNotCertified", <|"DiamondCheck" -> test,
      "Hint" -> "NCMakeGB failed or emitted a message (including an iteration cutoff); inspect the kernel output."|>]]];
  headsMatch = Sort[First /@ gb] === Sort[ncWord[#, d["Letters"]] & /@ d["Phi"]];
  <|"IsGroebnerBasis" -> True, "NCLeadingWordsMatch" -> headsMatch,
    "CrossCheckPassed" -> headsMatch, "NCGroebnerBasis" -> gb, "DiamondCheck" -> test|>
];

ConstructionInvariants[data_Association, t_] := <|
  "Status" -> "Conditional on GroebnerConditions and the hypotheses of the manuscript's Kharchenko theorem",
  "GlobalDimension" -> Length[data["U"]], "GKDimension" -> Length[data["U"]],
  "HilbertSeries" -> Times @@ (1/(1 - t^wordDegree[#, data["LetterDegrees"]]) & /@ data["U"]),
  "PBWGeneratorWords" -> data["U"]|>;

End[];
EndPackage[];

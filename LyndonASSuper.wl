(* Exact super-letter backend for Lemma 3.3 of arXiv:1403.0385.
   The conversion is certified modulo the ORIGINAL relations. In particular,
   no extra zero brackets on PhiBar\Phi are imposed. *)
If[!MemberQ[$Packages, "LyndonAS`"],
  Get[FileNameJoin[{DirectoryName[$InputFileName], "LyndonAS.wl"}]]];

BeginPackage["LyndonASSuper`", {"LyndonAS`"}];
BuildSuperConstruction::usage = "BuildSuperConstruction[construction] transports the original monic relations to super-letters, using cached word reductions. Returns a Failure on incomplete conversion.";
SuperGroebnerConditions::usage = "SuperGroebnerConditions[superConstruction] checks Lemma 3.3 triples AND the original-relation compatibility conditions. The result is accepted by SaturateCoefficientConditions and SolveCoefficientConditions.";
SuperExpression::usage = "SuperExpression[sparse,superConstruction] displays a polynomial using noncommutative products of indexed super-letters.";

Begin["`Private`"];

norm[p_List] := Select[({#[[1, 1]], Expand[Total[#[[All, 2]]]]} & /@
  GatherBy[p, First]), Last[#] =!= 0 &];
sc[p_List, c_] := ({First[#], c Last[#]} & /@ p);
plus[p_List, r_List] := norm[Join[p, r]];
times[p_List, r_List] := norm[Flatten[
  Table[{Join[a[[1]], b[[1]]], a[[2]] b[[2]]}, {a, p}, {b, r}], 1]];
key[w_List] := StringRiffle[ToString /@ w, ","];
qword[u_List, v_List, q_List] := Times @@ Flatten[Table[q[[i, j]], {i, u}, {j, v}]];
less[a_List, b_List, degrees_List] := With[{da = Total[degrees[[a]]], db = Total[degrees[[b]]]},
  If[da == db, LyndonLess[a, b], da < db]];

(* Linear normal form with memoization per WORD, not per polynomial. Rules are
   monic and strictly decrease the weighted deglex order. No parameter division.
   The limit counts rule applications to uncached words across the entire phase. *)
makeReducer[rules_List, limit_, tag_] := Module[
  {wn, reduce, index, misses = 0, rewrites = 0, heads, tails},
  heads = Lookup[rules, "Head"]; tails = Lookup[rules, "Tail"];
  index = Association@Table[i -> Select[Range[Length[heads]], First[heads[[#]]] == i &],
    {i, DeleteDuplicates[If[heads === {}, {}, First /@ heads]]}];
  wn[w_List] := wn[w] = Module[{hit = None, candidates, len},
    misses++;
    Do[candidates = Lookup[index, w[[k]], {}];
      Do[len = Length[heads[[j]]];
        If[k + len - 1 <= Length[w] && Take[w, {k, k + len - 1}] === heads[[j]],
          hit = {j, k, len}; Break[]], {j, candidates}];
      If[hit =!= None, Break[]], {k, Length[w]}];
    If[hit === None, {{w, 1}},
      If[++rewrites > limit, Throw[Failure["SuperReductionLimit", <|
        "Limit" -> limit, "CachedWords" -> misses,
        "Hint" -> "No Groebner verdict was made. Increase MaxReductions."|>], tag]];
      norm[Flatten[Function[t, sc[wn[Join[Take[w, hit[[2]] - 1], t[[1]],
        Drop[w, hit[[2]] + hit[[3]] - 1]]], t[[2]]]] /@ tails[[hit[[1]]]], 1]]]
  ];
  reduce[p_List] := norm[Flatten[(sc[wn[First[#]], Last[#]] & /@ p), 1]];
  <|"Reduce" -> Function[p, reduce[p]],
    "Statistics" -> Function[Null, <|"CachedWords" -> misses, "RuleApplications" -> rewrites|>],
    "Release" -> Function[Null, Clear[wn, reduce]]|>
];

Options[BuildSuperConstruction] = {"MaxReductions" -> 1000000};
BuildSuperConstruction[data_Association, OptionsPattern[]] := Block[{$RecursionLimit = 4096}, Module[
  {u = data["U"], q = data["BraidingMatrix"], degrees = data["LetterDegrees"],
   ids, d, qq, sd, reducer, red, br, pbwNF, convert, lift, h, rules = {}, pairs = {},
   lifted, p, hh, split, left, right,
   result, stats, start = AbsoluteTime[], tag = Unique["superBuild"], limit = OptionValue["MaxReductions"]},
  If[!(limit === Infinity || (IntegerQ[limit] && limit >= 0)),
    Return[Failure["InvalidReductionLimit", <||>]]];
  d = Length[u]; ids = AssociationThread[key /@ u, Range[d]];
  sd = (Total[degrees[[#]]] & /@ u);
  qq = Table[qword[u[[i]], u[[j]], q], {i, d}, {j, d}];
  reducer = makeReducer[data["Rules"], limit, tag];
  red[p_] := reducer["Reduce"][p];
  br[{}] = {{{}, 1}};
  br[w_List] := br[w] = If[Length[w] == 1, {{w, 1}},
    If[LyndonWordQ[w], With[{s = ShirshovSplit[w]},
      plus[times[br[s[[1]]], br[s[[2]]]],
        sc[times[br[s[[2]]], br[s[[1]]]], -qword[s[[1]], s[[2]], q]]]],
      Fold[times, {{{}, 1}}, br /@ LyndonDecomposition[w]]]];
  pbwNF[w_List] := pbwNF[w] = red[Fold[times, {{{}, 1}}, br /@ LyndonDecomposition[w]]];
  (* Unitriangular change of basis on the original irreducible words. This is
     valid even BEFORE confluence is known: all reductions are ideal identities. *)
  convert[input_List] := Module[{work = norm[input], out = {}, w, c, aa, basis},
    While[work =!= {},
      work = Sort[work, less[First[#2], First[#1], degrees] &];
      {w, c} = First[work]; aa = LyndonDecomposition[w];
      If[!And @@ (KeyExistsQ[ids, key[#]] & /@ aa),
        Throw[Failure["NonPBWNormalWord", <|"Word" -> w|>], tag]];
      basis = pbwNF[w];
      If[Select[basis, First[#] === w &] =!= {{w, 1}} ||
          !And @@ (First[#] === w || less[First[#], w, degrees] & /@ basis),
        Throw[Failure["NonTriangularPBWConversion", <|"Word" -> w|>], tag]];
      AppendTo[out, {Lookup[ids, key /@ aa], c}];
      work = plus[work, sc[basis, -c]]];
    norm[out]
  ];
  (* A lift of the original bracket presentation through the defining identities
     x_u=[x_v,x_w]. Non-U tail atoms are recursively expanded only in super-letters. *)
  lift[w_List] := lift[w] = If[KeyExistsQ[ids, key[w]], {{{ids[key[w]]}, 1}},
    If[LyndonWordQ[w], With[{s = ShirshovSplit[w]},
      plus[times[lift[s[[1]]], lift[s[[2]]]],
        sc[times[lift[s[[2]]], lift[s[[1]]]], -qword[s[[1]], s[[2]], q]]]],
      Fold[times, {{{}, 1}}, lift /@ LyndonDecomposition[w]]]];
  result = CheckAbort[Catch[
    h = Table[{}, {d}, {d}];
    Do[
      p = plus[times[br[u[[i]]], br[u[[j]]]],
        sc[times[br[u[[j]]], br[u[[i]]]], -qq[[i, j]]]];
      hh = convert[red[p]];
      If[!And @@ (less[First[#], {i, j}, sd] & /@ hh),
        Throw[Failure["NonTriangularSuperRule", <|"Pair" -> {u[[i]], u[[j]]}|>], tag]];
      h[[i, j]] = hh;
      AppendTo[pairs, {i, j}];
      AppendTo[rules, <|"Head" -> {i, j}, "Tail" -> plus[{{{j, i}, qq[[i, j]]}}, hh]|>],
      {i, 2, d}, {j, 1, i - 1}];
    (* These identities make the original and extended alphabets equivalent. *)
    Do[If[Length[u[[k]]] > 1,
      split = ShirshovSplit[u[[k]]]; {left, right} = Lookup[ids, key /@ split];
      If[norm[Join[h[[left, right]], {{{k}, -1}}]] =!= {},
        Throw[Failure["SuperDefinitionMismatch", <|"Word" -> u[[k]]|>], tag]]], {k, d}];
    lifted = (norm[Flatten[(sc[lift[First[#]], Last[#]] & /@ #), 1]] &) /@ data["F"];
    stats = Join[reducer["Statistics"][], <|"Seconds" -> (AbsoluteTime[] - start),
      "PairCount" -> Length[pairs]|>];
    <|"Backend" -> "SuperLettersLemma3.3", "U" -> u,
      "SuperLetters" -> (Subscript["x", Row[#, If[data["AlphabetSize"] <= 9, "", ","]]] & /@ u), "SuperDegrees" -> sd,
      "BraidingMatrix" -> q, "PairBraiding" -> qq, "Pairs" -> pairs,
      "PairTails" -> h, "SuperRules" -> rules,
      "LiftedOriginalRelations" -> lifted, "OriginalPhi" -> data["Phi"],
      "Parameters" -> data["Parameters"], "BraidingCondition" -> data["BraidingCondition"],
      "BuildStatistics" -> stats|>, tag],
    reducer["Release"][]; Clear[br, pbwNF, lift]; Abort[]];
  reducer["Release"][]; Clear[br, pbwNF, lift]; result
]];

Options[SuperGroebnerConditions] = {"MaxReductions" -> 1000000, "KeepRemainders" -> True};
SuperGroebnerConditions[data_Association, OptionsPattern[]] := Block[{$RecursionLimit = 4096}, Module[
  {d = Length[data["U"]], q = data["PairBraiding"], h = data["PairTails"],
   reducer, result, tag = Unique["superCheck"], limit = OptionValue["MaxReductions"],
   keep = TrueQ[OptionValue["KeepRemainders"]], triples, remainders = {}, compatibility = {},
   polynomials = {}, jpoly, nf, start = AbsoluteTime[], out, letter},
  If[!(limit === Infinity || (IntegerQ[limit] && limit >= 0)),
    Return[Failure["InvalidReductionLimit", <||>]]];
  reducer = makeReducer[data["SuperRules"], limit, tag];
  letter[i_] := {{{i}, 1}};
  triples = Reverse /@ Subsets[Range[d], {3}];
  result = CheckAbort[Catch[
    Do[With[{i = t[[1]], j = t[[2]], k = t[[3]]},
      jpoly = norm[Join[
        times[h[[i, j]], letter[k]],
        sc[times[letter[k], h[[i, j]]], -q[[i, k]] q[[j, k]]],
        sc[times[letter[i], h[[j, k]]], -1],
        sc[times[h[[j, k]], letter[i]], q[[i, j]] q[[i, k]]],
        sc[times[letter[j], h[[i, k]]], q[[i, j]]],
        sc[times[h[[i, k]], letter[j]], -q[[j, k]]]]];
      nf = reducer["Reduce"][jpoly];
      polynomials = Join[polynomials, Last /@ nf];
      If[keep, AppendTo[remainders, nf]]], {t, triples}];
    (* H was derived from the original ideal. The following checks the reverse
       containment once H is confluent, so no original parameter branch is lost. *)
    Do[nf = reducer["Reduce"][g]; polynomials = Join[polynomials, Last /@ nf];
      If[keep, AppendTo[compatibility, nf]], {g, data["LiftedOriginalRelations"]}];
    polynomials = DeleteDuplicates[Select[Factor /@ polynomials, # =!= 0 &]];
    out = <|"Backend" -> "SuperLettersLemma3.3", "Parameters" -> data["Parameters"],
      "Ambiguities" -> (<|"Kind" -> "SuperTriple", "Word" -> #|> & /@ triples),
      "Triples" -> triples, "TripleCount" -> Length[triples],
      "CompatibilityCount" -> Length[data["LiftedOriginalRelations"]],
      "CoefficientPolynomials" -> polynomials, "Equations" -> (# == 0 & /@ polynomials),
      "BraidingCondition" -> data["BraidingCondition"],
      "Condition" -> (And @@ (# == 0 & /@ polynomials) && data["BraidingCondition"]),
      "CheckStatistics" -> Join[reducer["Statistics"][], <|"Seconds" -> AbsoluteTime[] - start|>],
      "Meaning" -> "Necessary and sufficient for the ORIGINAL monic G to be a Groebner basis: super-letter triples plus original-relation compatibility, with nonzero q_ij."|>;
    If[keep, AssociateTo[out, {"Remainders" -> remainders, "CompatibilityRemainders" -> compatibility}]];
    out, tag], reducer["Release"][]; Abort[]];
  reducer["Release"][]; result
]];

SuperExpression[p_List, data_Association] := Total[Function[t, t[[2]] Switch[Length[t[[1]]],
  0, 1, 1, data["SuperLetters"][[First[t[[1]]]]],
  _, NonCommutativeMultiply @@ data["SuperLetters"][[t[[1]]]]]] /@ p];

End[];
EndPackage[];

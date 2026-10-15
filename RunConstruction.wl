(* ::Package:: *)

(* ::Title:: *)
(* \:4ece Lyndon \:95ed\:96c6\:6784\:9020 AS \:6b63\:5219\:4ee3\:6570 *)


(* ::Section:: *)
(* 0. \:52a0\:8f7d\:7a0b\:5e8f\:ff1b\:5728 Mathematica \:4e2d\:6253\:5f00\:672c\:6587\:4ef6\:ff0c\:6309\:5757\:8fd0\:884c\:ff0c\:6216\:76f4\:63a5 Get \:672c\:6587\:4ef6\:3002 *)


projectDirectory = DirectoryName[$InputFileName];
If[projectDirectory === "", projectDirectory = NotebookDirectory[]];
Get[FileNameJoin[{projectDirectory, "LyndonAS.wl"}]];



(* ::Section:: *)
(* 1. \:53ef\:4fee\:6539\:7684\:914d\:7f6e\:5757\:3002\:8bcd {2,2,1} \:8868\:793a x2 x2 x1\:ff1bx1 < x2 < ... \:3002 *)


alphabetSize = 2;
letters = Table[Symbol["Global`x" <> ToString[i]], {i, alphabetSize}];
letterDegrees = ConstantArray[1, alphabetSize];

(* \:5f53\:524d\:6587\:7ae0\:7684\:56db\:4e2a PBW \:751f\:6210\:8bcd\:3002\:82e5\:589e\:52a0\:5b57\:6bcd\:ff0c\:8bf7\:540c\:6b65\:4fee\:6539 U\:ff0c\:4f7f\:5b83\:5305\:542b\:5168\:90e8\:5355\:5b57\:6bcd\:5e76\:95ed\:5408\:3002 *)
U = {{1}, {2, 1}, {2}};

(* Automatic \:751f\:6210\:72ec\:7acb\:975e\:96f6\:53c2\:6570 q11,q12,q21,q22\:ff08\:9ed8\:8ba4 Global \:4e0a\:4e0b\:6587\:ff09\:3002
   \:4e5f\:53ef\:8bbe\:4e3a\:7cbe\:786e\:77e9\:9635\:ff0c\:5982 {{1,1},{1,1}}\:3002\:4e0d\:8981\:7528\:673a\:5668\:5c0f\:6570\:3002
   q_ij = 1/p \:4e4b\:7c7b\:6761\:4ef6\:8bf7\:6539\:5199\:6210 q_ij p == 1\:ff0c\:653e\:5728 extraConditions \:4e2d\:3002 *)
braidingMatrix = Automatic;
tailMode = "Kharchenko";
(* \:53ef\:9009 "None"\:ff08\:65e0\:5c3e\:9879\:ff09\:3001"TriangularKharchenko"\:3001"QuasiTriangularKharchenko"\:3002 *)

(* \:5f53\:524d\:4e24\:5b57\:6bcd\:4f8b\:5b50\:81ea\:52a8\:6c42\:89e3\:ff1b\:5927\:578b\:4f8b\:5b50\:53ef\:6539\:6210 False\:ff0c\:5148\:68c0\:67e5\:65b9\:7a0b\:3002 *)
runReduce = True;
reduceTimeLimit = 600;
extraConditions = True;
loadNCAlgebra = True;



(* ::Section:: *)
(* 2. \:9a8c\:8bc1\:95ed\:96c6\:ff0c\:8ba1\:7b97 Phi(U)\:ff0c\:679a\:4e3e f_w \:548c G = {[f_w]_c}\:3002 *)


construction = BuildConstruction[U,
  "AlphabetSize" -> alphabetSize, "Letters" -> letters,
  "LetterDegrees" -> letterDegrees, "BraidingMatrix" -> braidingMatrix,
  "TailMode" -> tailMode];
If[FailureQ[construction], Print[construction]; Abort[]];

Print["U (ordered) = ", construction["U"]];
Print["Phi(U) = ", construction["Phi"]];
Print["q matrix = ", construction["BraidingMatrix"]];
Print["Each row: leading word, admissible tail words, corresponding free coefficients"];
Print[Grid[Prepend[Transpose[{construction["Phi"], construction["TailWords"],
  construction["TailParameters"]}], {"w", "tail words", "coefficients"}], Frame -> All]];

(* \:72ec\:7acb\:6807\:91cf\:53c2\:6570 c_i_j \:5bf9\:5e94 f_w = w + Sum[c_i_j v_i_j]\:3002
   \:53c2\:6570\:53ef\:4ee5\:7b49\:4e8e\:96f6\:ff1b\:6ca1\:6709\:5f3a\:884c\:6392\:9664\:9000\:5316\:5206\:652f\:3002 *)
If[TrueQ[loadNCAlgebra],
  ncExpressions = NCExpressions[construction];
  If[FailureQ[ncExpressions], Print[ncExpressions],
    Print["Kharchenko polynomials f:"]; Print[Column[ncExpressions["F"]]];
    Print["Braided defining relations G:"]; Print[Column[ncExpressions["G"]]];
    Print["PBW generating set:"]; Print[Column[ncExpressions["PBWGenerators"]]];
    Print["Independent bracket agreement: ", ncExpressions["BracketChecks"]]]];



(* ::Section:: *)
(* 3. Diamond Lemma\:ff1a\:5168\:90e8\:4e34\:754c\:91cd\:53e0\:7684\:4f59\:5f0f\:7cfb\:6570\:540c\:65f6\:4e3a\:96f6\:3002 *)


conditionReport = GroebnerConditions[construction];
If[FailureQ[conditionReport], Print[conditionReport]; Abort[]];
Print["Number of critical ambiguities = ", Length[conditionReport["Ambiguities"]]];
Print["Coefficient equations (necessary and sufficient):"];
Print[Column[conditionReport["Equations"]]];
Print["Nonzero braiding constraints: ", conditionReport["BraidingCondition"]];

(* \:7b2c i \:4e2a\:91cd\:53e0\:7684\:8bcd\:3001S-polynomial\:3001\:5b8c\:5168\:7ea6\:5316\:4f59\:5f0f\:ff1a
   conditionReport["Ambiguities"][[i]]
   conditionReport["Compositions"][[i]]
   conditionReport["Remainders"][[i]]
   ToNCExpression[conditionReport["Remainders"][[i]], letters]
*)



(* ::Section:: *)
(* 4. \:7cfb\:6570\:6c42\:89e3\:3002SolveCoefficientConditions \:8fd4\:56de\:6240\:6709\:590d\:6570\:5206\:652f\:ff0c\:800c\:4e0d\:662f\:53ea\:6c42\:4e00\:822c\:4f4d\:7f6e\:3002 *)


If[TrueQ[runReduce],
  solutionReport = SolveCoefficientConditions[conditionReport, extraConditions, reduceTimeLimit];
  Print[solutionReport]];

(* \:4e5f\:53ef\:5206\:9636\:6bb5\:6c42\:89e3\:ff0c\:4f8b\:5982\:5148\:53d6\:666e\:901a flip braiding\:ff0c\:518d\:6c42\:6240\:6709\:5c3e\:9879\:7cfb\:6570\:ff1a
   flipRules = Thread[Flatten[construction["BraidingMatrix"]] ->
                      ConstantArray[1, alphabetSize^2]];
   flipConditions = conditionReport["Condition"] /. flipRules;
   Reduce[flipConditions, Flatten[construction["TailParameters"]], Complexes]

   \:5168\:90e8\:5c3e\:9879\:7f6e\:96f6\:3001\:53ea\:5206\:7c7b\:8fab\:5b50\:53c2\:6570\:ff1a
   zeroTails = Thread[Flatten[construction["TailParameters"]] ->
                      ConstantArray[0, Length[Flatten[construction["TailParameters"]]]]];
   Reduce[conditionReport["Condition"] /. zeroTails,
          Flatten[construction["BraidingMatrix"]], Complexes]
*)



(* ::Section:: *)
(* 5. \:6bcf\:4e2a\:6ee1\:8db3\:6761\:4ef6\:7684\:53c2\:6570\:70b9/\:5206\:652f\:5bf9\:5e94\:7684 PBW \:6570\:636e\:ff1bAS \:7ed3\:8bba\:4f7f\:7528\:6b63\:6587\:5b9a\:7406\:3002 *)


invariants = ConstructionInvariants[construction, t];
Print[invariants];

(* \:4fdd\:5b58\:5168\:90e8\:7cbe\:786e\:4e2d\:95f4\:7ed3\:679c\:ff0c\:53ef\:7528 Get \:6062\:590d\:ff1b\:4e0d\:4f1a\:89e6\:78b0\:8bba\:6587 main.tex\:3002 *)
Put[<|"Construction" -> construction, "GroebnerConditions" -> conditionReport,
  "Invariants" -> invariants|>, FileNameJoin[{projectDirectory, "construction-result.wl"}]];



(* ::Section:: *)
(**)


(* 6. \:6c42\:89e3\:540e\:9009\:53d6\:4e00\:4e2a\:7cbe\:786e\:53c2\:6570\:70b9\:ff0c\:68c0\:67e5\:539f G\:ff0c\:5e76\:8c03\:7528 NCMakeGB \:4ea4\:53c9\:9a8c\:8bc1\:3002
   \:4ee5\:4e0b\:4f5c\:4e3a\:624b\:52a8\:8fd0\:884c\:6a21\:677f\:ff0c\:4e0d\:80fd\:628a\:672a\:8d4b\:503c\:7684\:53c2\:6570\:5f53\:4f5c\:5df2\:9a8c\:8bc1\:3002

   parameterRules = { ... };
   VerifySpecialization[construction, parameterRules]
   VerifyWithNCAlgebra[construction, parameterRules, 20]

   NCMakeGB \:4e0d\:662f\:53c2\:6570\:5206\:7c7b\:5668\:3002\:4e0d\:8981\:76f4\:63a5\:5bf9\:7b26\:53f7 G \:8c03\:7528\:5b83\:540e\:ff0c
   \:628a\:4e00\:822c\:53c2\:6570\:57df\:4e0a\:7684\:8f93\:51fa\:5f53\:4f5c\:5168\:90e8\:53c2\:6570\:5206\:652f\:3002
*)

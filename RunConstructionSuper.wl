(* ::Package:: *)

(* Run this file in a fresh kernel. Configuration is independent of the old runners. *)
projectDirectory = DirectoryName[$InputFileName];
If[projectDirectory === "", projectDirectory = NotebookDirectory[]];
Get[FileNameJoin[{projectDirectory, "LyndonASSuper.wl"}]];



(* ::Section:: *)
(* 1. Configuration: the default example has |U|=6 and three original generators. *)


alphabetSize = 2;
U = {{1}, {2, 1},{2,2,1},{2}};
letterDegrees = ConstantArray[1, alphabetSize];
braidingMatrix = Automatic;
tailMode = "Kharchenko";
extraConditions = True; (* Example: q11 == q22 && q22 == q33 *)
runSaturation = True;
runReduce = True;
buildTimeLimit = 600;
superBuildTimeLimit = 600;
superCheckTimeLimit = 600;
saturationTimeLimit = 600;
reduceTimeLimit = 600;
maxReductions = 1000000;
printSuperRules = True;



(* ::Section:: *)
(* 2. Each stage has its own limit. Failure/timeout is NEVER reported as no solutions. *)


SetAttributes[superStage, HoldRest];
superStage[name_, expression_, seconds_] := Module[{answer},
  answer = TimeConstrained[expression, seconds,
    Failure["TimeLimit", <|"Stage" -> name, "Seconds" -> seconds|>]];
  If[MatchQ[answer, Failure["TimeLimit", _]], AppendTo[superTimedOutStages, name]];
  If[FailureQ[answer], Throw[<|"Status" -> "Incomplete", "Stage" -> name,
    "Failure" -> answer|>, "superRun"]];
  answer
];

superTimedOutStages = {};
superEquationCounts = Missing["NotComputed"];
superRunResult = Catch[
  construction = superStage["Original construction",
    BuildConstruction[U, "AlphabetSize" -> alphabetSize,
      "LetterDegrees" -> letterDegrees, "BraidingMatrix" -> braidingMatrix,
      "TailMode" -> tailMode], buildTimeLimit];
  superConstruction = superStage["Super-letter conversion",
    BuildSuperConstruction[construction, "MaxReductions" -> maxReductions], superBuildTimeLimit];
  If[TrueQ[printSuperRules], Print["Exchange rules (left side minus right side = 0):"];
    Print[Column[Function[r, SuperExpression[
      Join[{{r["Head"], 1}}, ({First[#], -Last[#]} & /@ r["Tail"])], superConstruction]] /@
      superConstruction["SuperRules"]]]];
  (* Save a restart point BEFORE the coefficient calculations. *)
  Put[superConstruction, FileNameJoin[{projectDirectory, "super-construction-checkpoint.wl"}]];
  rawSuperReport = superStage["Triple and original-relation checks",
    SuperGroebnerConditions[superConstruction, "MaxReductions" -> maxReductions], superCheckTimeLimit];
  Put[rawSuperReport, FileNameJoin[{projectDirectory, "super-conditions-checkpoint.wl"}]];

  (* ::Section:: *)
  (* 3. Existing coefficient saturation and exact parameter classification. *)
  conditionReport = rawSuperReport;
  If[TrueQ[runSaturation],
    conditionReport = SaturateCoefficientConditions[rawSuperReport,
      construction["BraidingMatrix"], extraConditions, saturationTimeLimit];
    If[FailureQ[conditionReport], Throw[<|"Status" -> "Incomplete", "Stage" -> "Saturation",
      "Failure" -> conditionReport|>, "superRun"]];
    If[MatchQ[conditionReport["SaturationStatus"], Missing["TimeLimit"]],
      AppendTo[superTimedOutStages, "Saturation"]]];
  superEquationCounts = {Length[rawSuperReport["CoefficientPolynomials"]],
    Length[conditionReport["CoefficientPolynomials"]]};
  solutionReport = If[TrueQ[runReduce],
    SolveCoefficientConditions[conditionReport, extraConditions, reduceTimeLimit], Missing["NotRequested"]];
  If[AssociationQ[solutionReport] && MatchQ[solutionReport["Result"], Missing["TimeLimit"]],
    AppendTo[superTimedOutStages, "Reduce"]];
  <|"Status" -> If[AssociationQ[solutionReport] && TrueQ[solutionReport["Solved"]],
      "Solved", "ConditionsComputed"],
    "Construction" -> construction, "SuperConstruction" -> superConstruction,
    "GroebnerConditions" -> conditionReport, "Solution" -> solutionReport,
    "Invariants" -> ConstructionInvariants[construction, t]|>, "superRun"];
superRunSummary = <|
  "Completed" -> (superRunResult["Status"] === "Solved" ||
    (superRunResult["Status"] === "ConditionsComputed" && !TrueQ[runReduce])),
  "TimedOut" -> (superTimedOutStages =!= {}),
  "TimedOutStages" -> superTimedOutStages|>;
If[superRunResult["Status"] === "Incomplete",
  AssociateTo[superRunSummary, {"FailedStage" -> superRunResult["Stage"],
    "FailureReason" -> First[superRunResult["Failure"]]}]];
AssociateTo[superRunResult, "RunSummary" -> superRunSummary];
Put[superRunResult, FileNameJoin[{projectDirectory, "construction-result-super.wl"}]];
Print["Equation counts (raw super, after saturation): ", superEquationCounts];
Print["Solution: ", With[{s = Lookup[superRunResult, "Solution", Missing["NotComputed"]]},
  If[AssociationQ[s], s["Result"], s]]];
Print["Calculation status: ", superRunSummary];




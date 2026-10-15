(* Enumerate every closed set of the requested size on an ordered alphabet.
   No word-length cutoff: every extension is chosen from Phi(U). *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "LyndonAS.wl"}]];

EnumerateClosedSets[n_Integer?Positive, size_Integer?Positive] := Module[{sets, next},
  If[size < n, Return[{}]];
  sets = {List /@ Range[n]};
  Do[
    next = Flatten[Table[
      Sort[Append[u, #]] & /@ PhiClosedSet[u, n], {u, sets}], 1];
    sets = DeleteDuplicates[next],
    {size - n}];
  Sort[Sort[#, LyndonLess] & /@ sets]
];

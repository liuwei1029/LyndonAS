# LyndonAS

Construct multihomogeneous families of algebras from Lyndon closed sets in Wolfram Language / Mathematica, compute PBW / Gröbner conditions, and solve for the parameters.

The package provides both an algorithm on the original alphabet and a superletter algorithm based on Zhou–Lu's Lemma 3.3. For a closed set with six elements, the superletter algorithm checks 20 triple ambiguities and additionally verifies compatibility with the original defining relations to preserve the original parameter family.

## Quick start

Open `RunConstructionSuper.wl` in Mathematica, edit the configuration at the top, and run it. Alternatively, evaluate the following in a fresh kernel:

```wolfram
Get["/path/to/LyndonAS/RunConstructionSuper.wl"]
```

Replace the path with the location of your local repository. The main configuration options are:

```wolfram
alphabetSize = 3;
U = {{1}, {2, 1}, {2}, {3, 1}, {3, 2}, {3}};
letterDegrees = ConstantArray[1, alphabetSize];
braidingMatrix = Automatic;
tailMode = "Kharchenko";
extraConditions = True;
```

The entry script in the repository contains the current working configuration; the configuration above is an optional six-element example. When changing `alphabetSize`, also update `U` and `letterDegrees`.

Use `extraConditions` to impose additional relations such as `q11 == q22`. Setting the tail mode to `"None"` changes the parameter family under consideration; it is not merely a performance option.

The entry script prints only the commutation relations, the number of equations, the solution, and the completion or timeout status. Full results and checkpoints are saved locally and excluded from version control. `Solution: False` means that there is no solution; timeouts are reported separately.

## Files

| File | Purpose |
|---|---|
| `LyndonAS.wl` | Lyndon words, reduction on the original alphabet, saturation of coefficient ideals, and parameter solving |
| `LyndonASSuper.wl` | Cached reductions, superletter commutation rules, and triple-ambiguity conditions |
| `RunConstructionSuper.wl` | Recommended entry script |
| `RunConstructionSaturated.wl` | Original algorithm with saturation by nonzero parameters |
| `RunConstruction.wl` | Original entry script |
| `ArbitraryGenerators.wl` | Example families with an arbitrary number of generators |
| `EnumerateClosedSets.wl` | Enumeration of finite Lyndon closed sets |
| `Tests.wlt`, `SaturationTests.wlt`, `SuperTests.wlt` | Regression tests and cross-checks |

Detailed documentation (in Chinese): [Superletter algorithm](SUPER-ALGORITHM.zh.md), [Original implementation](README.zh.md), [Saturation](SATURATION.zh.md), [Examples with arbitrary numbers of generators](ARBITRARY-GENERATORS.zh.md), and [Six-element closed sets on two letters](closed-sets-n2-size6.md). Some absolute paths in these documents are examples from the development machine; replace them with your local paths.

## Environment and validation

Validated in Mathematica 14.2. The superletter entry script does not require NCAlgebra; the independent cross-checks in the original tests use NCAlgebra 6.

```wolfram
dir = "/path/to/LyndonAS";
TestReport[FileNameJoin[{dir, #}] & /@
  {"Tests.wlt", "SaturationTests.wlt", "SuperTests.wlt"}]
```

The latest reported validation passed 40 tests, including cross-checks at 30 exact parameter points covering all 15 six-element closed sets on two letters. Performance results are recorded in `super-benchmark-results.wl`. Timed-out cases are explicitly marked as `Missing["SaturationTimeLimit"]` and do not count as successful validation.

Generating coefficient conditions, computing commutative Gröbner bases for the coefficient equations, and running `Reduce` can each be time-consuming. Conclusions about dimensions and AS regularity are conditional on the relevant mathematical hypotheses and Gröbner conditions being satisfied.

## References

- G.-S. Zhou, D.-M. Lu, [Lyndon words for Artin-Schelter regular algebras](https://arxiv.org/abs/1403.0385), Lemma 3.3.
- T. Gateva-Ivanova, [Algebras defined by Lyndon words and Artin-Schelter regularity](https://arxiv.org/abs/1905.11281).

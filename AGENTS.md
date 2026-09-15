# Zero-Dependency Codex Instructions v1.0

These repository instructions define the fixed rules for Codex to perform Zero-Dependency conversion of JavaScript / TypeScript software.

Run Codex from the target repository root containing this `AGENTS.md` and `run-config.json`.

---

## 1. Role and Goal

You are an Agent that converts the target software's in-scope external production dependencies to Zero-Dependency local implementations.

Your goal is:

> Preserve behavior required by the target software while replacing in-scope external third-party production dependencies with local implementations containing only the functionality and processing actually required by the target software.

Do not aim to reimplement complete third-party packages.

For direct, optional, and transitive dependencies alike, implement only the functionality and processing necessary for behavior required by the target software.

Proceed autonomously through analysis, specification, implementation, integration, validation, and justified re-analysis or repair.

Do not evaluate the research effectiveness of the method or draw research conclusions.

---

## 2. Input and Scope

### 2.1 `run-config.json`

Use `run-config.json` as the sole source of run-specific execution parameters.

It must contain:

```json
{
  "schema_version": "1.0",
  "run_id": "<RUN_ID>",
  "repository": "<REPOSITORY>",
  "revision": "<REVISION>",
  "generated_package_root": "<RELATIVE_PATH>"
}
```

Field meanings:

- `schema_version`: schema version of `run-config.json`.
- `run_id`: unique identifier for this run and its artifacts.
- `repository`: target Git repository.
- `revision`: target Git revision.
- `generated_package_root`: repository-relative root directory for generated Zero-Dependency production code.

At execution start, verify that:

- `run-config.json` exists and parses as valid JSON,
- all required fields exist and have valid types,
- required strings are non-empty,
- `schema_version` is supported,
- the current repository matches `repository`,
- the checked-out revision matches `revision`,
- `generated_package_root` is a valid repository-relative path.

Do not infer or fabricate missing required values.

If input is invalid, do not modify production code. Record the reason and stop.

### 2.2 Production Dependency Scope

The following are in scope for Zero-Dependency conversion:

- packages declared in the target software's `dependencies`,
- packages declared in the target software's `optionalDependencies`,
- in-scope runtime transitive dependencies reachable from those packages.

The following are out of scope:

- packages that are present only because they are declared in `peerDependencies`,
- packages used only through `devDependencies`,
- dependencies used only for development, testing, linting, formatting, documentation, or other non-production tooling and not part of the in-scope production dependency graph.

`optionalDependencies` are in scope.

`peerDependencies` are out of scope as peer dependencies. Do not select a package for conversion solely because it appears in `peerDependencies`.

If the same package is also reachable through an in-scope `dependencies` or `optionalDependencies` path, treat that path as in scope.

### 2.3 Direct and Transitive Dependencies

A direct production dependency is an in-scope package declared directly in the Baseline target software's `dependencies` or `optionalDependencies`.

A transitive production dependency is an in-scope runtime package reached through a direct dependency or another in-scope transitive dependency.

Direct and transitive classification defines dependency position and analysis order. It does not define implementation breadth.

For every in-scope dependency, implement only required functionality and processing.

---

## 3. Invariants

The following rules apply throughout the run.

### 3.1 Required Functionality Only

This is the central rule:

> Locally implement only the functionality and processing necessary to realize behavior required by the target software.

Do not implement a package merely because it appears in the dependency graph.

Do not reproduce a package's complete API or complete feature set unless all of it is demonstrably required.

Do not retain functionality, processing, or code whose necessity cannot be explained from the target software's usage context.

### 3.2 No Substitute Third-Party Production Dependency

Do not replace an in-scope dependency with another newly added third-party production dependency.

You may use:

- ECMAScript standard functionality,
- Node.js standard APIs,
- standard Web APIs available in the fixed target runtime,
- existing local target-software code,
- generated local code.

You may use development tools for analysis, implementation, and validation, but the converted production runtime must not gain a new external runtime, tool, service, or third-party production dependency.

### 3.3 Original Source Use

You may inspect original third-party package source code.

When necessary to realize Required Behavior, you may reflect original processing or code into the local implementation.

Code similarity is not itself prohibited.

The criterion is whether the retained functionality, processing, or code is necessary for behavior required by the target software.

### 3.4 Existing Tests

Do not modify existing tests for the purpose of making Zero-Dependency conversion pass.

This includes, for example:

- deleting or skipping tests,
- deleting assertions,
- changing expected values,
- weakening validation conditions,
- configuring failures to be ignored,
- deleting test scripts,
- bypassing existing validation commands.

Additional tests and behavior probes may be created for analysis or diagnosis, but they must remain distinct from existing tests and must not replace the formal SUCCESS conditions.

### 3.5 Minimal Change

Do not make changes whose necessity for Zero-Dependency conversion or its validation cannot be explained.

Avoid unrelated refactoring, formatting-only changes, architecture redesign, unrelated dependency updates, and unrelated configuration or source changes.

### 3.6 Generated Package Layout

All new Zero-Dependency production code must be created under:

```text
<generated_package_root>/
```

For every third-party package that requires local implementation, create a dedicated package-name directory.

Unscoped package:

```text
<generated_package_root>/
└── package-name/
```

Scoped package:

```text
<generated_package_root>/
└── @scope/
    └── package-name/
```

A package directory may contain multiple files and subdirectories when necessary.

All generated production code associated with that package must remain under that package's dedicated directory.

Do not create a package directory merely because the package exists in the dependency graph.

Existing target source files, manifests, lockfiles, and configuration files may be modified outside `generated_package_root` when necessary for integration and dependency removal.

### 3.7 Uncertainty

Do not implement behavior based only on unsupported assumptions when relevant evidence can reasonably be obtained.

Use source inspection, static analysis, behavior probing, or other justified analysis as needed.

If significant uncertainty remains and a reasonable judgment cannot be made, record the uncertainty and stop instead of forcing SUCCESS.

---

## 4. Dependency Processing Rules

### 4.1 Fixed Direct Dependency Order

The direct dependency roots for the run are fixed from the Baseline target software before production modification begins.

Take the union of exact package-name strings declared in:

- `dependencies`,
- `optionalDependencies`.

If the same package name appears in both, treat it as one direct root.

Sort the resulting package names in ascending lexicographic order by the exact package-name string.

Record the complete order before modifying production code and keep it fixed for the entire run.

Do not reorder roots based on implementation difficulty, dependency depth, package size, expected effort, or Agent preference.

Do not recompute or reorder the root list after the manifest changes.

### 4.2 Top-Down Analysis

For the current direct dependency:

1. Identify how the target software uses it.
2. Identify the behavior actually required from it.
3. Trace only the package-internal processing necessary to realize that behavior.
4. When required processing invokes another in-scope package, determine whether behavior from that dependency is necessary.
5. If necessary, recursively analyze that dependency in the same way.
6. If not necessary, stop traversal along that dependency path.

Example:

```text
Application
└── A
    └── B
        └── C
```

If A's required behavior needs B, but B's required behavior does not need C, do not locally implement C.

### 4.3 Bottom-Up Implementation

After required dependency behavior has been identified, implement required packages from the deepest required dependency back toward the direct dependency.

If A, B, and C are all required:

```text
C
↓
B
↓
A
```

If C is not required:

```text
B
↓
A
```

Generated packages may depend on other generated packages.

### 4.4 Shared Transitive Dependencies

The same transitive package may be required by multiple direct dependency branches.

Example:

```text
Application
├── A
│   └── B
└── D
    └── B
```

Do not assume that local B behavior generated while processing A automatically satisfies D.

When processing D, independently analyze what behavior D requires from B.

For the same package name and the same resolved version:

- if the existing local implementation already satisfies the newly identified Required Behavior, reuse it unchanged,
- if additional behavior is required, add only the newly required functionality and processing,
- the final local implementation must contain only the union of behavior actually required by all processed consumers,
- do not preemptively implement hypothetical or future functionality.

The fact that a package was already analyzed or implemented in an earlier branch does not remove the requirement to analyze its necessity and Required Behavior in a later branch.

### 4.5 Multiple Resolved Versions

Do not assume that different resolved versions of the same package are behaviorally interchangeable.

Analyze each resolved version in the usage context of the branch that reaches it.

If multiple resolved versions of the same package exist in the Baseline in-scope dependency graph and local implementation is required for those versions, separate them below the package directory.

Example:

```text
<generated_package_root>/
└── package-name/
    ├── 1.0.0/
    └── 2.0.0/
```

Scoped package:

```text
<generated_package_root>/
└── @scope/
    └── package-name/
        ├── 1.0.0/
        └── 2.0.0/
```

Treat each resolved version as a distinct local implementation unit.

Do not merge behavior across versions merely because the package name is the same.

If only one resolved version of a package exists in the Baseline in-scope graph, do not create an unnecessary version subdirectory. Place generated files directly under the package's dedicated directory.

---

## 5. Execution Workflow

### Phase 0: Setup, Baseline, and Inventory

Before production modification:

1. Validate `run-config.json`.
2. Record the target repository, configured revision, actual commit, target software name/version, Node.js version, package manager and version, OS, architecture, module system, TypeScript usage, lockfile, and `generated_package_root`.
3. Establish the Baseline by running, where applicable:
   - dependency installation,
   - build,
   - runtime or smoke execution,
   - all existing tests.
4. Identify the Baseline in-scope production dependency graph, including:
   - direct `dependencies`,
   - direct `optionalDependencies`,
   - in-scope runtime transitive dependencies,
   - resolved versions,
   - dependency paths.
5. Separately identify out-of-scope peer-only and development-only dependencies.
6. Create and record the fixed direct dependency processing order defined in Section 4.1.

If a pre-existing Baseline failure prevents a meaningful before/after comparison, do not begin production conversion.

Do not repair a pre-existing Baseline defect as part of Zero-Dependency conversion.

### Phase 1: Analyze the Current Direct Dependency Branch

Process direct dependency roots in the fixed Baseline order.

For the current direct dependency, determine the Required Behavior from the target software's actual usage context.

Inspect, when relevant:

- import / require locations,
- used APIs / functions / methods,
- call sites,
- arguments and options,
- return values and how they are used,
- errors and exceptions,
- surrounding control flow,
- asynchronous behavior,
- callbacks and events,
- state and side effects,
- initialization,
- environment variables and configuration,
- platform-dependent behavior,
- dynamic calls and dynamic import / require.

Do not merely list API names. Be able to explain:

> What behavior does the target software require from this dependency?

Then recursively analyze only the package functionality and transitive dependency behavior necessary to realize that Required Behavior, following Section 4.2.

### Phase 2: Replacement Specification

Before modifying Zero-Dependency production implementation for the current direct dependency branch, record at least:

- Required Behavior,
- Not Required Behavior,
- packages requiring local implementation,
- packages determined unnecessary and the reason,
- required functionality for each package,
- generated directory for each package,
- planned generated files and their roles,
- existing files expected to require modification,
- required relationships between generated packages,
- integration method,
- external dependency removal method,
- known risks and uncertainty.

Do not begin production implementation until this specification is complete.

If implementation later requires a materially different approach or undeclared generated production file, update the specification before making that change.

### Phase 3: Bottom-Up Implementation and Integration

Implement required packages bottom-up according to Section 4.3.

Follow the generated package layout and multiple-version rules.

When a shared package implementation already exists, follow Section 4.4: reuse it when sufficient or extend it only by newly required behavior.

Then modify, as necessary:

- target source imports / requires,
- generated-package references,
- package manifest,
- lockfile,
- relevant configuration.

Ensure the target software uses the generated direct-package implementation instead of the external direct dependency.

Remove in-scope external dependency relationships that are no longer required by the converted branch.

Do not remove out-of-scope peer or development dependencies merely to reduce dependency count.

Do not perform unrelated dependency updates.

### Phase 4: Intermediate Validation

After each direct dependency branch is integrated, run, where applicable:

- dependency installation,
- build,
- runtime / smoke execution,
- all existing tests,
- current in-scope production dependency graph inspection.

Do not proceed to the next direct root until validation succeeds or execution stops because of unresolved failure or uncertainty.

If a later Baseline direct root no longer has an in-scope external dependency relationship because an earlier conversion eliminated it, analyze and record why it is no longer required and skip it.

Do not generate a local implementation merely because the package was present in the original Baseline root list.

Repeat Phases 1 through 4 until every Baseline direct root has been processed or explicitly skipped with evidence.

---

## 6. Validation and Repair

### 6.1 Repair

If Intermediate Validation or Final Validation fails, identify the cause and return to the responsible stage.

Default mapping:

- missed target usage → Phase 1,
- incomplete recursive dependency analysis → Phase 1,
- incorrect replacement specification → Phase 2,
- local implementation defect → Phase 3,
- integration or dependency-removal defect → Phase 3.

When returning to an earlier stage, update the relevant artifacts and record what changed.

Do not repeat the same failed modification without new evidence or a revised hypothesis.

If reasonable re-analysis cannot resolve the problem, finish as failure or uncertainty instead of forcing SUCCESS.

### 6.2 Final Validation

After all Baseline direct roots have been processed, validate the complete target software.

Confirm at minimum:

1. no in-scope external third-party production dependency remains through `dependencies`, `optionalDependencies`, or their in-scope runtime transitive paths,
2. out-of-scope `peerDependencies` and `devDependencies` are not incorrectly treated as failures merely because they remain,
3. no new third-party production dependency was added as a substitute,
4. all generated Zero-Dependency production code is under `generated_package_root`,
5. every third-party package with generated production code has its own dedicated package directory,
6. no package directory was created when no local implementation was required,
7. the build succeeds when applicable,
8. runtime / smoke validation succeeds when applicable,
9. all existing tests pass.

Record N/A only when a validation category genuinely does not exist or is not applicable, and record the reason.

---

## 7. Artifacts and Reporting

Keep analysis and experiment records separate from generated production implementation.

Use:

```text
.zero-dependency/runs/<run-id>/
```

Create at minimum:

```text
.zero-dependency/
└── runs/
    └── <run-id>/
        ├── baseline.md
        ├── dependency-inventory.md
        ├── direct-dependencies/
        │   └── <direct-package-name>/
        │       ├── analysis.md
        │       ├── specification.md
        │       └── validation.md
        ├── repair-log.md
        └── execution-report.md
```

Create or update artifacts at the corresponding execution stage rather than generating all evidence only at the end.

### `baseline.md`

Record the Baseline environment and validation results.

### `dependency-inventory.md`

Record at least:

- initial in-scope direct dependencies,
- direct `optionalDependencies`,
- fixed direct-dependency processing order,
- in-scope transitive dependencies,
- resolved versions,
- dependency paths or graph,
- out-of-scope peer dependencies,
- out-of-scope development-only dependencies,
- final dependency state.

### Per-direct-dependency `analysis.md`

Record at least:

- Required Behavior,
- relevant target usage,
- recursive dependency analysis,
- required transitive packages,
- excluded packages and exclusion reasons,
- additional Required Behavior identified for shared transitive packages.

### `specification.md`

Record the Phase 2 replacement specification.

### `validation.md`

Record branch-level changes, eliminated dependency paths, and Intermediate Validation results.

### `repair-log.md`

Record validation failures, cause hypotheses, stages revisited, changes made, and revalidation results.

### `execution-report.md`

At execution end, summarize at least:

- execution configuration,
- target and environment,
- Baseline,
- initial dependency graph,
- fixed direct-dependency processing order,
- result for each direct dependency branch,
- generated packages and their Required Functionality,
- final union of Required Behavior for shared package/version implementations,
- handling of multiple resolved versions,
- eliminated dependency paths,
- repair, uncertainty, and Human Intervention,
- final dependency graph,
- created, modified, and deleted files,
- final result.

If Human Intervention occurs, record the intervention point, reason, information or instruction provided, and action taken afterward.

---

## 8. Final Status

The final result must be one of:

- `SUCCESS`
- `FAILED`
- `STOPPED_DUE_TO_UNCERTAINTY`

Report `SUCCESS` only if all of the following are satisfied:

1. all in-scope external production dependency relationships have been removed,
2. no new third-party production dependency was added as a substitute,
3. behavior required by the target software is preserved,
4. all applicable build, runtime, and existing-test validation succeeds,
5. generated production code follows the package-directory rules defined in this file.

Do not intentionally retain functionality beyond Required Behavior.

Do not hide significant uncertainty and report SUCCESS.

For `FAILED` or `STOPPED_DUE_TO_UNCERTAINTY`, record the reason in `execution-report.md`.

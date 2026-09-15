# Zero-Dependency Codex Instructions v1.2

These repository instructions define the Zero-Dependency conversion procedure for Codex. Run Codex from the project root containing this `AGENTS.md` and `run-config.json` so these instructions and the structured execution input are in scope.

## 1. Agent Role

You are an Agent that performs Zero-Dependency conversion of external production dependencies in JavaScript / TypeScript software.

Your role is to analyze the actual usage context of the specified target dependency in the target software, identify the behavior required by the target software, and reconstruct only that required behavior as the minimum necessary local implementation.

Then integrate the local implementation into the target software and remove the specified external production dependency.

After dependency removal, validate the result using the target software's build, runtime execution, and existing tests.

If validation fails, analyze the cause and, when necessary, re-analyze or revise the usage context, relevant dependency internals, replacement specification, local implementation, or integration method, then validate again.

Your responsibilities are:

1. Acquire and validate execution input.
2. Analyze the usage context of the specified dependency in the target software.
3. Analyze the dependency internals required to implement the used functionality.
4. Specify a local implementation that reproduces only the required behavior.
5. Design and generate the local implementation.
6. Integrate the local implementation into the target software.
7. Remove the specified external production dependency.
8. Verify dependency removal.
9. Validate behavior using build, runtime execution, and existing tests.
10. Analyze failures, re-analyze, repair, and revalidate when needed.
11. Record analyses, judgments, modifications, and validation results.

You do not select the target software or the dependency to convert. Those are specified by execution input.

Do not independently Zero-Dependency-convert any dependency other than the specified target dependency.

You do not evaluate the research effectiveness of this method or draw research conclusions. Your role is to perform the Zero-Dependency conversion and objectively record its process and results.

After execution begins, proceed autonomously through analysis, specification, implementation, integration, validation, re-analysis, and repair without requesting step-by-step human decisions in normal cases.

If sufficient information cannot be obtained and an appropriate judgment or implementation cannot be made reasonably, do not continue based only on speculation. Record the uncertainty and its cause and stop.

---

## 2. Execution Input

### 2.1 Input Source

Do not infer or obtain run-specific target information from the initial user message. Use `run-config.json` as the sole source of run-specific execution parameters.

At the start of execution, use the following file located at the project root that contains this `AGENTS.md` as the structured execution input:

`run-config.json`

Read `run-config.json` before performing Zero-Dependency analysis or production-source modification.

`run-config.json` specifies the target and execution limits for this run. It does not override the behavioral rules, analysis procedure, prohibitions, or SUCCESS criteria defined in this `AGENTS.md`.

### 2.2 Required Input Fields

`run-config.json` must contain all of the following fields:

- `schema_version`
- `run_id`
- `repository`
- `revision`
- `target_dependency`
- `max_repair_iterations`

Expected structure:

```json
{
  "schema_version": "1.0",
  "run_id": "<RUN_ID>",
  "repository": "<TARGET_REPOSITORY>",
  "revision": "<TARGET_REVISION>",
  "target_dependency": "<TARGET_DEPENDENCY>",
  "max_repair_iterations": 5
}
```

Field meanings:

- `schema_version`: version of the `run-config.json` schema, not the model, Codex version, or `AGENTS.md` instruction version.
- `run_id`: unique identifier for this single execution and its artifacts.
- `repository`: repository containing the target software.
- `revision`: tag, release version, branch revision, or commit hash to use.
- `target_dependency`: third-party npm package to Zero-Dependency-convert in this run.
- `max_repair_iterations`: maximum number of repair iterations allowed in Phase 9. Must be an integer greater than or equal to 0.

### 2.3 Input Validation

At execution start, confirm all of the following:

1. `run-config.json` exists.
2. It parses as valid JSON.
3. All required fields exist.
4. All required fields have valid types.
5. Required string values are non-empty.
6. `schema_version` is supported.
7. `run_id` identifies this run.
8. `repository` identifies the target repository.
9. `revision` identifies the target revision.
10. `target_dependency` identifies the target npm package.
11. `max_repair_iterations` is an integer greater than or equal to 0.

Do not infer or fabricate missing required values.

If the file is missing, invalid, uses an unsupported schema, omits a required field, or contains invalid values, do not begin Zero-Dependency conversion. Stop with an input error and record the reason.

### 2.4 Supported Schema

These rules support:

`schema_version: "1.0"`

Do not assume compatibility with another schema version. Stop and record an unsupported-schema error.

### 2.5 Execution Input Rules

Do not independently change values from `run-config.json`, including:

- schema version
- run ID
- target repository
- target revision
- target dependency
- maximum repair iterations

Do not choose an easier dependency instead of `target_dependency`.

Determine the resolved version of the target dependency from the target repository's actual manifest, lockfile, and dependency tree in Phase 0. Do not infer it from `run-config.json`.

Detect and record the actual execution environment in Phase 0.

---

## 3. Zero-Dependency Definition

For this task, Zero-Dependency conversion means removing the specified third-party npm package as a production dependency and reconstructing only the functionality from that package that the target software actually requires as local code inside the target software.

The target of Zero-Dependency conversion is external dependency on a third-party npm package.

Dependencies between local functions, classes, or modules inside the new local implementation do not need to be removed.

Allowed conceptual structure:

Application
→ Local Module
→ Local Helper Function

Replacing the specified dependency with another third-party npm package is not Zero-Dependency conversion.

---

## 4. Core Principles

Do not aim to reimplement the entire target package.

Always follow this principle:

> Start from functionality actually used by the target software, and analyze and locally implement only the scope required to realize that functionality.

You do not need to reproduce all APIs, options, or internal features exposed by the original package.

Only behavior confirmed as required in the target software's usage context should be included in the implementation scope.

All of the following are mandatory simultaneously:

- preserve behavior required by the target software,
- remove the specified external dependency,
- add no new third-party production dependency as a substitute.

Do not sacrifice one of these requirements to satisfy the others and report SUCCESS.

---

## 5. Allowed Implementation

You may use:

- ECMAScript standard functionality
- JavaScript / TypeScript
- Node.js standard APIs
- standard Web APIs available in the target execution environment
- new local modules inside the target repository
- existing local code in the target software
- necessary import / require changes
- necessary package configuration changes
- minimum existing-code changes required for Zero-Dependency conversion

The local implementation may use multiple files, functions, classes, or local modules.

Internal dependencies between these local implementation elements are allowed.

---

## 6. Prohibitions

### 6.1 No New Third-Party Production Dependency

Do not replace the specified dependency by adding another third-party npm package.

### 6.2 No Retention Beyond the Required Scope

You may inspect the original package source code to understand required behavior and the internal processing necessary to realize it.

You may reflect original processing or code into the local implementation when necessary. Identical or similar code is not prohibited merely because it resembles the original.

However, every function, behavior, or code region retained in the local implementation must have an explainable necessity in the target software's usage context.

Do not retain the entire package or functionality/code beyond the required scope, including functionality the target software does not use or processing unnecessary to realize the required behavior.

The criterion is not code similarity. The criterion is:

> Can the necessity of this functionality, processing, or code be explained as required to realize behavior needed by the target software?

### 6.3 No New Production Runtime External Dependency

You may use available development tools, commands, libraries, and analysis techniques for analysis, conversion, and validation, including:

- source search
- dependency analysis
- AST analysis
- static analysis
- version control
- diff inspection
- test execution
- build execution
- runtime checks
- behavior probing

However, the Zero-Dependency result must not introduce a new production-runtime dependency on an external runtime, external command, system tool, external service, or other third-party production component.

### 6.4 Do Not Modify Existing Tests to Force Success

Do not modify existing tests for the purpose of making Zero-Dependency conversion pass.

Prohibited actions include:

- deleting test cases
- skipping tests
- deleting assertions
- changing expected values
- weakening test conditions
- configuring failures to be ignored
- deleting test scripts
- bypassing validation commands

If existing tests fail, treat the failure as evidence of a problem in usage analysis, relevant implementation analysis, replacement specification, local implementation, or integration.

### 6.5 No Unjustified Changes

Do not make changes whose necessity for the specified Zero-Dependency conversion or its validation cannot be explained.

Avoid in particular:

- unrelated refactoring
- formatting-only changes
- naming cleanup
- architecture redesign
- unrelated dependency updates
- unrelated configuration changes
- unrelated source modifications

For necessary changes, record why they are required for Zero-Dependency conversion or validation.

Keep the modification scope as localized as reasonably possible.

---

## 7. Work Phases

Execute the following phases in order unless Phase 9 explicitly returns execution to an earlier phase.

Phases 0 through 4 are analysis/specification phases.

Do not modify the target software's production implementation for Zero-Dependency purposes until Phase 4 is complete.

Temporary scripts, behavior probes, and additional diagnostic tests may be created for analysis, but existing tests must not be modified.

### Phase 0: Input and Baseline Identification

#### Purpose

Uniquely identify the target, starting state, and execution environment for this run.

#### Actions

Read from `run-config.json`:

- schema version
- run ID
- target repository
- target revision
- target dependency
- maximum repair iterations

If the target repository is not already available in the current experiment workspace, obtain it using the specified repository value. Use a dedicated target working directory under `workspace/` and do not overwrite unrelated existing content.

Confirm that the repository and checked-out revision match `run-config.json`.

Record at least:

- target software
- target version
- commit hash
- target dependency
- resolved target dependency version
- Node.js version
- npm version
- OS
- architecture
- package manager
- module system
- whether TypeScript is used
- whether a lockfile exists
- maximum repair iterations

Confirm that the specified dependency exists as a production dependency relevant to the target software.

If a lockfile exists, do not update dependency versions unnecessarily during baseline identification.

#### Completion Condition

The following must be uniquely identified:

- target software
- target revision
- target dependency
- resolved dependency version
- execution environment
- repair iteration limit

### Phase 1: Baseline Validation

#### Purpose

Confirm that the original target software is in a valid, comparable state before Zero-Dependency conversion.

#### Actions

Run, where applicable to the project:

1. dependency installation
2. build
3. runtime execution
4. existing tests

If the project has no build step, record build as N/A.

If another validation category genuinely does not exist for the project, record it as N/A with the reason.

#### Baseline Failure

If baseline failure prevents a meaningful before/after comparison, do not begin Zero-Dependency conversion.

Do not repair a pre-existing baseline failure as part of the Zero-Dependency conversion.

Reasonable retries for transient network or installation failures are allowed.

If a valid baseline still cannot be established, record the reason and stop.

### Phase 2: Usage Context Analysis

#### Purpose

Determine what functionality and behavior the target software actually requires from the specified dependency.

Analyze primarily from the target software side.

At minimum inspect, when relevant:

- import / require locations
- imported exports
- used APIs / functions / methods
- call sites
- arguments
- argument values or value ranges
- options
- return values
- how return values are used
- surrounding control flow
- error handling
- asynchronous behavior
- callbacks
- events
- state
- side effects
- module initialization
- environment variables
- configuration
- platform-dependent behavior
- dynamic property access
- dynamic import / require

Do not merely list API names.

For each relevant usage, be able to explain:

> What behavior does the target software require from this dependency?

### Phase 3: Relevant Implementation Analysis

#### Purpose

Determine which internal parts of the original dependency are required to realize the behavior identified in Phase 2.

Do not aim to understand or reproduce the entire package.

Starting from used APIs and required behavior, transitively inspect relevant implementation elements as necessary, including:

- internal function calls
- constants
- local variables
- module state
- object state
- data dependencies
- control dependencies
- internal modules
- relevant third-party dependency behavior
- initialization logic
- fallback behavior
- error paths
- asynchronous paths
- callback / event paths
- platform-specific paths
- dynamic calls
- dynamic import / require
- environment-dependent behavior

You may directly inspect original dependency source code.

If source inspection is insufficient, behavior probing is allowed.

For behavior probing, record:

- command or execution performed
- input
- observed result
- purpose of the probe

### Phase 4: Replacement Specification

#### Purpose

Define the specification that the local implementation must satisfy before production code is changed.

Define at least:

#### Required Behavior

- accepted inputs
- relevant arguments
- relevant options
- return values
- exceptions / errors
- asynchronous behavior
- relevant side effects
- relevant state transitions
- relevant platform-dependent behavior

#### Not Required Behavior

Identify functionality or behavior present in the original package but not required in the target software's usage context and therefore excluded from the local implementation.

#### Implementation Strategy

Record:

- ECMAScript features to use
- Node.js standard APIs to use
- existing local code to reuse
- local modules to create
- production file paths to create
- role of each production file
- reason for each placement
- existing files to modify
- dependency removal method

#### Risks / Uncertainties

Record:

- unresolved issues
- dynamic behavior concerns
- environment-dependent behavior concerns
- behaviors that require particular attention during validation

Do not modify production implementation for Zero-Dependency purposes until this phase is complete.

### Phase 5: Local Implementation

Generate the minimum necessary local implementation that satisfies the Phase 4 Replacement Specification.

It must:

- satisfy Required Behavior
- avoid unnecessarily implementing Not Required Behavior
- add no new third-party production dependency
- run in the detected target environment
- maintain the interface needed by the target software
- avoid retaining original package functionality beyond the required scope

If a production file not declared in Phase 4 must be created or modified, update the Replacement Specification first and record the reason.

### Phase 6: Integration and Dependency Removal

Change the target software to use the local implementation instead of the external dependency.

Modify as needed:

- import
- require
- local module path
- package.json
- lockfile
- related configuration

Remove the specified target dependency from the target software's production dependency relationship.

Do not Zero-Dependency-convert unspecified dependencies.

Do not perform dependency updates unrelated to removal of the specified target dependency.

### Phase 7: Dependency Verification

Verify at minimum:

1. the target software's production dependency on the specified dependency is removed,
2. production code no longer directly imports/requires the specified dependency for the replaced functionality,
3. no new third-party production dependency was added as a substitute,
4. transitive dependency state is appropriately updated after removal,
5. the local implementation requires no new external runtime/tool/service in production.

If the same package remains through a separate pre-existing dependency path, record that path and distinguish it from the dependency path removed in this run.

### Phase 8: Behavioral Validation

Run, where applicable:

1. dependency installation
2. build
3. runtime execution
4. existing tests

If no build step exists, record N/A.

Do not modify existing tests.

Clearly distinguish additional diagnostic tests from existing tests.

If the SUCCESS conditions in Section 12 are not satisfied, proceed to Phase 9.

### Phase 9: Repair and Re-analysis

Identify the direct cause of validation failure and return to the phase responsible for the problem.

Procedure:

Failure
→ Cause Analysis
→ Cause Hypothesis
→ Responsible Phase Identification
→ Re-analysis or Modification
→ Revalidation

Default return mapping:

- missed Usage Context → Phase 2
- insufficient Relevant Implementation Analysis → Phase 3
- incorrect Replacement Specification → Phase 4
- Local Implementation defect → Phase 5
- Integration / Dependency Removal defect → Phase 6

When returning to an earlier phase, update that phase's artifacts and record the difference from the previous analysis/specification.

#### Repair Iteration Definition

One repair iteration consists of:

1. observing a Behavioral Validation failure,
2. analyzing the cause,
3. identifying the responsible phase,
4. returning to that phase,
5. re-analyzing or modifying,
6. re-running necessary downstream phases,
7. re-running Behavioral Validation.

#### Repair Limit

Use `run-config.json.max_repair_iterations` as the hard repair limit.

Do not increase it independently.

If the number of repair iterations reaches the configured maximum and SUCCESS is still not achieved, stop further repair, mark the final result as FAILED, and record:

- unresolved failure,
- last hypothesized cause,
- last responsible phase.

If `max_repair_iterations` is 0, do not attempt repair after the first failed Phase 8 validation.

---

## 8. Output Artifacts and File Placement

Separate generated files into three categories.

### 8.1 Zero-Dependency Local Implementation

These are production files used by the converted target software.

Do not force a universal location.

Choose a location that fits the target software's existing directory structure, module organization, naming conventions, and import style.

Declare planned production file paths and placement rationale in Phase 4 before implementation.

### 8.2 Analysis and Execution Artifacts

Keep analysis, specification, execution, and repair records separate from production implementation.

Default artifact directory:

`.zero-dependency/runs/<run-id>/`

Use `run-config.json.run_id` for `<run-id>`.

Create at minimum:

- `baseline.md`
- `usage-analysis.md`
- `implementation-analysis.md`
- `replacement-specification.md`
- `repair-log.md`
- `execution-report.md`

Create or update artifacts at the end of the corresponding phase rather than generating everything only at the end.

### 8.3 Temporary Analysis Files

Temporary files for probing, debugging, or source analysis should normally be placed under:

`.zero-dependency/runs/<run-id>/tmp/`

Temporary files are not part of the production implementation.

Before finishing, record necessary observations in the artifacts and remove temporary files that are no longer needed.

### 8.4 File Modification Record

Record every created, modified, or deleted file with at least:

- file path
- action: created / modified / deleted
- purpose
- related phase
- file category

Distinguish:

- production implementation
- analysis / execution artifact
- temporary analysis file

---

## 9. Uncertainty Handling

When significant uncertainty remains, do not continue based only on speculation.

Record at minimum:

- what cannot be determined
- why it cannot be determined
- evidence obtained
- analysis attempted
- why execution cannot safely continue

Do not hide uncertainty and report SUCCESS.

---

## 10. Additional Tests

You may generate additional tests for diagnosis, behavior probing, or local implementation verification.

Additional tests are not part of the formal SUCCESS criteria.

For each additional test, record:

- purpose
- tested behavior
- relation to required behavior
- result

Clearly distinguish existing tests from additional tests.

---

## 11. Human Intervention

If external information, judgment, correction, or instruction is provided during execution, record it as Human Intervention.

Record at least:

- intervention point
- reason
- information or instruction provided
- action taken afterward

Do not report a fully autonomous run when Human Intervention occurred.

---

## 12. SUCCESS Conditions

Report SUCCESS only if all applicable conditions below are satisfied:

1. the target software's specified external production dependency relationship is removed,
2. no new third-party production dependency is added as a substitute,
3. functionality required by the target software is replaced by local implementation,
4. if a build step exists, build succeeds,
5. the target software is executable,
6. all existing tests pass.

If the project genuinely has no build step, condition 4 is N/A.

Do not report SUCCESS if any applicable condition is not satisfied.

---

## 13. Final Output

At execution end, create `execution-report.md` containing at least:

### Execution Configuration

- Schema Version
- Run ID
- Repository
- Revision
- Target dependency
- Maximum repair iterations

### Target

- Software
- Version
- Commit
- Target dependency
- Resolved dependency version

### Environment

- OS
- Architecture
- Node.js
- npm
- Package manager
- Module system

### Baseline

- Installation
- Build
- Runtime
- Existing tests

### Usage Context Analysis

- Used APIs
- Call sites
- Arguments / Options
- Return values
- Required behavior
- Relevant environment / platform conditions

### Relevant Implementation Analysis

- Relevant source elements
- Relevant internal functions
- Relevant state / constants
- Relevant internal modules
- Relevant transitive dependency behavior
- Excluded functionality
- Exclusion reasons

### Replacement Specification

- Required behavior
- Not required behavior
- Implementation strategy
- Production files to create
- Production files to modify
- Placement rationale
- Known risks / uncertainties

### Implementation

- Generated local files
- Implemented behavior
- Modified files
- Removed dependency
- New third-party dependency added

### Dependency Verification

- Target dependency removal
- Remaining dependency paths
- New third-party dependencies
- New production runtime dependencies

### Behavioral Validation

- Installation
- Build
- Runtime
- Existing tests
- Additional tests

### Repair and Re-analysis

- Maximum repair iterations
- Repair iterations actually used

For each iteration:

- Observed failure
- Hypothesized cause
- Responsible phase
- Phase returned to
- Analysis/specification changes
- Modification
- Result

### Human Intervention

- Count
- Details

### File Modification Record

For each file:

- Path
- Action
- Purpose
- Related phase
- File category

### Final Result

Record the appropriate final state.

If the result is not SUCCESS, record a Failure / Uncertainty Reason.

---

## 14. Core Principle

Your purpose is not merely to generate code that makes tests pass.

Throughout analysis, specification, implementation, integration, validation, and repair, prioritize this principle:

> Identify behavior required by the target software from its actual usage context, retain only the scope necessary to realize that behavior as local implementation, and thereby remove the specified external third-party production dependency.

Using or reflecting original package code is not inherently a problem.

What matters is that the necessity of every retained function, behavior, or code region can be explained from the target software's usage context.

Keep production implementation clearly separated from analysis and experimental artifacts.

Do not retain unnecessary functionality or make unjustified changes. Keep analysis, judgment, specification, modification, validation, and re-analysis traceable.

---
name: design
description: Produce an implementation-ready architecture proposal with explicit interfaces, codebase evidence, decisions, invariants, and a simplification review. Use when the user invokes $design or /design, asks to design a system or feature, requests an architecture proposal, or wants a technical design before implementation.
---

# Design a system or feature

Create a concrete architecture document that an implementation agent can follow without ambiguity. Adapt exploration depth to the brief: explore broadly for an open-ended problem, focus on relevant boundaries for a constrained brief, and validate/formalize a detailed user sketch.

## Workflow

### 1. Track the design

Run `bd prime` in the project repository before other project work.

If `COCKPIT_DIR` is set and `$COCKPIT_DIR/project-tree.json` exists, inspect it and match the current working directory and topic to a project. Reuse the uniquely matching project's labels for every `bd create` in this run. If no project matches, omit project labels; ask only when choosing the wrong project would materially affect ownership.

Create and claim the task:

```sh
bd create --title="Design: <topic>" --type=task [--labels=<labels>]
bd update <id> --claim
```

Keep the returned task ID.

### 2. Establish the brief

Extract:

- Goal: the problem and desired outcome.
- Constraints: compatibility requirements and explicit exclusions.
- Proposed shape: APIs, boundaries, rollout, and decisions already supplied by the user.

Treat user-supplied architecture as a hypothesis to validate, not an invitation to redesign unrelated systems. Inspect linked source material with the appropriate available tool. For Figma desktop workflows in a Coder devbox, follow the repository's desktop-linux MCP instructions.

### 3. Explore in parallel

Spawn these three subagents together, with enough user and repository context to work independently:

1. **Codebase explorer**: map current architecture, interfaces, data flow, tests, and load-bearing behavior. Return file paths and line references.
2. **Prior-art explorer**: find analogous abstractions, conventions, rollout patterns, error handling, and tests in the repository.
3. **Devil's advocate**: challenge the proposed approach, rank failure modes and maintenance risks, and suggest concrete mitigations or simpler alternatives.

Explore locally while they run when useful. Synthesize their evidence; do not concatenate their reports.

### 4. Decide and specify

Make decisions instead of presenting a menu. Record why meaningful alternatives were rejected.

Specify every boundary used by the design:

- External APIs: endpoint/command, request, response, errors, and authentication.
- Internal interfaces: exact language-level types and signatures.
- Data schemas: exact added or changed fields, types, defaults, and purpose.
- Rollout controls: exact flag behavior, legacy fallback, failure behavior, and removal criteria.

Use `N/A — <reason>` for interface categories that genuinely do not apply. Do not invent flexibility without a known caller.

### 5. Write the proposal

Derive a unique 3–6 word kebab-case slug. Require `COCKPIT_DIR`; if it is unset or empty, stop and tell the user: `COCKPIT_DIR is not set. Set it before running $design.`

Create `$COCKPIT_DIR/state/proposals` if needed and write `<slug>.md` there using `apply_patch`. Do not overwrite an existing proposal; choose a more specific slug.

Use this structure:

```markdown
# Design: <Feature/System Name>

## Problem
<What and why>

## Constraints
<Compatibility requirements and exclusions>

## Architecture
<Mermaid component/data-flow diagram>

## Interfaces

### External APIs
<Complete specs or N/A>

### Internal Interfaces
<Exact types and signatures>

### Data Schemas
<Exact schema changes or N/A>

### Rollout
<Feature flags, legacy path, observability, and cleanup>

## Data Flow
<Numbered flows referencing interfaces>

## Key Decisions
| Decision | Chosen | Rejected | Why |
|---|---|---|---|

## Invariants
<Concrete constraints implementation must preserve>

## Testing
<Unit, integration, rollout, and regression coverage>

## Open Questions
<Only genuine human blockers, or N/A>

## Next Step
<Implementation handoff>

## Tracking
- Beads: <task-id> — closed
```

Reference existing code with clickable absolute `file:line` links where the rendering surface supports them. Ensure the Mermaid diagram matches the interfaces and data flows.

### 6. Run a clean-room simplification review

After drafting, spawn one fresh subagent with only the proposal text and this request:

> Review this design for unnecessary complexity. For every proposed component or interface, ask whether it can be removed, merged, or narrowed without losing a named behavior, invariant, or correctness property. Flag speculative flexibility. Return numbered recommendations with impact analysis.

Classify each recommendation as ACCEPT, MODIFY, or REJECT with a reason. Apply accepted and modified recommendations to the proposal.

### 7. Validate, publish, and close

Verify:

- Every template section has content or an explicit `N/A — <reason>`.
- Every interface has complete types, parameters, return values, and error/fallback behavior.
- Each key decision names at least one rejected alternative.
- The architecture diagram agrees with the described components and flows.
- Invariants are testable constraints.
- Open questions contain only genuine blockers.
- Existing code references resolve.
- The tracking section contains the claimed Beads ID.

Commit and push only the proposal in the cockpit repository, preserving unrelated changes:

```sh
git -C "$COCKPIT_DIR" add "state/proposals/<slug>.md"
git -C "$COCKPIT_DIR" commit -m "proposal: <slug>"
git -C "$COCKPIT_DIR" pull --rebase
git -C "$COCKPIT_DIR" push
```

If publication fails, report the exact failure and leave the Beads task open. After a successful push, close the task with `bd close <id>` and verify the cockpit repository is up to date with its remote.

Return only the absolute proposal path and a two-sentence summary of the chosen architecture and implementation handoff. Do not re-render the proposal in chat.

You are implementing a design. Your goal is to turn an approved design document into working code using parallel task execution.

## Input

The user has an approved design document (from /design, usually followed by /plan). They may provide:
- A path to the design document
- A reference to the most recent design
- Just "/implement" if the design is in conversation context

If no design is available, stop and tell the user to run /design first.

## Agent Strategy

| Step | Parallel? | Why |
|---|---|---|
| 1. Create tracking task | No — main agent | Track the run before starting |
| 2. Build the task graph | No — main agent | Read /plan's graph, or derive from the design |
| 3. Create shared interfaces | No — main agent | Must exist before workers start |
| 4. Spawn workers | Yes — all workers | Independent implementation tasks |
| 5. Integrate | No — main agent | Verify changes, run tests |
| 6. Tighten changes | No — main agent | /simplify + comment audit, re-run tests |
| 7. Archive consumed design | No — main agent | Move design to finished/ in cockpit |
| 8. Close tasks and report | No — main agent | Summarizes results with ## Tracking |

## Process

### 1. Create tracking task

Create one orchestration task for the whole run with the **TaskCreate** tool: title `Implement: [design name]`, status `in_progress`. Capture its id — call it the **orchestration task**. Every implementation subtask you create below is a separate Task; the orchestration task is the parent you close last.

Do not create a duplicate orchestration task. Child implementation tasks are the only other tasks you create.

### 2. Build the task graph

Check whether `/plan` already left a task graph in the conversation or in a plan file the user referenced.

- **If a task graph exists** → read it. Identify which tasks are ready (no unresolved deps) and which are blocked. Mirror each task into a harness Task (TaskCreate, status `pending`) so progress is trackable, then proceed.
- **If no task graph exists** → derive one from the design document. Parse and extract:
  - **Components** to build (from the Architecture section)
  - **Interfaces** to implement (from the Interfaces section)
  - **Data schemas** to create/modify (from the Data Schemas section)
  - **Dependencies** between tasks (which tasks block others)

  Create one harness Task per component (TaskCreate) with the interface spec, file scope, and acceptance criteria captured in the task body. Note the dependency order; you'll spawn unblocked tasks first.

### 3. Create shared interfaces

Before spawning workers, create any shared types, interfaces, proto definitions, or generated-type stubs that multiple workers need. This prevents workers from inventing incompatible interfaces.

Write these shared files before spawning workers.

### 4. Spawn workers (parallel)

For each ready task (no unresolved deps), spawn a worker:

**Worker** (Agent, model=opus):
> You are implementing one task from a design.
>
> ## Your Task: [task title]
> [paste the task description, including interface spec and file scope]
>
> ## Interface Spec
> [paste the relevant interfaces from the design]
>
> ## Files
> - Modify: [file paths]
> - Create: [file paths]
>
> ## Rules
> - Follow the interface spec exactly — do not add methods, fields, or parameters not in the spec
> - Match existing code patterns in the repo (error handling, naming, structure). Obey the nearest `AGENTS.md` / `CLAUDE.md` for the directory you're editing.
> - Write tests for the code you write, and run them:
>   - **sinatra (Ruby):** `RACK_ENV=test bundle exec ruby -Isinatra/test:sinatra/lib/test "<test file>"` (RCE/Coder) or `./devbox test "<test file>"` (classic devbox). Lint with `bundle exec rubocop <file>`; typecheck with `bundle exec srb tc` from `sinatra/`.
>   - **web (TS):** `DISPLAY=:0 pnpm test -- <test file>` from `web/` (RCE/Coder) or `./devbox test <test file>` (classic). Typecheck with `bazel build //web:ts_typecheck`; lint with `bazel lint //web:eslint_fast --//bazel/config/eslint:paths=$'<rel path>'`. Never use `tsc`/`eslint` directly.
>   - Other stacks: use the repo's real test command, not a guess.
> - Do not modify files outside your task scope
> - **Do not run any git commands** (no commits, no branching, no stashing) — the working-tree diff is handed to /pr afterward
> - If you're blocked or find the design is ambiguous, report the issue — do not guess
> - If you discover work outside your task scope (missing APIs, tech debt, schema gaps), report it at the end of your output:
>   ```
>   ## Discovered Work
>   - [title]: [one-line description]
>   ```
>   Do not create tasks yourself — the orchestrator will file them

Mark each task `in_progress` (TaskUpdate) as you spawn its worker. Spawn ALL ready workers in ONE assistant message using the `Agent` tool. Each is a synchronous, blocking call — multiple `Agent` tool uses in a single message run concurrently and the harness blocks the turn until every result returns. **Do not set `run_in_background: true`** for workers — you want their results in hand before integrating.

For tasks with unresolved deps: wait for the blocking workers to complete, then spawn the next wave.

### 5. Integrate

After all workers complete:

- Review the changes made by all workers for consistency
- Run the relevant tests for the touched areas (see the per-stack commands in the worker rules above)
- Fix integration issues — usually import paths, type mismatches, or missing glue code
- Collect `## Discovered Work` sections from all worker outputs
- File each discovered item as a **new top-level Task** (TaskCreate) — not a child of the orchestration task — so it survives after this run closes. Briefly list them in the report.
- Do not run any git commands

If any check fails, fix it before reporting.

### 6. Tighten changes

After integration is green, tighten the code the workers produced before it leaves the skill. There is no PR yet, so everything here is scoped to the implementation's **working-tree changes** (the uncommitted diff).

1. **Simplify the code.** Invoke the `/simplify` skill over the changes. It applies reuse, simplification, efficiency, and altitude cleanups in place — collapsing duplication, swapping reinvented helpers for existing ones, and removing complexity the parallel workers couldn't see across task boundaries.

2. **Audit comments for load-bearing value.** Review every comment the implementation added or changed and cut the ones that don't earn their place:
   - **Always strip personal workflow artifacts** (no judgment call — these must never ship in code): task IDs, links or paths to design docs (`$COCKPIT_DIR/state/designs/…` or any cockpit reference), "see the plan / per the design" pointers, and any other internal tracking reference. They're meaningless to a repo reader and leak private context.
   - **Remove** comments that explain *what* well-named code already says, that reference the task/PR ("added for X"), or that are tombstones (`# renamed from…`, stale TODOs).
   - **Collapse** multi-paragraph docstrings or blocks to the one line that carries the load.
   - **Keep** only the non-obvious *why*: hidden constraints, invariants, ordering requirements, workaround-for-bug notes. When in doubt, keep — deleting load-bearing context is worse than leaving a marginal comment.

3. **Re-run the Step 5 tests.** Both passes edit real code, so re-run the same tests. If a cleanup broke something, fix it or revert that specific change — never report with red tests.

Do not run any git commands in the code repo — the changes stay in the working tree for /pr.

### 7. Archive consumed design

If the design document lives in `$COCKPIT_DIR/state/designs/`, move it to `$COCKPIT_DIR/state/designs/finished/` and commit + push the cockpit repo so the move propagates to your other devboxes:

```bash
mkdir -p "$COCKPIT_DIR/state/designs/finished"
mv "$design_file" "$COCKPIT_DIR/state/designs/finished/"
git -C "$COCKPIT_DIR" add -A
git -C "$COCKPIT_DIR" commit -m "archive design: $(basename "$design_file") (implemented)"
git -C "$COCKPIT_DIR" push
```

(Committing the cockpit scratchpad is fine — cockpit is your own repo. This is the one place the skill touches git, and it's never the code repo.) If the design wasn't in the cockpit, skip this step.

### 8. Close tasks and report

Mark each completed implementation task `completed` (TaskUpdate), then mark the orchestration task `completed`.

Write the Implementation Report:

```markdown
# Implementation Report: [Design Name]

## Tasks Completed
- <task title> — done

## Files Created/Modified
[list files with brief description]

## Test Results
[pass/fail summary]

## Deviations & Discovered Work
[differences from design, with rationale]
[titles of any new tasks filed for discovered work, or "None"]

## Tracking
- Orchestration task: <title/id> — completed
```

Save the report with the Write tool to `$COCKPIT_DIR/state/implementations/implement-report-<design-slug>.md` (create the dir if needed), and tell the user the path. You MUST write the file to disk — do not just output the report as conversation text.

Then tell the user the working-tree diff is ready and suggest running **/pr** to ship it.

## Rules

- **Do not start without a design** — if there's no design document, stop
- **Do not run git in the code repo** — `/implement` leaves an uncommitted working-tree diff; `/pr` owns committing, branching, and PR creation. The only git this skill runs is committing the design archive in `$COCKPIT_DIR` (Step 7).
- **No worktrees** — do not use `isolation: "worktree"` on worker agents
- **Shared interfaces first** — create them before spawning workers to prevent drift
- **Workers follow the spec exactly** — no freelancing, no extra methods, no bonus abstractions
- **Match existing patterns** — look at neighboring code and the directory's `AGENTS.md`/`CLAUDE.md` before writing new code
- **Tests are required** — every worker writes and runs tests for its code, using the repo's real test command
- **Report deviations** — if implementation must differ from design, explain why
- **## Tracking is mandatory** — the report must list the orchestration task and its status

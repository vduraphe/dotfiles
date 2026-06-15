You are exploring and documenting a system or area of the codebase. Your goal is to produce a structured document that gives a reader (human or agent) a complete mental model.

## Input

The user provides a system, feature, or area to explore. Examples:
- "the auth token rotation system"
- "how the API gateway routes requests"
- "the billing pipeline"

## Agent Strategy

| Step | Parallel? | Why |
|---|---|---|
| 1. Create Beads task | No — main agent | Track work before starting |
| 2. Scope exploration | No — main agent | Needs user input to define focus |
| 3. Topic explorers (Data Flow, Schema, Integration, Invariant) | Yes — 4 agents | Independent research areas |
| 4. Synthesize | No — main agent | Combines all explorer output |
| 5. Output | No — main agent | Formats final document + closes Beads |
| 6. Self-validation | No — main agent | Checks output completeness |

## Process

### 1. Create Beads task

**Project labeling**: Read `$COCKPIT_DIR/project-tree.json` (skip if missing or `COCKPIT_DIR` unset). Review the project list to understand the landscape of active projects and their labels. Determine which project this work belongs to by matching `cwd` against project `path` fields and matching the explored area against project names. If exactly one project matches, use its `labels` array. If ambiguous or no match, ask the user which project this is for. Store the resolved labels for all `bd create` calls in this skill invocation.

Run `bd create --title="Explore: [area]" --type=task --labels=<resolved-labels>` and store the returned task ID.
Claim it: `bd update <id> --claim`.

### 2. Scope the exploration

Identify the key questions to answer:
- What does this system do?
- What are the request/data flows?
- What are the key invariants and constraints?
- What data stores and schemas are involved?
- What are the integration points with other systems?
- What are the failure modes?

### 3. Spawn topic explorers (parallel)

Spawn ALL explorers in ONE message. Each gets a focused area:

**Data Flow Explorer** (Agent, model=opus):
> Trace the primary data flows through this system. Follow requests end-to-end. Identify entry points, transformations, and where data is stored or forwarded. Return: numbered list of flows with file paths and function names.

**Schema & State Explorer** (Agent, model=opus):
> Find all data stores, schemas, types, and state this system manages. Include database tables, proto definitions, config files, caches. Return: list of schemas with field descriptions and where they're used.

**Integration Explorer** (Agent, model=opus):
> Map all integration points — other services this system calls, services that call it, shared queues, events published/consumed. Return: list of dependencies with direction (inbound/outbound) and protocol.

**Invariant Explorer** (Agent, model=opus):
> Identify constraints, invariants, and implicit rules. Look for: validation logic, error handling patterns, retry policies, ordering guarantees, consistency requirements. Return: list of invariants with the code that enforces them.

### 4. Synthesize

Combine all explorer findings into a single structured document. Resolve conflicts between explorers. Fill gaps by reading additional files if needed.

### 5. Output

Write the exploration document to the cockpit state directory:
1. If `$COCKPIT_DIR` is unset or empty, stop: "COCKPIT_DIR is not set. Set it before running /explore."
2. `mkdir -p "$COCKPIT_DIR/state/explorations"` and write the document to `$COCKPIT_DIR/state/explorations/<slug>.md` where `<slug>` is a kebab-case version of the system/area name (max 50 chars). Fill the `## Tracking` section with the Beads task ID from Step 1.
3. Commit and push to the cockpit repo:
   ```bash
   git -C "$COCKPIT_DIR" add "state/explorations/<slug>.md"
   git -C "$COCKPIT_DIR" commit -m "exploration: <slug>"
   git -C "$COCKPIT_DIR" push
   ```
   If any git command fails, warn the user but continue.
4. Close the Beads task: `bd close <task-id>`.

Produce a markdown document with these sections:

```markdown
# [System Name]

## Overview
One paragraph: what it does, why it exists.

## Architecture
Mermaid diagram showing key components and their relationships.

## Request/Data Flows
Numbered flows, each with:
- Entry point (file:line)
- Steps with file references
- Terminal state

## Data Stores & Schemas
Tables, caches, queues — with key fields and purpose.

## Integration Points
What this system talks to and what talks to it.

## Key Invariants
Constraints the system maintains, with the code that enforces them.

## Failure Modes
What breaks and how the system handles it.

## Tracking
- Beads: <task-id> — closed
```

### 6. Self-validation

Before presenting the final document, verify:

- [ ] Every section in the output template has content (or an explicit "N/A — [reason]")
- [ ] Every claim references a specific file and function/line
- [ ] No inference is presented as established fact — column names, variable names, and patterns are labeled as suggestive, not definitive
- [ ] Architecture diagram exists and matches the described components
- [ ] Data flows are end-to-end (entry point → terminal state), not fragments
- [ ] Integration points list direction (inbound/outbound) and protocol
- [ ] No section is a restatement of another — each adds distinct information
- [ ] A Beads task was created and claimed before exploration, recorded in `## Tracking`, and closed after the document was saved

If any check fails, go back and fill the gap before presenting.

## Rules

- Every claim must reference a specific file and function/line
- Use mermaid diagrams for architecture and complex flows
- Keep it factual — document what IS, not what should be
- **Beads tracks the work** — create and claim the task before exploring, close it after the document is saved, and record the ID in `## Tracking`
- If an area is unclear or undocumented, say so explicitly
- **Distinguish evidence from inference.** A claim backed by code you read is evidence. A claim derived from a column name, variable name, or pattern match is inference. Label inferences explicitly: "the column name suggests…" not "this is…". When the user or a coworker will act on your output (PR comments, Slack replies, Asana updates), only state what you can cite — bad inferences erode trust faster than gaps do.
- **When answering coworker questions or drafting external communication**, every factual claim must have a source you can point to (file:line, URL, error message). If you can't find one, say "I couldn't verify this" rather than presenting inference as fact.

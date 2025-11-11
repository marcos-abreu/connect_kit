# Spec-Driven Development Workflow

## Overview

Complete SDD workflow with set of skills following Anthropic best practices titles, specific descriptions, proper skill structure, and integration with Superpowers patterns.

## Quick Start

1. **Place all skills** in `.claude/skills/`
2. **Type `/catchup`** to start workflow
3. **Follow the prompts** - workflow guides you through each phase

## File Structure

```
your-project/
├── specs/
│   ├── product/
│   │   ├── mission.md
│   │   ├── roadmap.md
│   │   └── tech-stack.md
│   └── features/
│       └── YYYY-MM-DD-feature-name/
│           ├── planning/
│           │   ├── initialization.md
│           │   ├── requirements.md
│           │   └── visuals/
│           ├── spec.md
│           ├── tasks.md
│           ├── verification/
│           │   ├── spec-verification.md
│           │   ├── final-verification.md
│           │   └── screenshots/
│           └── implementation/
│               └── [N]-[group-name]-implementation.md
└── .claude/skills/
    ├── sdd-orchestrator.md
    ├── product-planning.md
    ├── spec-creation-workflow.md
    ├── spec-initialization.md
    ├── requirements-gathering.md
    ├── spec-writing.md
    ├── tasks-planning.md
    ├── spec-verification.md
    ├── spec-implementation-workflow.md
    └── implementation-verification.md
```

## Skills Created (10 Total)

### Core Orchestration (3 skills)

**1. sdd-orchestrator.md**
- **When:** Via `/catchup` command
- **Does:** Scans specs/, detects state, announces status, proposes next step, waits for confirmation, routes to workflow
- **Lines:** ~200

**2. spec-creation-workflow.md**
- **When:** Creating new spec or resuming incomplete spec
- **Does:** Orchestrates 5 phases with validation between each
- **Lines:** ~250

**3. spec-implementation-workflow.md**
- **When:** Spec verified and ready for implementation
- **Does:** Sets up worktree, executes tasks via subagent-driven or sequential, verifies, completes branch
- **Lines:** ~300

### Spec Creation Phases (5 skills)

**4. spec-initialization.md**
- **When:** Phase 1 of spec creation
- **Does:** Creates dated folder structure, saves raw idea
- **Lines:** ~200

**5. requirements-gathering.md**
- **When:** Phase 2 of spec creation
- **Does:** Asks questions ONE at a time, checks visuals (mandatory), documents requirements
- **Lines:** ~300

**6. spec-writing.md**
- **When:** Phase 3 of spec creation
- **Does:** Searches codebase for reusability, presents spec in 150-200 word sections, validates each
- **Lines:** ~300

**7. tasks-planning.md**
- **When:** Phase 4 of spec creation
- **Does:** Creates task groups with dependencies, TDD-based (no test counting)
- **Lines:** ~300

**8. spec-verification.md**
- **When:** Phase 5 of spec creation
- **Does:** Verifies completeness, accuracy, reusability, flags over-engineering
- **Lines:** ~300

### Supporting Skills (2 skills)

**9. product-planning.md**
- **When:** No product documentation exists
- **Does:** Brainstorming-style product vision exploration, creates mission/roadmap/tech-stack
- **Lines:** ~300

**10. implementation-verification.md**
- **When:** After implementation complete
- **Does:** Verifies all tasks done, updates roadmap, runs full test suite, creates final report
- **Lines:** ~300

## Key Changes from Initial Version

### Fixed Issues

✅ **Skill Descriptions** - Now specific about when/why to use (following Superpowers pattern)
✅ **Removed ALL test counting** - Let TDD work naturally, no artificial limits
✅ **Removed Parallel Agents option** - Option C removed from implementation workflow
✅ **Changed state name** - IMPLEMENTATION_NOT_STARTED → IMPLEMENTATION_READY
✅ **Product planning questions** - Uses brainstorming approach, not rigid 5 questions
✅ **Skill lengths** - All 100-350 lines with progressive disclosure
✅ **Orchestrator trigger** - Changed from auto-trigger to `/catchup` command
✅ **verification-before-completion usage** - Clarified as principle for subagents, not explicit call

### Testing Philosophy

**OLD (AgentOS approach):**
- 2-8 tests per task group (counting)
- Maximum 10 tests in gap analysis
- Expected 16-34 tests total
- Artificial limits throughout

**NEW (TDD approach):**
- Follow TDD naturally
- Write tests for each behavior
- No counting or limits
- Subagents following TDD write appropriate tests
- Tasks note "follow TDD" but don't specify counts

**Why:** Skills can't enforce test counting. Subagents following TDD will write the right tests naturally.

## Workflow Flow

```
User types: /catchup
    ↓
sdd-orchestrator
    ├─ Scans specs/ folder
    ├─ Detects state
    ├─ ANNOUNCES status
    ├─ PROPOSES next step
    ├─ WAITS for confirmation
    └─ Routes based on choice

Routes to one of:

├─→ product-planning (if no product docs)
│   ├─ Brainstorms product vision
│   ├─ ONE question at a time
│   ├─ Presents sections incrementally
│   └─ Creates mission.md, roadmap.md, tech-stack.md
│
├─→ spec-creation-workflow (if creating/completing spec)
│   │
│   ├─→ Phase 1: spec-initialization
│   │   └─ Creates dated folder, saves idea
│   │
│   ├─→ Phase 2: requirements-gathering
│   │   ├─ Asks questions ONE at a time
│   │   ├─ MANDATORY: Checks visuals folder
│   │   └─ Documents requirements.md
│   │
│   ├─→ Phase 3: spec-writing
│   │   ├─ Searches codebase for reusability
│   │   ├─ Presents sections (150-200 words)
│   │   └─ Validates each section
│   │
│   ├─→ Phase 4: tasks-planning
│   │   ├─ Determines task groups
│   │   ├─ Validates structure
│   │   └─ Creates tasks.md (TDD-based, no counting)
│   │
│   └─→ Phase 5: spec-verification
│       ├─ Systematic checks
│       ├─ [Pass] Ready for implementation
│       └─ [Fail] Fix issues → re-verify
│
└─→ spec-implementation-workflow (if spec ready)
    │
    ├─ Present approach options:
    │   • Option A: subagent-driven (less intervention)
    │   • Option B: sequential (more control)
    │
    ├─→ using-git-worktrees (Superpowers)
    │   └─ Creates isolated workspace
    │
    ├─→ Execute based on approach:
    │   ├─ subagent-driven-development OR
    │   └─ executing-plans
    │   (Subagents use verification-before-completion principles)
    │
    ├─→ implementation-verification
    │   ├─ Verifies tasks complete
    │   ├─ Updates roadmap
    │   ├─ Runs full test suite
    │   └─ Creates final report
    │
    └─→ finishing-development-branch (Superpowers)
        ├─ Presents options (merge/PR/keep/discard)
        ├─ Executes choice
        └─ Cleans up worktree
```

## Design Patterns

### 1. Brainstorming-Style Interaction

**Every skill uses:**
- ONE question at a time
- Present in small chunks (150-200 words)
- Validate incrementally
- Offer alternatives
- Wait for confirmation

### 2. State Detection (Filesystem Only)

**Detected from:**
- File existence (initialization.md, requirements.md, etc.)
- Checkbox states (tasks.md, roadmap.md)
- Verification report status
- No hidden state files

### 3. Progressive Disclosure

**Skills are concise (100-350 lines):**
- Point to other skills
- Reference docs instead of embedding
- Use Skill tool to invoke others
- Single responsibility focus

### 4. TDD Without Counting

**Testing approach:**
- Follow TDD naturally
- Write test for behavior → implement → refactor
- No artificial test counts
- Subagents write appropriate tests for components

### 5. Reusability First

**Always search before creating:**
- Requirements phase: Ask about similar features
- Spec writing phase: Search codebase
- Tasks phase: Note reuse opportunities
- Verification phase: Flag when ignored

## Integration with Superpowers

### SDD Skills Use Superpowers At:

**During Implementation:**
- `using-git-worktrees` - REQUIRED before starting
- `subagent-driven-development` - Option A (recommended)
- `executing-plans` - Option B (more control)
- `finishing-development-branch` - REQUIRED to complete

**During Implementation (Principles):**
- `verification-before-completion` - Subagents follow principles before marking tasks done

**During Spec Creation (Optional):**
- `brainstorming` - Can be used during requirements/spec phases for complex features

### Command to Start

**`/catchup`** triggers `sdd-orchestrator`

Alternative names considered:
- `/status` (too ambiguous)
- `/sdd` (too abbreviated)
- `/resume` (implies paused)
- `/continue` (similar to resume)

**`/catchup` chosen** - clear intent: "catch me up on workflow state"

## User Experience

### First Time

```
User: /catchup

Claude:
📋 Spec-Driven Development Status

Product Documentation:
⚠️  Product documentation needed

Proposed: Create product documentation
Required before specs.

What would you like to do?
1. Create product documentation
2. Something else (describe)
```

### Creating Spec

```
[After product docs complete]

User: /catchup

Claude:
📋 Status

Product: ✅ Complete
Active Specs: None

Next Roadmap: User Authentication

Proposed: Start user authentication spec

What would you like to do?
1. Start user authentication spec
2. Different feature (describe)
3. Something else

---

[User chooses 1]

Phase 1: Initialization
[Creates structure]

Phase 2: Requirements
[ONE question at a time]

Phase 3: Spec Writing
[Searches codebase, presents sections]

Phase 4: Tasks Planning
[Creates breakdown]

Phase 5: Verification
✅ Passed - Ready for implementation!
```

### Implementing

```
User: /catchup

Claude:
📋 Status

Active Specs:
🟢 2025-11-09-user-authentication
   └─ Phase: Implementation ready

Proposed: Implement user-authentication

What would you like to do?
1. Implement user-authentication
2. Something else

---

[User chooses 1]

Implementation approach:
A. Subagent-driven (recommended)
B. Sequential execution

Which?

---

[Sets up worktree]
[Executes tasks]
[Verifies implementation]
[Completes branch]

✅ Implementation complete!
```

## Configuration

### Required Setup

**1. Place skills in `.claude/skills/`**

**2. Create /catchup command** (in your custom commands file):

```yaml
# .claude/commands/catchup.md (or similar)
---
name: catchup
description: Check workflow status and continue where you left off
---

Run the sdd-orchestrator skill to detect current state and guide next steps.

Use Skill tool: sdd-orchestrator
```

**3. Folder structure** (created automatically by skills):
```bash
mkdir -p specs/product
mkdir -p specs/features
```

### Optional Customization

**In global CLAUDE.md:**

```markdown
## Spec-Driven Development

This project follows SDD workflow.

- Product docs: specs/product/
- Feature specs: specs/features/
- Worktree location: .worktrees/ (or worktrees/ or global)
- Use /catchup to check status

[Add project-specific SDD preferences]
```

## Testing the Workflow

### Test Sequence

1. `/catchup` - Should announce "No product documentation"
2. Create product docs - Go through questions
3. `/catchup` - Should show product complete, propose first spec
4. Create first spec - Go through 5 phases
5. `/catchup` - Should show spec ready for implementation
6. Implement spec - Choose approach, complete
7. `/catchup` - Should detect completed work, show status

### Expected Behavior

✅ ONE question at a time during requirements
✅ MANDATORY visual folder check (bash command)
✅ Content in 150-200 word chunks with validation
✅ TDD-based tasks (no counting)
✅ Reusability searched and leveraged
✅ Isolated worktree before implementation
✅ Verification gates before completion

## Summary

Your SDD workflow is now complete with:

✅ 10 concise skills (100-350 lines each)
✅ Specific descriptions following Anthropic best practices
✅ `/catchup` command to trigger workflow
✅ Brainstorming-style interaction throughout
✅ TDD approach without artificial test counting
✅ Superpowers integration at key points
✅ Filesystem-based state detection
✅ Verification gates at critical junctures

The workflow automatically guides you from product planning through spec creation to implementation, with clear status announcements and checkpoints at every phase.

**Ready to use!** Place skills in `.claude/skills/` and type `/catchup` to begin.

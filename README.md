# qa-executor - Worker Agent

**Role**: qa-tools execution specialist
**Coordinator**: Liam (main agent)
**Channel**: `#qa-core` (Discord)

## Purpose

Execute qa-tools operations under the coordination of the main agent. This worker agent:
- Receives work orders via Discord (#qa-core)
- Executes qa-tools commands (generate, evaluate, lake)
- Reports progress and results naturally
- Asks questions when blocked

## Quick Start

### As a Human (Testing)

```bash
# Set environment
export QA_TOOLS_CORE_DIR=~/Src/qa-tools/qa-tools-core
export QA_TOOLS_DESIGNER_DIR=~/Src/qa-tools/qa-tools-designer

# Test qa-tools CLI
cd $QA_TOOLS_CORE_DIR
qa-tools --help
qa-tools evaluate --help
```

### As an Agent (Production)

When deployed as an OpenClaw agent:
1. Bind to Discord channel `#qa-core`
2. Listen for work orders from coordinator
3. Parse natural language commands
4. Execute qa-tools operations
5. Report results back to channel

## Work Order Examples

### Experiment Generation

**Coordinator**: "qa-executor: Run generate for experiment uc_customer_support_triage"

**Worker**:
```
Running qa-tools generate...
Command: qa-tools generate --experiment uc_customer_support_triage
Config: qa-tools-core/config/default.yaml
Output: lake/experiments/uc_customer_support_triage_20260222.parquet

✅ Generate complete
- Episodes: 50
- Duration: 3m 12s
- Artifact: uc_customer_support_triage_20260222.parquet
Done.
```

### Evaluation

**Coordinator**: "qa-executor: Run evaluation for uc_customer_support_triage"

**Worker**:
```
Running qa-tools evaluate...
Command: qa-tools evaluate --experiment uc_customer_support_triage
Model: openai:gpt-4o

✅ Evaluation complete
- Correctness: 0.78
- Relevance: 0.85
- Faithfulness: 0.72
- Total questions: 50
- Failed: 3
- Duration: 4m 23s
- Artifact: lake/evaluations/uc_customer_support_triage_20260222.parquet

Failures:
1. Question 17: Retrieved context missing
2. Question 23: Model timeout
3. Question 41: Invalid JSON response

Next step: Review failures or run next experiment?
```

### Lake Query

**Coordinator**: "qa-executor: What's the average correctness across all experiments this week?"

**Worker**:
```
Querying lake...
SQL: SELECT AVG(correctness) FROM evaluations WHERE date >= '2026-02-14'

Result:
- Average correctness: 0.76
- Experiment count: 12
- Range: 0.62 - 0.89
- Lowest: uc_public_sector_citizen_services (0.62)
- Highest: uc_developer_docs_assistant (0.89)

Done.
```

## Blocking Issues

When something goes wrong:

```
⚠️ Blocked on uc_healthcare_patient_education evaluation

Issue: Episode not found in lake
Error: Parquet file not found at lake/experiments/uc_healthcare_patient_education_*.parquet
Diagnosis: Need to run generate first

Options:
1. Run 'qa-tools generate --experiment uc_healthcare_patient_education'
2. Skip and move to next experiment

Which should I do?
```

## Safety

### Allowed Operations
- ✅ Run qa-tools commands in read-only mode
- ✅ Read lake data and artifacts
- ✅ Write to designated output directories
- ✅ Ask questions and report progress

### Requires Approval
- ⚠️ Delete any lake artifacts
- ⚠️ Modify experiment specs
- ⚠️ Change qa-tools configuration
- ⚠️ Run destructive operations

### Never Allowed
- ❌ Expose secrets or API keys
- ❌ Send messages to external channels
- ❌ Modify coordinator workspace
- ❌ Bypass safety checks

## Workspace Layout

```
qa-executor/
├── SOUL.md              # Who you are
├── IDENTITY.md          # Your role and boundaries
├── AGENTS.md            # Workspace conventions
├── README.md            # This file
├── memory/              # Daily notes
└── workspace/           # Execution workspace
```

## Environment Variables

```bash
# qa-tools paths
QA_TOOLS_CORE_DIR=~/Src/qa-tools/qa-tools-core
QA_TOOLS_DESIGNER_DIR=~/Src/qa-tools/qa-tools-designer
QA_USE_CASES_DIR=~/Src/qa-tools/qa-use-cases

# Discord (for agent deployment)
DISCORD_WEBHOOK_QA_CORE=https://discord.com/api/webhooks/...
```

## Related

- **Spec**: `qa-tools-agentic-team/docs/worker_agent_spec.md`
- **Coordinator**: `qa-tools-agentic-team` (Liam)
- **Discord setup**: `qa-tools-agentic-team/docs/discord_setup_checklist.md`

---

**Status**: 🚧 In development (workspace setup, not yet deployed)
**Created**: 2026-02-22
**Created by**: Liam (coordinator)

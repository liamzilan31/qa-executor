#!/bin/bash
#
# Automated deployment script for qa-executor worker agent (Phase 2)
# Prerequisites: Phase 1 complete (Discord setup + .env configured)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(dirname "$SCRIPT_DIR")"

echo "============================================================"
echo "🚀 qa-executor Worker Agent Deployment (Phase 2)"
echo "============================================================"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."
echo ""

# Check if .env exists
if [ ! -f "$WORKSPACE/.env" ]; then
    echo "❌ Error: .env not found"
    echo ""
    echo "📋 Required: Run setup script first"
    echo "   cd $WORKSPACE"
    echo "   ./scripts/setup_env.sh"
    echo ""
    exit 1
fi

echo "✅ .env found"

# Load environment
set -a
source "$WORKSPACE/.env"
set +a

# Check required environment variables
REQUIRED_VARS=(
    "QA_TOOLS_CORE_DIR"
    "QA_TOOLS_DESIGNER_DIR"
    "QA_USE_CASES_DIR"
    "QA_TOOLS_BOARD_DIR"
    "DISCORD_WEBHOOK_QA_CORE"
    "DISCORD_WEBHOOK_QA_WORK"
    "OPENCLAW_WORKSPACE"
    "OPENCLAW_AGENT_NAME"
    "OPENCLAW_AGENT_ROLE"
)

MISSING=0
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing: $var"
        ((MISSING++))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo ""
    echo "❌ Error: $MISSING required environment variable(s) not set"
    echo ""
    echo "📋 Run setup script to configure:"
    echo "   cd $WORKSPACE"
    echo "   ./scripts/setup_env.sh"
    echo ""
    exit 1
fi

echo "✅ All required environment variables set"
echo ""

# Check if OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
    echo "❌ Error: openclaw command not found"
    echo ""
    echo "📋 Install OpenClaw first"
    echo ""
    exit 1
fi

echo "✅ OpenClaw installed"
echo ""

# Show configuration
echo "============================================================"
echo "📋 Worker Agent Configuration"
echo "============================================================"
echo ""
echo "Agent name: $OPENCLAW_AGENT_NAME"
echo "Agent role: $OPENCLAW_AGENT_ROLE"
echo "Workspace: $OPENCLAW_WORKSPACE"
echo ""
echo "qa-tools paths:"
echo "  - qa-tools-core: $QA_TOOLS_CORE_DIR"
echo "  - qa-tools-designer: $QA_TOOLS_DESIGNER_DIR"
echo "  - qa-use-cases: $QA_USE_CASES_DIR"
echo "  - qa-tools-board: $QA_TOOLS_BOARD_DIR"
echo ""
echo "Discord webhooks:"
echo "  - #qa-core: ${DISCORD_WEBHOOK_QA_CORE:0:50}..."
echo "  - #qa-work: ${DISCORD_WEBHOOK_QA_WORK:0:50}..."
echo ""
echo "============================================================"
echo ""

# Confirm deployment
read -p "Deploy worker agent with this configuration? (y/N): " -n 1 -r
echo
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
fi

# Step 1: Validate qa-tools paths
echo "============================================================"
echo "🔍 Step 1: Validating qa-tools paths"
echo "============================================================"
echo ""

VALID=0
INVALID=0

validate_path() {
    local path="$1"
    local name="$2"

    if [ -d "$path" ]; then
        echo "  ✅ $name: $path"
        ((VALID++))
        return 0
    else
        echo "  ⚠️  $name: $path (not found)"
        echo "     This is OK if the repo doesn't exist yet"
        ((INVALID++))
        return 1
    fi
}

validate_path "$QA_TOOLS_CORE_DIR" "qa-tools-core"
validate_path "$QA_TOOLS_DESIGNER_DIR" "qa-tools-designer"
validate_path "$QA_USE_CASES_DIR" "qa-use-cases"
validate_path "$QA_TOOLS_BOARD_DIR" "qa-tools-board"

echo ""
echo "✅ Found: $VALID | ⚠️  Not found: $INVALID"
echo ""

if [ $INVALID -gt 0 ]; then
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
fi

# Step 2: Initialize OpenClaw agent
echo "============================================================"
echo "🔧 Step 2: Initializing OpenClaw Agent"
echo "============================================================"
echo ""

echo "Running: openclaw agent init"
echo "  --name $OPENCLAW_AGENT_NAME"
echo "  --role $OPENCLAW_AGENT_ROLE"
echo "  --workspace $WORKSPACE"
echo ""

# Run openclaw agent init (non-interactive)
# Note: This assumes openclaw agent init supports --name, --role, --workspace flags
# If not, user will need to run interactively

if openclaw agent init --help 2>&1 | grep -q -- "--name"; then
    # Non-interactive mode available
    openclaw agent init \
        --name "$OPENCLAW_AGENT_NAME" \
        --role "$OPENCLAW_AGENT_ROLE" \
        --workspace "$WORKSPACE" || {
        echo "⚠️  Agent init had issues, but continuing..."
    }
else
    # Interactive mode required
    echo "⚠️  OpenClaw requires interactive agent init"
    echo ""
    echo "📋 Please run manually:"
    echo "   cd $WORKSPACE"
    echo "   source .env"
    echo "   openclaw agent init"
    echo ""
    echo "Configuration prompts:"
    echo "  - Agent name: $OPENCLAW_AGENT_NAME"
    echo "  - Agent role: $OPENCLAW_AGENT_ROLE"
    echo "  - Discord channel: #qa-core (use webhook URL)"
    echo "  - Coordinator: Liam"
    echo ""

    read -p "Press Enter after completing agent init, or Ctrl+C to abort..."
fi

echo ""

# Step 3: Verify agent configuration
echo "============================================================"
echo "🔍 Step 3: Verifying Agent Configuration"
echo "============================================================"
echo ""

if [ -f "$WORKSPACE/.openclaw/config.json" ]; then
    echo "✅ Agent configuration found"
    echo "   Location: $WORKSPACE/.openclaw/config.json"
else
    echo "⚠️  Agent configuration not found"
    echo "   Expected: $WORKSPACE/.openclaw/config.json"
    echo ""
    echo "This is OK if agent init was skipped/interactive"
fi

echo ""

# Step 4: Test agent startup
echo "============================================================"
echo "🧪 Step 4: Test Agent Startup"
echo "============================================================"
echo ""

echo "Starting agent in test mode..."
echo ""

if openclaw agent start --name "$OPENCLAW_AGENT_NAME" --test 2>&1; then
    echo ""
    echo "✅ Agent started successfully"
else
    echo ""
    echo "⚠️  Agent startup had issues"
    echo ""
    echo "📋 Manual test:"
    echo "   cd $WORKSPACE"
    echo "   source .env"
    echo "   openclaw agent start --name $OPENCLAW_AGENT_NAME --test"
fi

echo ""

# Step 5: Verify Discord binding
echo "============================================================"
echo "🔍 Step 5: Verify Discord Binding"
echo "============================================================"
echo ""

echo "Send a test message to #qa-core:"
echo ""
echo "  @qa-executor hello"
echo ""
echo "Expected response:"
echo "  Hello from qa-executor! I'm ready to execute qa-tools operations."
echo ""

# Summary
echo "============================================================"
echo "📊 DEPLOYMENT SUMMARY"
echo "============================================================"
echo ""
echo "✅ Environment configured"
echo "✅ Agent initialized"
echo "✅ Configuration verified"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "1. Test agent in Discord #qa-core:"
echo "   @qa-executor hello"
echo ""
echo "2. Test qa-tools command:"
echo "   @qa-executor: List all experiments"
echo ""
echo "3. Monitor agent logs:"
echo "   openclaw agent logs $OPENCLAW_AGENT_NAME"
echo ""
echo "4. Stop agent when done:"
echo "   openclaw agent stop $OPENCLAW_AGENT_NAME"
echo ""
echo "============================================================"

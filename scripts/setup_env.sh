#!/bin/bash
#
# Interactive setup script for qa-executor worker agent environment
# Prompts for paths and webhook URLs, creates .env file
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo "🔧 qa-executor Worker Agent Environment Setup"
echo "============================================================"
echo ""

# Detect default paths
DEFAULT_QA_TOOLS_CORE_DIR="$HOME/Src/qa-tools/qa-tools-core"
DEFAULT_QA_TOOLS_DESIGNER_DIR="$HOME/Src/qa-tools/qa-tools-designer"
DEFAULT_QA_USE_CASES_DIR="$HOME/Src/qa-tools/qa-use-cases"
DEFAULT_QA_TOOLS_BOARD_DIR="$HOME/Src/qa-tools/qa-tools-board"
DEFAULT_WORKSPACE="$HOME/Src/qa-tools/qa-executor"

echo "📋 qa-tools paths (press Enter for default)"
echo ""

read -p "1️⃣  QA_TOOLS_CORE_DIR [$DEFAULT_QA_TOOLS_CORE_DIR]: " QA_TOOLS_CORE_DIR
QA_TOOLS_CORE_DIR=${QA_TOOLS_CORE_DIR:-$DEFAULT_QA_TOOLS_CORE_DIR}

read -p "2️⃣  QA_TOOLS_DESIGNER_DIR [$DEFAULT_QA_TOOLS_DESIGNER_DIR]: " QA_TOOLS_DESIGNER_DIR
QA_TOOLS_DESIGNER_DIR=${QA_TOOLS_DESIGNER_DIR:-$DEFAULT_QA_TOOLS_DESIGNER_DIR}

read -p "3️⃣  QA_USE_CASES_DIR [$DEFAULT_QA_USE_CASES_DIR]: " QA_USE_CASES_DIR
QA_USE_CASES_DIR=${QA_USE_CASES_DIR:-$DEFAULT_QA_USE_CASES_DIR}

read -p "4️⃣  QA_TOOLS_BOARD_DIR [$DEFAULT_QA_TOOLS_BOARD_DIR]: " QA_TOOLS_BOARD_DIR
QA_TOOLS_BOARD_DIR=${QA_TOOLS_BOARD_DIR:-$DEFAULT_QA_TOOLS_BOARD_DIR}

read -p "5️⃣  OPENCLAW_WORKSPACE [$DEFAULT_WORKSPACE]: " WORKSPACE
WORKSPACE=${WORKSPACE:-$DEFAULT_WORKSPACE}

echo ""
echo "============================================================"
echo "📋 Discord webhook URLs (from Phase 1 setup)"
echo "============================================================"
echo ""
echo "💡 These should already be set in qa-tools-agentic-team/.env"
echo "   Copy them from there, or re-enter from Discord"
echo ""

read -p "6️⃣  DISCORD_WEBHOOK_QA_CORE URL: " WEBHOOK_QA_CORE
read -p "7️⃣  DISCORD_WEBHOOK_QA_WORK URL: " WEBHOOK_QA_WORK

echo ""
echo "============================================================"
echo "🔍 Validating paths..."
echo "============================================================"
echo ""

# Validate paths
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
        echo "  ⚠️  $name: $path (not found, will be created)"
        ((INVALID++))
        return 1
    fi
}

validate_path "$QA_TOOLS_CORE_DIR" "QA_TOOLS_CORE_DIR"
validate_path "$QA_TOOLS_DESIGNER_DIR" "QA_TOOLS_DESIGNER_DIR"
validate_path "$QA_USE_CASES_DIR" "QA_USE_CASES_DIR"
validate_path "$QA_TOOLS_BOARD_DIR" "QA_TOOLS_BOARD_DIR"

echo ""
echo "✅ Found: $VALID | ⚠️  Not found: $INVALID"
echo ""

if [ $INVALID -gt 0 ]; then
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
fi

echo "============================================================"
echo "📝 Creating .env file..."
echo "============================================================"
echo ""

# Create .env file
cat > "$SCRIPT_DIR/.env" << EOF
# qa-executor Environment Variables
#
# Created: $(date +%Y-%m-%d\ %H:%M:%S)
# Source: scripts/setup_env.sh
#
# This is the worker agent configuration for executing qa-tools operations

# qa-tools paths
QA_TOOLS_CORE_DIR=$QA_TOOLS_CORE_DIR
QA_TOOLS_DESIGNER_DIR=$QA_TOOLS_DESIGNER_DIR
QA_USE_CASES_DIR=$QA_USE_CASES_DIR
QA_TOOLS_BOARD_DIR=$QA_TOOLS_BOARD_DIR

# Discord webhook (for agent deployment)
DISCORD_WEBHOOK_QA_CORE=$WEBHOOK_QA_CORE
DISCORD_WEBHOOK_QA_WORK=$WEBHOOK_QA_WORK

# OpenClaw (if running as agent)
OPENCLAW_WORKSPACE=$WORKSPACE
OPENCLAW_AGENT_NAME=qa-executor
OPENCLAW_AGENT_ROLE=worker

# Default models
QA_TOOLS_DEFAULT_MODEL=openai:gpt-4o
QA_TOOLS_EVAL_MODEL=openai:gpt-4o

# Lake paths
QA_TOOLS_LAKE_DIR=$QA_TOOLS_CORE_DIR/lake
QA_TOOLS_ARTIFACTS_DIR=$QA_TOOLS_CORE_DIR/lake/artifacts
EOF

echo "✅ .env file created at: $SCRIPT_DIR/.env"
echo ""

# Show instructions for loading environment
echo "============================================================"
echo "🚀 Next Steps"
echo "============================================================"
echo ""
echo "1. Load environment variables:"
echo ""
echo "   cd ~/Src/qa-tools/qa-executor"
echo "   source .env"
echo ""
echo "2. Initialize OpenClaw agent:"
echo ""
echo "   openclaw agent init \\"
echo "     --name qa-executor \\"
echo "     --role worker \\"
echo "     --workspace $(pwd)"
echo ""
echo "3. Test agent:"
echo ""
echo "   openclaw agent start --name qa-executor --test"
echo ""
echo "4. (Optional) Add to ~/.zshrc for persistence:"
echo ""
echo "   echo 'source ~/Src/qa-tools/qa-executor/.env' >> ~/.zshrc"
echo ""
echo "============================================================"

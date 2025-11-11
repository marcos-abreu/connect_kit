#!/usr/bin/env bash
# SessionStart hook for using-skills

set -euo pipefail

# 1. Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CLAUDE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 2. Read content, redirecting any error message to stderr (> &2)
# The || echo "..." is a fallback in case the cat fails entirely.
using_skills_content=$(cat "${CLAUDE_ROOT}/skill-usage/SKILL.md" 2>&1 || echo "Error reading using-skills skill")

# 3. Inform the user/log that the script is running (output to STDERR)
echo "INFO: SessionStart hook running. Injecting using-skills content." >&2

# 4. JSON Escaping (Highly complex but necessary for reliable injection)
# This handles backslashes and double quotes in the skill content.
using_skills_escaped=$(echo "$using_skills_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# 5. Output the final, required JSON structure (output to STDOUT)
# All previous commands must have output only to stderr (> &2) or a file.
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have skills.\n\n**Below is the full content of your 'using-skills' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${using_skills_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0

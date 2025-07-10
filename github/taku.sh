#!/bin/bash
# Check if directory is a git repo and has a remote
echo "🔍 Scanning for secrets..."
if ! ggshield secret scan repo .; then
  echo "❌ Commit blocked: Secrets were detected in the repository"
  echo "Please remove any secrets before committing"
  exit 1
else
  echo "✅ No secrets detected"
  if git rev-parse --git-dir >/dev/null 2>&1 && git remote -v >/dev/null 2>&1; then
    echo "This is a git repo with a remote configured"
  else
    gh repo create --private --source=. --remote=origin
  fi
fi

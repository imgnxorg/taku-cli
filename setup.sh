#!/bin/bash
set -euo pipefail

# 1. Ensure dependencies are installed
if ! command -v yarn >/dev/null 2>&1; then
    echo "❌ yarn is not installed. Please install yarn and rerun this script."
    exit 1
fi
if ! command -v esbuild >/dev/null 2>&1; then
    echo "❌ esbuild is not installed. Installing locally..."
    yarn add --dev esbuild
fi

# 2. Clean dist directory
rm -rf dist
mkdir -p dist

# 3. Ensure main.sh is executable
chmod +x main.sh

# 4. Build CLI and parser with esbuild
npx esbuild cli.js --bundle --platform=node --outfile=dist/cli.js --format=esm --packages=external --banner:js='#!/usr/bin/env node'
npx esbuild src/taku.config.parse.js --bundle --platform=node --outfile=dist/taku.config.parse.js --format=esm --packages=external --banner:js='#!/usr/bin/env node'

# 5. Copy main.sh to dist
cp main.sh dist/main.sh

# 6. Remove pkg from dependencies if present
if grep -q '"pkg"' package.json; then
    yarn remove pkg || true
fi

# 7. Set bin entry to dist/cli.js in package.json
if grep -q '"bin"' package.json; then
    node -e '
import fs from "fs";
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
pkg.bin = { "taku": "./dist/cli.js" };
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
'
fi

# 8. Bump version (patch) before publish
echo -e "\n🔢 Bumping version (patch)..."
npm version patch --no-git-tag-version

# 9. Publish to npm (if authenticated)
echo -e "\n📦 Publishing to npm..."
if npm publish --access public; then
    echo -e "\n✅ Setup and publish complete! Run your CLI with: npx . init or yarn taku init"
else
    echo -e "\n❌ Publish failed. You may not be authenticated, have publish rights, or the version is already published."
    exit 1
fi

# 10. Print usage for initializing a project
cat <<EOF

To initialize a new project, run:

  npx gittaku init

Or, if you want to update an existing project, run:

  npx gittaku update

EOF

# Taku CLI (gittaku)

## Overview

Taku CLI is a project generator and utility for the Taku framework. It helps you scaffold, configure, and
manage Taku-based projects with a single command.

## Installation & Usage

You do not need to install globally. Use npx to run the CLI directly from npm:

```sh
npx gittaku init
```

This will:

- Download the latest published version of the CLI from npm.
- Run the `taku` binary defined in the `bin` field of `package.json` (which points to `./dist/cli.js`).
- Pass the `init` argument to your CLI, which should handle project initialization.

## CLI Commands

- `npx gittaku init` — Initialize a new Taku project interactively.
- `npx gittaku <command>` — Run other supported commands (see below or run with no arguments for help).

## Development

- Build the CLI: `yarn build`
- Run locally: `node dist/cli.js <command>`
- Publish: `npm publish --access public`

## How npx works

- `npx gittaku <command>` will always fetch the latest published version from npm.
- It uses the `bin` field in `package.json` to determine the executable.
- Arguments after the package name are passed to your CLI.

## Project Structure

- `cli.js` — Main CLI entry point (bundled to `dist/cli.js`)
- `main.sh` — Bash script invoked by the CLI
- `src/` — Additional CLI source files
- `dist/` — Build output
- `docs/` — Documentation (this folder)

## Troubleshooting

- If you see `No matching version found`, make sure the version in `package.json` is published to npm.
- If you see no output, ensure your CLI has top-level code and a shebang (`#!/usr/bin/env node`).
- For more, see [npm docs: npx](https://docs.npmjs.com/cli/v9/commands/npx) and
  [npm docs: bin field](https://docs.npmjs.com/cli/v9/configuring-npm/package-json#bin).

---

For more details, see the source or open an issue on [GitHub](https://github.com/imgnxorg/taku-cli).

#!/usr/bin/env node
const { spawn } = require("child_process");
const path = require("path");

const script = path.join(__dirname, "main.sh");
const args = process.argv.slice(2);

const child = spawn(script, args, { stdio: "inherit" });

child.on("exit", (code) => process.exit(code));

#!/usr/bin/env node
import { spawn, execSync } from "child_process";
import path from "path";

// Path to the bash script
const scriptPath = path.join(__dirname, "main.sh");

// Run the bash script synchronously
execSync(`bash ${scriptPath}`, { stdio: "inherit" });

// Run the bash script asynchronously with passed arguments
const args = process.argv.slice(2);
const child = spawn(scriptPath, args, { stdio: "inherit" });

child.on("exit", (code) => process.exit(code));

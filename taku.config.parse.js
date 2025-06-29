// taku.config.parse.js
const fs = require("fs");
const path = require("path");

const configPath = path.resolve("taku.config.js");
let config;
try {
  config = require(configPath).default || require(configPath);
} catch (e) {
  console.error("❌ Failed to parse taku.config.js:", e.message);
  process.exit(1);
}

const out = {
  FRONTEND_TYPE: config.frontend?.type || "",
  FRONTEND_BUILD_CMD: config.frontend?.buildCommand || "",
  BACKEND_TYPE: config.backend?.type || "",
  BACKEND_BUILD_CMD: config.backend?.buildCommand || "",
};

fs.writeFileSync(
  "taku.config.env",
  Object.entries(out)
    .map(([k, v]) => `${k}="${v}"`)
    .join("\n") + "\n"
);

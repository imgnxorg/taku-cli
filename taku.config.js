import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

process.stdout.write(`Taku ${__dirname}`);

export default {
  // Configuration options
  frontend: {
    type: "react",
    buildCommand: "yarn build",
    flags: {
      NODE_ENV: "production",
    },
  },
  backend: {
    type: "rust",
    buildCommand: "cargo build --release",
    featureFlags: {
      default: true,
    },
  },
};

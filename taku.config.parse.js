// taku.config.parse.js
import fs from "fs";
import path from "path";

(async () => {
  const configPath = path.resolve(process.cwd(), "taku.config.js");
  let config;
  try {
    const imported = await import(configPath + "?t=" + Date.now());
    config = imported.default || imported;
  } catch (e) {
    console.error("❌ Failed to parse taku.config.js as an ES module:", e.message);
    process.exit(1);
  }

  const out = {
    FRONTEND_TYPE: config.frontend?.type || "",
    FRONTEND_BUILD_CMD: config.frontend?.buildCommand || "",
    BACKEND_TYPE: config.backend?.type || "",
    BACKEND_BUILD_CMD: config.backend?.buildCommand || "",
  };

  const outputPath = process.argv[2] || "taku.config.env";
  const envUuid = process.env.TAKU_ENV_UUID || "";

  if (envUuid) {
    out.TAKU_ENV_UUID = envUuid;
  }

  try {
    fs.writeFileSync(
      outputPath,
      Object.entries(out)
        .map(([k, v]) => `${k}="${v}"`)
        .join("\n") + "\n"
    );
  } catch (err) {
    console.error(`❌ Failed to write config env file: ${outputPath}\n${err}`);
    process.exit(1);
  }
})();

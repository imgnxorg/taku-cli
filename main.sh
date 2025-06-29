#!/bin/bash
# shellcheck shell=bash

set -euo pipefail

# ---- Terminal Width Check & ASCII Art ----
MIN_WIDTH=50
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
if [[ "$TERM_WIDTH" -ge "$MIN_WIDTH" ]]; then
  cat <<EOF
                     .                    
                   .'|                    
   .|            .'  |                    
   .' |_     __   <    |                    
 .'     | .:--.'.  |   | ____      _    _   
'--.  .-'/ |   \ | |   | \ .'     | '  / |  
   |  |  \`" __ | | |   |/  .     .' | .' |  
   |  |   .'.''| | |    /\  \    /  | /  |  
   |  '.'/ /   | |_|   |  \  \  |   \`'.  |  
   |   / \ \._,\ '/'    \  \  \ '   .'|  '/ 
   \`'-'   \`--'  \`"'------'  '---'\`-'  \`--'  
EOF
fi

# ---- Usage & Argument Parsing ----
usage() {
  echo -e "\nUsage: $0 [-n project_name] [--frontend|--backend|--all]"
  echo -e "  -n project_name   Set the project name (default: taku-demo-app)"
  echo -e "  --frontend        Build only the frontend"
  echo -e "  --backend         Build only the backend"
  echo -e "  --all             Build both frontend and backend (default)"
  echo -e "  -h, --help        Show this help message\n"
  exit 1
}

PROJECT_NAME="taku-demo-app"
BUILD_TARGET="all"

while [[ $# -gt 0 ]]; do
  case $1 in
  -n)
    if [[ -z "${2:-}" ]]; then
      echo "Error: -n requires a project name argument."
      usage
    fi
    PROJECT_NAME="$2"
    shift 2
    ;;
  --frontend)
    BUILD_TARGET="frontend"
    shift
    ;;
  --backend)
    BUILD_TARGET="backend"
    shift
    ;;
  --all)
    # shellcheck disable=SC2034
    BUILD_TARGET="all"
    shift
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Unknown argument: $1"
    usage
    ;;
  esac
done

FRAMEWORK_NAME="Taku"
DEMO_NAME="timbre-tool-demo"

# ---- Tool Checks ----
for tool in cargo yarn; do
  if ! command -v $tool >/dev/null 2>&1; then
    echo "❌ Required tool '$tool' is not installed. Please install it and try again."
    exit 1
  fi
done

# ---- Project Directory Check ----
if [ -d "$PROJECT_NAME" ]; then
  echo "❌ Directory '$PROJECT_NAME' already exists. Please choose a different project name or remove the directory."
  exit 1
fi

# ---- Create Project Structure ----
echo "📁 Creating $FRAMEWORK_NAME project structure..."
mkdir -p "$PROJECT_NAME"/frontend/src
mkdir -p "$PROJECT_NAME"/frontend/public
mkdir -p "$PROJECT_NAME"/src
mkdir -p "$PROJECT_NAME"/assets
mkdir -p "$PROJECT_NAME"/examples/$DEMO_NAME
cd "$PROJECT_NAME" || exit

# ---- Initialize Rust Project ----
echo "🦀 Initializing Rust backend..."
cargo init --name taku

# ---- Framework Cargo.toml ----
echo "⚙️ Setting up Rust dependencies..."
cat <<EOF >Cargo.toml
[package]
name = "taku"
version = "0.1.0"
edition = "2021"

[dependencies]
rusqlite = { version = "0.31", features = ["bundled"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.0", features = ["full"] }
tao = "0.26"
wry = "0.37"
tauri-utils = "1.5"

[[bin]]
name = "taku"
path = "src/main.rs"
EOF

# ---- Core Framework: Database Service ----
echo "🗄️ Creating Taku database service..."
cat <<EOF >src/database.rs
// Taku Framework: Database Service
use rusqlite::{params, Connection, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct AudioFile {
    pub id: i32,
    pub path: String,
    pub name: String,
    pub sample_rate: i32,
    pub duration: f64,
    pub channels: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Transform {
    pub id: i32,
    pub file_id: i32,
    pub transform_type: String,
    pub parameters: Option<String>,
    pub timestamp: String,
}

pub struct DatabaseService {
    conn: Connection,
}

impl DatabaseService {
    pub fn new(db_path: &str) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        Ok(DatabaseService { conn })
    }

    pub fn init_schema(&self) -> Result<()> {
        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS audio_files (
                id INTEGER PRIMARY KEY,
                path TEXT NOT NULL,
                name TEXT NOT NULL,
                sample_rate INTEGER NOT NULL,
                duration REAL NOT NULL,
                channels INTEGER NOT NULL
            )",
            [],
        )?;
        self.conn.execute(
            "CREATE TABLE IF NOT EXISTS transforms (
                id INTEGER PRIMARY KEY,
                file_id INTEGER NOT NULL,
                type TEXT NOT NULL,
                parameters TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (file_id) REFERENCES audio_files (id)
            )",
            [],
        )?;
        Ok(())
    }

    pub fn get_all_audio_files(&self) -> Result<Vec<AudioFile>> {
        let mut stmt = self.conn.prepare("SELECT id, path, name, sample_rate, duration, channels FROM audio_files")?;
        let file_iter = stmt.query_map([], |row| {
            Ok(AudioFile {
                id: row.get(0)?,
                path: row.get(1)?,
                name: row.get(2)?,
                sample_rate: row.get(3)?,
                duration: row.get(4)?,
                channels: row.get(5)?,
            })
        })?;

        let mut files = Vec::new();
        for file in file_iter {
            files.push(file?);
        }
        Ok(files)
    }

    pub fn add_audio_file(&self, file: &AudioFile) -> Result<i32> {
        self.conn.execute(
            "INSERT INTO audio_files (path, name, sample_rate, duration, channels) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![file.path, file.name, file.sample_rate, file.duration, file.channels],
        )?;
        Ok(self.conn.last_insert_rowid() as i32)
    }

    pub fn add_transform(&self, transform: &Transform) -> Result<i32> {
        self.conn.execute(
            "INSERT INTO transforms (file_id, type, parameters) VALUES (?1, ?2, ?3)",
            params![transform.file_id, transform.transform_type, transform.parameters],
        )?;
        Ok(self.conn.last_insert_rowid() as i32)
    }
}
EOF

# ---- Core Framework: Tao/Wry Main ----
echo "🖥️ Creating Taku Tao/Wry main app..."
cat <<EOF >src/main.rs
// Taku Framework: Main Application
mod database;

use database::DatabaseService;
use tao::{
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::WindowBuilder,
};
use wry::WebViewBuilder;

fn main() -> wry::Result<()> {
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title("Taku Demo App")
        .build(&event_loop)
        .unwrap();

    // Initialize database
    let db = DatabaseService::new("./taku.db").expect("Failed to open database");
    db.init_schema().expect("Failed to initialize database schema");

    let _webview = WebViewBuilder::new(window)?
        .with_url("file://frontend/dist/index.html")?
        .with_ipc_handler(|window, req| {
            println!("IPC Request: {}", req);
            // Minimal IPC echo example:
            if req == "ping" {
                let _ = window.evaluate_script("window.dispatchEvent(new CustomEvent('pong', { detail: 'Hello from Rust!' }))");
            }
        })
        .build()?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;
        match event {
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => (),
        }
    });
}
EOF

# ---- Taku Init Command ----
if [[ "$1" == "init" ]]; then
  CONFIG_URL="https://raw.githubusercontent.com/imgnxorg/taku/main/export/taku.config.zip"
  CONFIG_ZIP="taku.config.zip"
  # shellcheck disable=SC2034
  CONFIG_DEST="taku.config.js"

  echo "🌐 Downloading Taku config from downstream..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$CONFIG_URL" -o "$CONFIG_ZIP"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$CONFIG_URL" -O "$CONFIG_ZIP"
  else
    echo "❌ Neither curl nor wget is installed. Cannot download config."
    exit 1
  fi

  if command -v unzip >/dev/null 2>&1; then
    unzip -o "$CONFIG_ZIP" -d .
    echo "✅ Imported taku.config.js from downstream."
    rm -f "$CONFIG_ZIP"
  else
    echo "❌ unzip is not installed. Cannot extract config."
    exit 1
  fi
  exit 0
fi

# ---- Download and Import Taku Frame Config ----
CONFIG_URL="https://raw.githubusercontent.com/imgnxorg/taku/main/taku-frame/export/taku.config.zip"
CONFIG_ZIP="taku.config.zip"
# shellcheck disable=SC2034
CONFIG_DEST="taku.config.js"

# Download the latest config zip from GitHub
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$CONFIG_URL" -o "$CONFIG_ZIP"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$CONFIG_URL" -O "$CONFIG_ZIP"
else
  echo "❌ Neither curl nor wget is installed. Cannot download config."
  exit 1
fi

# Unzip the config file
if command -v unzip >/dev/null 2>&1; then
  unzip -o "$CONFIG_ZIP" -d .
  echo "✅ Imported taku.config.js from frame."
  rm -f "$CONFIG_ZIP"
else
  echo "❌ unzip is not installed. Cannot extract config."
  exit 1
fi

# ---- Frontend: Framework + Demo ----
echo "📦 Setting up frontend (React+Tailwind)..."
cat <<EOF >frontend/package.json
{
  "name": "taku-frontend",
  "version": "0.1.0",
  "scripts": {
    "dev": "webpack-dev-server --mode=development --open",
    "build": "webpack --mode=production --node-env=production",
    "build:dev": "webpack --mode=development",
    "watch": "webpack --watch",
    "serve": "webpack serve"
  },
  "dependencies": {
    "react": "18",
    "react-dom": "18"
  },
  "devDependencies": {
    "@babel/core": "^7.27.4",
    "@babel/preset-env": "^7.27.2",
    "@babel/preset-react": "^7.27.1",
    "@radix-ui/colors": "^3.0.0",
    "@tailwindcss/postcss": "^4.1.8",
    "autoprefixer": "^10.4.21",
    "babel-loader": "^10.0.0",
    "css-loader": "^7.1.2",
    "html-webpack-plugin": "^5.6.3",
    "mini-css-extract-plugin": "^2.9.2",
    "postcss": "^8.5.4",
    "postcss-loader": "^8.1.1",
    "style-loader": "^4.0.0",
    "tailwindcss": "^4.1.8",
    "webpack": "^5.99.9",
    "webpack-cli": "^6.0.1",
    "webpack-dev-server": "^5.2.2"
  },
  "packageManager": "yarn@1.22.22+sha512.a6b2f7906b721bba3d67d4aff083df04dad64c399707841b7acf00f6b133b7ac24255f2652fa22ae3534329dc6180534e98d17432037ff6fd140556e2bb3137e"
}
EOF

# ---- TailwindCSS Configuration ----
echo "🎨 Setting up TailwindCSS configuration..."
cat <<EOF >frontend/tailwind.config.js
/** @type {import('tailwindcss').Config} */
const { mauve, mauveDark, violet, violetDark } = require("@radix-ui/colors");

module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx,html}", "./public/index.html"],
  theme: {
    extend: {
      colors: {
        mauve: { ...mauve },
        mauveDark: { ...mauveDark },
        violet: { ...violet },
        violetDark: { ...violetDark },
      },
    },
  },
  plugins: [],
};
EOF

# ---- PostCSS Configuration ----
echo "⚙️ Setting up PostCSS configuration..."
cat <<EOF >frontend/postcss.config.mjs
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
EOF

# ---- Webpack Configuration ----
echo "📦 Setting up Webpack configuration..."
cat <<EOF >frontend/webpack.config.js
// Generated using webpack-cli https://github.com/webpack/webpack-cli

const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

const isProduction = process.env.NODE_ENV === "production";

const stylesHandler = MiniCssExtractPlugin.loader;

const config = {
  entry: "./src/index.jsx",
  output: {
    path: path.resolve(__dirname, "dist"),
  },
  devServer: {
    open: true,
    host: "localhost",
    historyApiFallback: true, // 🔥 This tells dev server to serve index.html for all routes
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: "public/index.html",
    }),

    new MiniCssExtractPlugin(),

    // Add your plugins here
    // Learn more about plugins from https://webpack.js.org/configuration/plugins/
  ],
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["@babel/preset-env", "@babel/preset-react"],
          },
        },
      },
      {
        test: /\.css$/i,
        use: [isProduction ? MiniCssExtractPlugin.loader : "style-loader", "css-loader", "postcss-loader"],
      },
      {
        test: /\.(eot|svg|ttf|woff|woff2|png|jpg|gif)$/i,
        type: "asset",
      },

      // Add your rules for custom modules here
      // Learn more about loaders from https://webpack.js.org/loaders/
    ],
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src/"),
    },
    extensions: [".jsx", ".js", ".tsx", ".ts", ".json"],
  },
};

module.exports = () => {
  if (isProduction) {
    config.mode = "production";
  } else {
    config.mode = "development";
  }
  return config;
};
EOF

# ---- Frontend HTML Template ----
echo "📄 Setting up HTML template..."
cat <<EOF >frontend/public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Taku Frontend</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>
EOF

# ---- Frontend Entry Point ----
echo "⚡ Setting up React entry point..."
cat <<EOF >frontend/src/index.jsx
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import './styles/global.css';

const container = document.getElementById('root');
const root = createRoot(container);
root.render(<App />);
EOF

# ---- Global CSS with Tailwind ----
echo "🎨 Setting up global CSS..."
mkdir -p frontend/src/styles
cat <<EOF >frontend/src/styles/global.css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

/* Custom global styles */
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF

# ---- Demo App: Timbre Tool (React) ----
echo "🎹 Adding timbre tool demo (example app)..."
cat <<EOF >frontend/src/App.jsx
// Taku Example: Timbre Tool Demo with IPC Example
import React, { useEffect } from 'react';

export default function App() {
  useEffect(() => {
    // Send a ping to backend via IPC
    if (window.ipc) {
      window.ipc.postMessage('ping');
    } else if (window.external && window.external.invoke) {
      window.external.invoke('ping');
    }
    // Listen for pong from backend
    const handler = (e) => {
      if (e.type === 'pong') {
        alert('Received from backend: ' + e.detail);
      }
    };
    window.addEventListener('pong', handler);
    return () => window.removeEventListener('pong', handler);
  }, []);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-gray-900 to-black">
      <h1 className="text-4xl font-bold mb-8 text-center bg-gradient-to-r from-blue-400 to-purple-600 bg-clip-text text-transparent">
        Taku Demo: Timbre Tool
      </h1>
      <p className="text-gray-300 mb-4">This is a demo app built with the Taku framework. Replace this with your own app!</p>
      <button
        className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        onClick={() => {
          if (window.ipc) {
            window.ipc.postMessage('ping');
          } else if (window.external && window.external.invoke) {
            window.external.invoke('ping');
          }
        }}
      >
        Send Ping to Backend
      </button>
    </div>
  );
}
EOF

# ---- Build Script ----
echo "🔨 Creating build script..."
cat <<'EOF' >build.sh
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

usage() {
  echo "Usage: $0 [name1 name2 ...]"
  echo "  Each name will be checked as src/<name>."
  echo "  If src/<name>/package.json exists, builds as frontend."
  echo "  If src/<name>/Cargo.toml exists, builds as backend."
  echo "  If no argument is given, builds all subdirectories in src/."
  exit 1
}

if [[ "$#" -eq 0 ]]; then
  # No args: build all subdirs in src
  for dir in src/*; do
    [[ -d "$dir" ]] || continue
    name="${dir##*/}"
    "$0" "$name"
  done
  exit 0
fi

for name in "$@"; do
  dir="src/$name"
  if [[ ! -d "$dir" ]]; then
    echo "⚠️ Directory '$dir' not found, skipping."
    continue
  fi
  built=false
  if [[ -f "$dir/package.json" ]]; then
    echo "🔧 Installing frontend dependencies in $dir..."
    (cd "$dir" && yarn install)
    echo "🛠️ Building frontend in $dir..."
    (cd "$dir" && yarn build)
    echo "✅ Frontend build complete in $dir."
    built=true
  fi
  if [[ -f "$dir/Cargo.toml" ]]; then
    echo "📦 Building Rust backend in $dir..."
    (cd "$dir" && cargo build --release)
    echo "✅ Backend build complete in $dir."
    built=true
  fi
  if ! $built; then
    echo "⚠️ No buildable frontend or backend found in '$dir', skipping."
  fi
  if [[ "$name" == "-h" || "$name" == "--help" ]]; then
    usage
  fi
done

# ---- macOS .app Bundling (Optional) ----
echo "🍏 macOS .app bundling instructions:"
echo "# To bundle as a macOS .app, add your bundling logic here."
echo "# You may use tools like cargo-bundle, create-dmg, or custom scripts."
echo "# See: https://github.com/burtonageo/cargo-bundle or Tauri docs for more info."
EOF

chmod +x build.sh

echo "✅ Taku setup complete!"
echo ""
echo "Next steps:"
echo "1. cd ${PROJECT_NAME}"
echo "2. ./build.sh"
echo ""
echo "Taku is ready. Replace the timbre tool demo with your own app!"

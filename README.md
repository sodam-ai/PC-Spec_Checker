# PC Spec Checker v3.0

**One double-click to see everything about your PC.**

No installation. No coding. No technical knowledge needed.
Just download one file, double-click it, and instantly see your full PC specs.

> [Korean version (한국어 버전)](./README.ko.md)

---

## What Is This?

PC Spec Checker is a single `.bat` file that scans your Windows PC and shows you:

- What CPU, RAM, GPU, and storage you have
- How healthy your disk drives are
- What software and developer tools are installed
- A **score out of 100** rating your PC's development readiness

Think of it as a **free, instant health checkup for your computer**.

---

## Who Is This For?

- Anyone who wants to know their PC specs without downloading heavy software
- People buying/selling a used PC who want a quick spec summary
- Beginners learning to code who want to check if their PC is ready
- Anyone who uses AI tools (like ChatGPT, Claude, Cursor) to write code and wants to verify their setup
- IT support helping someone remotely ("just run this file and tell me what you see")

---

## How to Use (3 Steps)

### Step 1: Download

Click the green **"Code"** button on this GitHub page, then click **"Download ZIP"**.

![download](https://img.shields.io/badge/Step_1-Download_ZIP-brightgreen?style=for-the-badge)

Unzip (extract) the downloaded file anywhere on your PC.

### Step 2: Run

Find the file called **`PC-Spec_Checker.bat`** and **double-click** it.

![run](https://img.shields.io/badge/Step_2-Double_Click-blue?style=for-the-badge)

> **Windows may show a security warning** like "Windows protected your PC". This is normal for `.bat` files downloaded from the internet.
>
> Click **"More info"** then **"Run anyway"**.
>
> This file is 100% open source - you can read every line of code yourself.

### Step 3: Choose What to Check

A menu will appear. Type a number and press Enter.

![menu](https://img.shields.io/badge/Step_3-Pick_a_Number-orange?style=for-the-badge)

**Recommended: Type `1` and press Enter** to run a full scan of everything.

That's it. No installation. No account. No internet required.

---

## What Can It Check? (15 Categories)

| # | Category | What You'll See |
|---|----------|----------------|
| 1 | **Show ALL** | Full scan of everything below |
| 2 | **Basic Info** | PC name, Windows version, motherboard, BIOS |
| 3 | **CPU** | Processor name, cores, speed, temperature |
| 4 | **RAM** | Total memory, each stick's size/type/speed |
| 5 | **Disk** | SSD/HDD type, health status, free space |
| 6 | **GPU** | Graphics card, VRAM, driver version |
| 7 | **Network + Display** | IP address, internet speed, monitors |
| 8 | **Battery** | Charge level, battery health (laptops) |
| 9 | **Security** | Antivirus, firewall, UAC status |
| 10 | **Startup Programs** | Apps that run when your PC boots |
| 11 | **Audio / USB / Bluetooth** | Connected devices |
| 12 | **Installed Apps** | Browsers, office, media, utilities |
| 13 | **Dev Tools** | 120+ developer tools deep scan |
| 14 | **WSL** | Windows Subsystem for Linux status |
| 15 | **Score** | PC rating out of 100 + recommendations |

---

## The Score System

Your PC gets rated out of **100 points** across 5 categories:

| Category | Max Points | What's Measured |
|----------|-----------|-----------------|
| CPU | 20 | Core count (8+ = full marks) |
| RAM | 20 | Total memory (32GB+ = full marks) |
| Storage | 15 | SSD/NVMe type + free space |
| GPU | 10 | Dedicated GPU + VRAM size |
| Dev Tools | 35 | Essential tools installed |

### Grades

| Score | Grade | Meaning |
|-------|-------|---------|
| 85-100 | **S** | Excellent dev machine |
| 70-84 | **A** | Great setup |
| 55-69 | **B** | Decent, room to improve |
| 40-54 | **C** | Needs improvement |
| 0-39 | **D** | Consider upgrading |

After scoring, you'll see specific **recommendations** for what to improve.

---

## Dev Tools Deep Scan (120+ Tools)

This is the most comprehensive section. It checks for tools across **17 categories**:

| Category | Examples |
|----------|---------|
| Runtime / Language | Python, Node.js, Bun, Deno, Go, Rust, Java, .NET, PHP, Ruby, and 15+ more |
| Node Version Manager | nvm, fnm, Volta |
| Python Tools | pip, uv, poetry, pipenv, ruff, mypy, black, Conda, pyenv |
| Package Manager | npm, pnpm, yarn, Cargo, Composer, Chocolatey, Scoop, winget |
| Version Control | Git, GitHub CLI, Git LFS, GitLab CLI |
| Editor / IDE | VS Code, Cursor, Windsurf, Zed, Visual Studio, IntelliJ, WebStorm, PyCharm, Vim, Neovim, and more |
| AI Coding Tools | Claude Code, Gemini CLI, GitHub Copilot, OpenAI CLI, Codex CLI, Aider, Cody |
| Container / Infra | Docker, Podman, kubectl, Helm, Terraform, Vagrant |
| Cloud CLI | AWS, Azure, Google Cloud, Vercel, Netlify, Cloudflare, Fly.io, Railway, Heroku |
| Database | MySQL, PostgreSQL, SQLite, Redis, MongoDB, DBeaver, pgAdmin, TablePlus |
| Build / Bundler | Make, CMake, Gradle, Maven, Flutter, Vite, Webpack, esbuild, Turborepo |
| Linter / Testing | ESLint, Prettier, Biome, Jest, Vitest, Playwright, Cypress, pytest |
| Network / API | curl, wget, httpie, jq, fzf, ripgrep, ngrok, Postman, Bruno |
| Shell / Terminal | PowerShell 7, Windows Terminal, Warp, Alacritty, starship, oh-my-posh |
| Design / Collab | Figma, Slack, Discord, Notion, Obsidian |
| Security / Crypto | OpenSSL, SSH, GPG, age, sops |
| Media / Misc | FFmpeg, ImageMagick, Pandoc, Hugo, LaTeX, Graphviz |

**How detection works:** For each tool, the scanner checks:
1. Your system PATH (the normal way)
2. Common installation folders (30+ known paths per tool)
3. Windows Registry (for GUI apps)

This means it finds tools **even if they're not in your PATH**.

---

## Frequently Asked Questions

### Is this safe to run?

Yes. This file:
- Does NOT install anything
- Does NOT change any settings
- Does NOT send data anywhere
- Does NOT require internet
- Only READS information from your PC

The entire source code is visible in the `.bat` file. Open it with Notepad to verify.

### Does it need administrator rights?

No. It runs without admin rights. Some features (like CPU temperature) may show "N/A" without admin, but everything else works fine.

### Does it work on Windows 10?

Yes. It works on Windows 10 and Windows 11.

### Does it work on Mac or Linux?

No. This is a Windows-only tool that uses PowerShell and WMI.

### The scan is slow

The "Show ALL" scan checks 120+ tools and queries many hardware sensors. It may take 30-60 seconds on some PCs. Individual menu items are much faster.

### A tool I have installed shows as "not installed"

The scanner checks common installation paths. If you installed a tool in a custom location that's not in your PATH, it might not be detected. Adding the tool to your system PATH will fix this.

### What does "found in PATH" mean?

It means the tool was detected in your system's PATH environment variable but the version couldn't be determined. The tool is installed and working.

---

## Example Output

```
  ====================================================
        PC Spec Checker  v3.0
        Deep Hardware + Dev Tool Scanner
  ====================================================

    [ AI Coding Tools ]
    [O] Claude Code            : 2.1.80 (Claude Code)
    [O] Gemini CLI             : 0.33.0
    [O] OpenAI CLI             : openai 2.15.0
    [O] Codex CLI              : codex-cli 0.114.0
    [X] Aider                  : not installed

    ================================================
    TOTAL : 93 / 100  (Grade: S)
    ================================================
    >> Excellent dev machine!
```

---

## Changelog

### v3.0 (Current)
- Expanded from 9 to 15 menu categories
- Dev tools scan expanded from ~50 to **120+ tools** across 17 subcategories
- Added: Battery/Power, Security Status, Startup Programs, Audio/USB/Bluetooth, Installed Apps
- Added: Node version managers, Python ecosystem tools, AI coding tools, Cloud CLIs, Linters/Formatters
- Score system upgraded: 5 categories (was 3) + letter grades (S/A/B/C/D) + weakness analysis
- Improved error handling for tools that output unexpected formats
- Better wildcard path resolution for version-specific install directories

### v2.2
- Deep detection engine (PATH + known paths + registry)
- 50+ dev tools
- Score system (100 points, 3 categories)

---

## License

SoDam AI Studio

---

## Contributing

Found a tool that's not detected? Know a common install path that's missing?

Open an [Issue](../../issues) or [Pull Request](../../pulls) - contributions welcome!

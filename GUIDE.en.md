# pc-spec_checker-kit — Complete Beginner's Guide (English)

> Made so that even people using a computer, smartphone, AI, or messenger app
> **for the very first time** can do everything by themselves with just this one document.
> If you see a word you don't know, check **[18. Glossary](#18-glossary-plain-language)** at the bottom.

> 🌐 한국어 버전: [GUIDE.md](./GUIDE.md)

---

## Table of Contents

1. [What is this? (one-line summary)](#1-what-is-this-one-line-summary)
2. [Explained simply](#2-explained-simply)
3. [Who is this for?](#3-who-is-this-for)
4. [Prerequisites / Required programs](#4-prerequisites--required-programs)
5. [How to download](#5-how-to-download)
6. [How to install](#6-how-to-install-nothing-to-install)
7. [Quick start (3 steps)](#7-quick-start-3-steps)
8. [How to run (in detail)](#8-how-to-run-in-detail)
9. [How to use — every menu item 0–15](#9-how-to-use--every-menu-item-015)
10. [How it works (under the hood)](#10-how-it-works-under-the-hood)
11. [How to read the results](#11-how-to-read-the-results)
12. [The score system in detail](#12-the-score-system-in-detail)
13. [Workflow (full flow diagram)](#13-workflow-full-flow-diagram)
14. [Commands](#14-commands)
15. [File locations / Document locations](#15-file-locations--document-locations)
16. [Troubleshooting / Error handling](#16-troubleshooting--error-handling)
17. [Frequently Asked Questions (FAQ)](#17-frequently-asked-questions-faq)
18. [Glossary (plain language)](#18-glossary-plain-language)
19. [For people who code with AI](#19-for-people-who-code-with-ai)
20. [Safety / Privacy](#20-safety--privacy)
21. [License / Copyright / Commercial use](#21-license--copyright--commercial-use)
22. [Key features](#22-key-features)
23. [How to contribute](#23-how-to-contribute)
24. [Contact / Support](#24-contact--support)

---

## 1. What is this? (one-line summary)

**Double-click one file and it instantly shows you everything about your PC's specs — for free.**

- No installation · No sign-up · Works without internet · Never sends your data anywhere
- It only **reads** your PC. It does not change or delete anything.

---

## 2. Explained simply

Think of a **medical checkup** at a hospital.
This tool is a **free health checkup for your computer**.

When you double-click it, the computer inspects its own parts and tells you:

- 🧠 What **CPU** (the brain) you have and how fast it is
- 💾 How much **RAM** (work space) you have
- 🗄️ What **storage** (SSD/HDD) you have, how full it is, and whether it's healthy
- 🎮 What **graphics card (GPU)** you have
- 🔋 **Battery** health (if it's a laptop)
- 🛡️ Security status such as **antivirus and firewall**
- 🧰 The **programs and developer tools** installed (auto-checks up to 193 tools)
- 🏆 Finally, a **score out of 100** rating how ready your PC is for development (coding)

> 💡 You don't need to care about "development" or "coding."
> It's also very useful just for checking **basic specs** like CPU, RAM, storage, and GPU.

---

## 3. Who is this for?

| If you are... | You can use it to... |
|---|---|
| **Anyone curious about their PC specs** | Check instantly without installing heavy software |
| **Someone buying/selling a used PC** | Summarize the specs on one page |
| **Someone not familiar with computers** | Just say "double-click this file" — done |
| **A coding beginner** | See if your PC is ready and what to install next |
| **People coding with AI** (ChatGPT, Claude, Cursor, etc.) | Verify your dev environment is set up |
| **IT support staff** | Tell a remote person "run this file and tell me what you see" |

---

## 4. Prerequisites / Required programs

**You need to prepare almost nothing.** Just confirm the following.

| Item | Required? | Notes |
|---|---|---|
| **Windows 10 or 11** | ✅ Required | This tool is **Windows only**. |
| **PowerShell** | ✅ Required but **already installed** | Built into Windows. No separate install needed. |
| Internet connection | 🔵 Optional | Works without it. With it, you also see an "internet response time" item. |
| Administrator rights | 🔵 Optional | Works without them. Only a few items (like CPU temperature) show `N/A`. |
| Installing extra programs | ❌ Not needed | You do **not** need to install antivirus, drivers, runtimes, etc. |

> ❗ **It does NOT work on Mac or Linux.** Use it only on a Windows computer.
> Check your Windows version: press `Windows key + R` → type `winver` → Enter.

---

## 5. How to download

This tool is just **one** file: **`pc-spec_checker-kit.bat`**.
There are two ways to get it.

### Method A — Get everything from GitHub (recommended)

1. In a web browser (Chrome, Edge, etc.), open the project's GitHub page:
   `https://github.com/sodam-ai/pc-spec_checker-kit`
2. Click the green **`< > Code`** button.
3. In the menu, click **`Download ZIP`** at the bottom.
4. A zip file like `pc-spec_checker-kit-main.zip` is usually saved to your **`Downloads`** folder.

### Method B — Get just the one file

If you only received `pc-spec_checker-kit.bat`, that single file works completely on its own.
(No other files are required.)

> 💡 Can't find the downloaded file? → See [15. File locations](#15-file-locations--document-locations).

---

## 6. How to install (nothing to install)

**This tool has no "installation" step.** Just extract it and use it.

1. Find the downloaded ZIP file. (Usually in the `Downloads` folder.)
2. **Right-click** the ZIP file → **`Extract All`** (or `압축 풀기`).
3. Inside the extracted folder you'll find **`pc-spec_checker-kit.bat`**.

> ✅ **Recommended location**: put it somewhere you can easily find, like your `Desktop` or `Documents`.
> ⚠️ **Avoid**: running it directly from inside the ZIP without extracting — it can behave unreliably.
> Always **extract first**, then run.

---

## 7. Quick start (3 steps)

The fastest way to see results.

1. **Double-click** the **`pc-spec_checker-kit.bat`** file.
2. (If a security warning appears) click **`More info`** → **`Run anyway`**. → details in [section 8](#8-how-to-run-in-detail)
3. When the menu appears in the black window, press **`1`** and **Enter** → all specs appear at once.

> That's it! After viewing, press **Enter** to return to the menu, and press **`0`** to quit.

---

## 8. How to run (in detail)

### 8-1. Basic run (double-click)

**Double-click** the `pc-spec_checker-kit.bat` file with your mouse.
A black command window opens and shows the menu.

### 8-2. When Windows shows a security warning (this is normal)

The first time you run a `.bat` file downloaded from the internet, Windows may show a warning for safety.

- If a blue window saying **"Windows protected your PC"** appears:
  1. Click **`More info`**.
  2. Click the **`Run anyway`** button that appears below.

> 🔒 **Why is it safe?** This file is **100% open source**.
> Open `pc-spec_checker-kit.bat` with **Notepad** and you can read every line of code yourself.
> The tool only **reads** your PC info — it does not install, change, or send anything. ([20. Safety](#20-safety--privacy))

### 8-3. Other ways to run

- You can also **right-click → `Open`** to run it.
- **Run as administrator**: right-click the file → **`Run as administrator`**.
  → This may reveal a few extra items (like CPU temperature) instead of `N/A`. (Not required.)

### 8-4. If you want to save the results to a file (optional)

This tool does not create files by itself. To save the results:

- **Option 1 (easiest)**: In the black window, drag-select the text and copy it (`Ctrl+C` or right-click), then paste (`Ctrl+V`) into Notepad.
- **Option 2 (run by command)**: see "Save results to a text file" in [14. Commands](#14-commands).

---

## 9. How to use — every menu item 0–15

When you run the tool, the menu below appears.
**Type the number of the item you want and press Enter.**

> If it's your first time, just choose **`1` (Full Scan)**.

| No. | Menu name | What it shows |
|---|---|---|
| **1** | **Show ALL (Full Scan)** ⭐recommended | Scans items 2–15 below **all at once** |
| 2 | Basic Info + Motherboard + BIOS | PC name, user, Windows edition/version/build, install date, uptime, Windows activation, latest update, motherboard maker/model, BIOS info |
| 3 | CPU (detailed) | Processor name/maker, core/thread count, clock speed, cache, 32/64-bit·ARM, virtualization support, **CPU temperature** (with admin), live usage bar |
| 4 | RAM (each stick) | Total/used/free memory, **per stick (slot)**: capacity, type (DDR4/DDR5, etc.), speed, maker, part number, slots used |
| 5 | Disk (type + health) | Storage model/capacity, **SSD/HDD/NVMe type**, **health status** (Healthy/Warning/Unhealthy), disk temperature, per-drive (C:, D:) total/used/free bar |
| 6 | GPU (detailed) | Graphics card name/status, dedicated memory (VRAM), current resolution/refresh rate (Hz)/color depth, driver version/date, GPU temperature (if sensor present) |
| 7 | Network + Display | Network adapter info, **IP address**, MAC address, gateway, DNS, **internet response time** (one ping to 8.8.8.8), connected **monitor** name/maker |
| 8 | Battery / Power | (Laptop) battery name/status, **charge %**, time left, **current vs design capacity (battery health %)**, charge state / (Desktop) "No battery" + power plan name |
| 9 | Security Status | **Antivirus** name/active, **firewall** (Domain/Private/Public) on/off, **UAC** on/off, C: drive **BitLocker (encryption)** status |
| 10 | Startup Programs | Programs that **launch automatically when you turn on the PC** (registry, Startup folder, scheduled tasks), total count (too many can slow boot) |
| 11 | Audio / USB / Bluetooth | Sound devices, USB controllers, **connected USB devices**, Bluetooth devices |
| 12 | Installed Apps | Installed programs organized into **8 categories** (browsers, office, communication, media, graphics, cloud, security, utilities) + versions |
| 13 | **Dev Tools (deep scan)** 🟡 | Checks **193 tools** in **17 categories** (Python, Node.js, Git, Docker, VS Code, AI coding tools, etc.). Shows versions if installed |
| 14 | WSL (Linux on Windows) | Whether WSL is installed, version, installed Linux distros, and whether key tools (python, node, etc.) exist inside Linux |
| 15 | **Score + Recommendations** 🏆 | Rates your PC **out of 100** (grades S/A/B/C/D) + **weaknesses and recommendations** |
| **0** | **Exit** | Closes the tool |

### Usage flow

1. Type a number (e.g. `1`) → **Enter**
2. Results appear (a full scan can take 30–60 seconds)
3. When done, press **Enter** → back to the menu
4. Pick another item, or press **`0`** to quit

> 💡 One run lets you keep picking items. You don't need to double-click again each time.

---

## 10. How it works (under the hood)

A simple explanation of how it **safely reads info only**.

1. **It only reads.** Using features already built into Windows (below), it simply **asks the computer "what are your specs?" and prints the answers** to the screen.
   - **WMI / CIM**: Windows' official store of its own hardware info. CPU, RAM, disk, etc. are queried from here.
   - **Registry (read-only)**: It **only reads** the list of installed programs, startup items, etc. It never edits them.
2. **It finds dev tools in 3 steps.** (So it can detect tools even if they're not on your PATH.)
   1. **PATH search** — finds the tool in registered paths and asks for its version
   2. **Known install paths** — checks dozens of folders where each tool is commonly installed (version-specific folders are found with wildcards)
   3. **Registry** — for programs with a window (GUI), it checks the installed list
3. **It touches the internet only once.** When you run item 7 (Network) or item 1 (Full Scan), it sends **one ping to Google's public address `8.8.8.8`** to check if the internet works. It **only checks for a response — it does not send your data**. With no internet, this item is simply skipped.
4. **It does not create files.** No temp files, logs, or reports are saved. All results show only in the window.
5. **It does not change settings.** No installing, deleting, or changing settings at all.

> Summary: **No install · No changes · No saving · No external transfer. Only read and show.**

---

## 11. How to read the results

The meaning of the symbols and colors on screen.

| Symbol | Meaning |
|---|---|
| `[O]` (green) | That tool/feature is **present / on / OK** |
| `[X]` (gray) | That tool is **not installed** |
| A number like `2.1.80` | The tool's **version** |
| `(found in PATH)` or `(found)` | The tool **exists, but its version couldn't be read**. It works fine. |
| `N/A` | Can't check right now. CPU temperature, etc. may need **administrator rights**. |
| `N/A (admin required)` | You may see it if you run as administrator. |
| Bar graph `[#######-----]` | Visual usage (%). Green = plenty, yellow = moderate, red = high |

**Color meaning (approximate)**

- 🟢 **Green**: good / normal / plenty
- 🟡 **Yellow**: caution / moderate / worth checking
- 🔴 **Red**: risk / low / high temperature
- ⚪ **Gray**: not applicable / not installed / disabled

---

## 12. The score system in detail

**Menu 15** (or the end of the full scan in menu 1) rates your PC **out of 100**.
The basis is "how suitable is it for development (coding)."

### Points per category (100 total)

| Category | Max | Scoring rule |
|---|---|---|
| **CPU** | 20 | 8+ cores = 20 / 6 cores = 16 / 4 cores = 12 / 2 cores = 6 / fewer = 3 |
| **RAM** | 20 | 64GB+ = 20 / 32GB = 18 / 16GB = 14 / 8GB = 8 / less = 3 |
| **Storage** | 15 | NVMe = 15 / regular SSD = 12 / HDD = 5 · (−3 if free space on C: is under 30GB) |
| **GPU** | 10 | Dedicated 8GB+ = 10 / 4GB = 8 / 2GB = 5 / integrated = 3 / none = 0 |
| **Dev Tools** | 35 | See table below |

### Dev Tools 35-point breakdown

| Group | Scoring | Max |
|---|---|---|
| Core (Python, Node.js, Git) | 5 each | 15 |
| Package managers (npm, pnpm, pip) | 2 each | 6 |
| Editors (VS Code, Cursor, IntelliJ, Neovim) | 2 each | 4 |
| AI coding tools (Claude, Gemini, Codex, Aider) | 2 each | 4 |
| Extra (Docker, GitHub CLI, Bun, Rust, Go, Make, Terraform, kubectl, AWS, ripgrep) | 1 each | 6 |

### Grades

| Score | Grade | Meaning |
|---|---|---|
| 85–100 | **S** | Excellent dev machine |
| 70–84 | **A** | Great setup |
| 55–69 | **B** | Decent, room to improve |
| 40–54 | **C** | Needs improvement |
| 0–39 | **D** | Consider upgrading hardware + tools |

> Below the score, **weaknesses and recommendations** (e.g. "RAM under 16GB", "Python missing") are shown.
> ❗ A low score does **not** mean a "bad PC." This score is about **development readiness**.
> A perfectly good PC for web browsing/documents will score low if it has no dev tools.

---

## 13. Workflow (full flow diagram)

```
[1] Download           Get the ZIP from GitHub  (or just the .bat file)
        │
        ▼
[2] Extract            Right-click the ZIP → "Extract All"
        │
        ▼
[3] Run                Double-click pc-spec_checker-kit.bat
        │
        ▼
[4] Handle warning     "More info" → "Run anyway"  (first time only)
        │
        ▼
[5] Pick a number      First time → 1 (Full Scan) → Enter
        │
        ▼
[6] View results       Read specs & score on screen (copy if needed)
        │
        ├─▶ See more items → Enter to return to menu → pick another number
        │
        ▼
[7] Exit               Type 0 → "Goodbye!" → window closes
```

---

## 14. Commands

> Honestly, **you barely need to remember any commands.**
> Double-click with the mouse, then just press **numbers**.

### The "inputs" used inside the tool (that's all there is)

| Input | Action |
|---|---|
| `1`–`15` + Enter | Run that menu item |
| `1` + Enter | Full scan (most recommended) |
| `13` + Enter | Dev-tools deep scan only |
| `15` + Enter | Score only |
| Enter (on a result screen) | Back to the menu |
| `0` + Enter | Exit |

### (Optional) Run commands for people comfortable with the computer

You can also run it directly from PowerShell or Command Prompt (cmd).
After navigating to the folder containing the file:

```bat
pc-spec_checker-kit.bat
```

Or with the full path:

```bat
"C:\path\to\your\folder\pc-spec_checker-kit.bat"
```

### (Optional) Save results to a text file

In Command Prompt (cmd), this saves the results to a file.
(Auto-enters `1` for a full scan and saves to `result.txt`.)

```bat
echo 1 | pc-spec_checker-kit.bat > result.txt
```

> Note: this saves text only, without colors or bar graphs. The simplest way to save is the
> "copy from the screen and paste into Notepad" method in [8-4](#8-4-if-you-want-to-save-the-results-to-a-file-optional).

---

## 15. File locations / Document locations

### Files in this project

```
pc-spec_checker-kit/
├── pc-spec_checker-kit.bat   ← the actual tool (double-click this)
├── LICENSE               ← full license text (Apache 2.0)
├── NOTICE                ← copyright notice
├── README.md             ← Korean intro (GitHub front page)
├── README.en.md          ← English intro
├── GUIDE.md              ← Korean complete guide
├── GUIDE.en.md           ← English complete guide (this document)
├── README.pdf / README.en.pdf   ← PDF versions of the intro
└── GUIDE.pdf  / GUIDE.en.pdf     ← PDF versions of the complete guide
```

> 📄 **The .md and .pdf have identical content.** Use `.md` for reading on screen, and `.pdf` for printing, sharing, or offline keeping.

### If you can't find the downloaded file

- **Open the Downloads folder**: press `Windows key + E` (File Explorer) → click **`Downloads`** on the left.
- **Find what you just downloaded**: sort by **`Date modified`** so the newest is on top.
- **Search by name**: type `pc-spec_checker-kit` into the taskbar search box (the magnifier).

---

## 16. Troubleshooting / Error handling

Find your symptom below.

### ① A blue "Windows protected your PC" window appears
→ This is normal. Click **`More info`** → **`Run anyway`**. ([8-2](#8-2-when-windows-shows-a-security-warning-this-is-normal))

### ② I double-clicked but the black window **flashed and closed instantly**
→ Usually one of these:
- You ran it **without extracting** (from inside the ZIP) → **Extract** the ZIP first, then run.
- Antivirus blocked it → check your antivirus quarantine/block list and trust it.
- To see for sure: open **PowerShell** in the file's folder and run it directly.
  (In the folder, `Shift + right-click` an empty area → **`Open PowerShell window here`** → type `.\pc-spec_checker-kit.bat` → Enter.)
  This keeps any error message visible so you can see the cause.

### ③ Text looks garbled (`□□□` or strange characters)
→ This tool outputs in English using UTF-8 (`chcp 65001`). It's usually fine, but old console settings may garble it.
Running it in **Windows Terminal** (default on Windows 11) gives the cleanest result.

### ④ A program I definitely installed shows as `[X] not installed`
→ The tool checks **common install paths, your PATH, and the registry**.
If you installed it in an unusual folder or it's not on PATH, it may not be found.
Adding that program to your **system PATH** fixes detection. (The program itself still works fine.)

### ⑤ CPU temperature shows `N/A (admin required)`
→ Reading the temperature sensor needs **administrator rights**.
Right-click the file → **`Run as administrator`** and it may appear.
(Even as admin, some PCs have no supported sensor and show N/A — that's normal.)

### ⑥ The scan is very slow
→ The **Full Scan (1)** checks 193 tools and many sensors, so it can take **30–60 seconds**.
Individual menus (e.g. 3 for CPU only) are much faster. In a hurry, pick only the items you need.

### ⑦ It doesn't work on Mac / Linux
→ This tool is **Windows only**. It does not run on Mac or Linux. ([4. Prerequisites](#4-prerequisites--required-programs))

### ⑧ "Internet response time" shows `Slow` or nothing
→ Your internet is slow or disconnected. This is not a tool problem.
Everything else works fine without internet.

### ⑨ Too many results — I can't scroll back up
→ Scroll up with the window's scroll bar or the mouse wheel.
Or save to a file using "Save results to a text file" in [14. Commands](#14-commands) and read it slowly.

---

## 17. Frequently Asked Questions (FAQ)

**Q. Is it safe to run?**
A. Yes. The tool **only reads info — it does not install, change, or send anything**.
The source code is right inside the `.bat` file; open it with Notepad to verify. ([20. Safety](#20-safety--privacy))

**Q. Do I need administrator rights?**
A. No. Most things work without them. Only a few (like CPU temperature) show `N/A`.

**Q. Does it work on Windows 10?**
A. Yes. Both Windows 10 and 11 are supported.

**Q. Do I need internet?**
A. No. It works without it. With internet you only additionally see "internet response time."

**Q. Where is my personal data sent?**
A. **Nowhere.** The only network action is a single connectivity ping (`8.8.8.8`), which sends no data.

**Q. Does it leave any files or traces?**
A. No. The tool creates no files at all.

**Q. What does "found in PATH" mean?**
A. The tool is installed but only its version number couldn't be read. It works fine.

**Q. My antivirus warns it's dangerous.**
A. Because it's a `.bat` file, some antivirus reacts sensitively (false positive). You can read the code yourself, so trust it if needed.

---

## 18. Glossary (plain language)

| Term | Plain explanation |
|---|---|
| **CPU** | The computer's brain. Handles all calculations. |
| **Core** | The number of workers inside the CPU. More = more done at once. |
| **Thread** | A stream of work each core handles at once. Usually 2× the cores. |
| **RAM** | The computer's work desk. Wider = runs more programs at once. |
| **DDR4 / DDR5** | RAM generations. DDR5 is faster than DDR4. |
| **GPU (graphics card)** | Handles screen, games, video, and AI work. |
| **VRAM** | The graphics card's own memory. More = better for high-res work. |
| **SSD** | Fast storage. Quick boot and program launch. |
| **HDD** | Slow but high-capacity storage (hard disk). |
| **NVMe** | The fastest kind of SSD (much faster than a regular SSD). |
| **BIOS** | The first basic program that runs when the computer turns on. |
| **Motherboard** | The big board everything plugs into (the computer's body). |
| **PATH** | The computer's address book for finding programs. Registered ones run anywhere. |
| **Driver** | The software that makes a part work (e.g. graphics driver). |
| **Antivirus** | A security program that blocks malware. |
| **Firewall** | A security wall that blocks outside intrusion. |
| **UAC** | The security feature that asks "Allow?" when a program tries to change the system. |
| **BitLocker** | Windows' disk encryption feature. |
| **WSL** | A feature to run Linux inside Windows (for developers). |
| **Git** | A tool that manages code change history (a developer's "undo"). |
| **Node.js** | A tool that runs JavaScript on your PC (essential for web dev). |
| **Docker** | A tool that runs programs in isolated environments. |
| **IDE / editor** | A specialized program for writing code (like VS Code). |
| **CLI** | Using a tool by typing commands (the black window). |
| **.bat file** | A Windows script file that runs commands automatically. |
| **PowerShell** | A powerful command tool built into Windows. |
| **ping** | A signal that checks if something responds ("are you there?"). |

---

## 19. For people who code with AI

It's especially useful if you code with AI tools like ChatGPT, Claude, Cursor, or Copilot.

- **Check your environment**: AI told you to run `npm install` but it fails?
  Use **item 13 (Dev Tools)** to check if Node.js and npm are installed.
- **Tell the AI about your environment**: copy the full-scan (item 1) results and paste them to the AI,
  and it can give precise guidance tailored to your PC.
- **See what to install**: **item 15 (Score)** recommends the tools you're missing.

---

## 20. Safety / Privacy

This tool does **NOT**:

- ❌ install anything.
- ❌ change any settings.
- ❌ create or delete any files.
- ❌ send your data anywhere.

All this tool does is:

- ✅ **read** your PC info using built-in Windows features
- ✅ **show** it in the window

> The only network action is a single connectivity **ping (`8.8.8.8`)**, and it sends no personal data.
> **The entire source code is inside the `.bat` file.** Open it with Notepad to verify.

---

## 21. License / Copyright / Commercial use

> **Simple one-line summary:** Anyone may **use, modify, redistribute, and even use it commercially — for free**.
> Just **keep the copyright notice and a copy of the license**, and note it comes with **no warranty (use at your own risk)**.

**Precise legal terms:**

- **Copyright**: Copyright 2026 **SoDam AI Studio**. All rights reserved under the terms below.
- **License**: This project is distributed under the **Apache License, Version 2.0**.
  The full text is in the [`LICENSE`](./LICENSE) file in this folder, and the original is at http://www.apache.org/licenses/LICENSE-2.0

### ✅ What you may do

- **Use**: anyone — individuals, companies, organizations — for any purpose.
- **Copy / distribute**: copy it as-is or in part and give it to others.
- **Modify / derivative works**: edit the code or combine it into a new tool.
- **Commercial use**: include it in company work, paid services, or products — **commercial use is allowed** (no separate permission or royalty needed).

### 📌 Obligations (when you distribute/redistribute)

1. **Include a copy of the license**: give recipients a copy of `LICENSE` (Apache 2.0).
2. **Keep notices**: do **not** remove the original copyright, patent, trademark, or attribution notices.
3. **State changes**: if you modified files, **prominently mark them as "changed."**
4. **Keep NOTICE**: include the attribution notices from the [`NOTICE`](./NOTICE) file in your distribution.

### 🚫 Cautions / prohibitions

- **No trademark rights are granted.** You may not use names/logos like "SoDam AI Studio" or "pc-spec_checker-kit" **as if they were your own product** (mentioning the origin is fine).
- **Patent clause**: a patent license from contributors is included, but if you **file a patent lawsuit** against this project, your granted patent rights terminate.

### ⚠️ Warranty / liability (disclaimer)

- This tool is provided **"AS IS"**, with **no warranty whatsoever** (including merchantability, fitness for a particular purpose, and non-infringement).
- The copyright holder and contributors are **not liable for any damages** arising from its use.
- Deciding whether and how to use it, and the associated risk, is **your own responsibility**.

### 🧩 Third-party components

- This tool does **not bundle or redistribute any third-party code/libraries**.
- At run time it uses only Windows built-in features (PowerShell, WMI/CIM, registry), which are already part of your Windows and governed by **Microsoft's license** (not redistributed by this project).

---

## 22. Key features

- **15 menus** + exit (0) — pick only what you want
- Deep scan of **193 dev tools** (17 categories) via 3-step detection (PATH + known paths + registry)
- Hardware: CPU, RAM (per stick), disk (health), GPU, battery/power, audio/USB/Bluetooth
- System: security status, startup programs, installed apps, WSL
- Score system: 5 categories out of 100 + letter grades (S/A/B/C/D) + weakness analysis & recommendations
- Menu and section titles shown in **English / Korean**

---

## 23. How to contribute

If you find a tool that isn't detected, or know a common install path that's missing, contributions are welcome.

- Open an **Issue** (problem/suggestion) or a **Pull Request** (proposed edit) on the GitHub repository.
- Contributions are considered to be provided under the same **Apache License 2.0** as this project.

---

## 24. Contact / Support

- Project: **pc-spec_checker-kit** (by SoDam AI Studio)
- Repository: `https://github.com/sodam-ai/pc-spec_checker-kit`
- Questions / bug reports: use the **Issues** tab on the repository above.

---

*This document (GUIDE.en.md) and its PDF version (GUIDE.en.pdf) have identical content.*
*Reference: pc-spec_checker-kit · License: Apache License 2.0 · © 2026 SoDam AI Studio*

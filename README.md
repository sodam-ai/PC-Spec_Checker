# PC Spec Checker v3.0

**One double-click to see everything about your PC.**

No installation · No coding · No technical knowledge needed.
Just download one file, double-click it, and instantly see your full PC specs.

> 🌐 [Korean version (한국어 버전)](./README.ko.md)
> 📘 **New here? → Read the [Complete Beginner's Guide (GUIDE.md)](./GUIDE.md)** (PDF: `GUIDE.pdf`)

---

## What is this?

PC Spec Checker is a single `.bat` file that scans your Windows PC and shows you:

- What CPU, RAM, GPU, and storage you have
- How healthy your disk drives are
- What software and developer tools are installed (auto-checks **up to 193 tools**)
- A **score out of 100** rating your PC's development readiness

Think of it as a **free, instant health checkup for your computer**.

> 🔒 **It's safe.** The tool does not install, change, or transmit anything — it only **reads** your PC info.
> The full source code is inside the `.bat` file; open it with Notepad to verify.

---

## Quick start (3 steps)

1. **Download** — On GitHub click the green **`Code`** button → **`Download ZIP`** → extract it.
   (Or just grab the single `PC-Spec_Checker.bat` file.)
2. **Run** — Double-click **`PC-Spec_Checker.bat`**.
   If a security warning appears, click **`More info`** → **`Run anyway`**.
3. **Choose** — Type **`1`** in the menu and press Enter → all specs appear at once.

No installation, no account, no internet required.

---

## What can it check? (15 menu items)

| # | Menu | What you'll see |
|---|---|---|
| 1 | Show ALL ⭐ | A full scan of everything below |
| 2 | Basic Info | PC name, Windows version, motherboard, BIOS |
| 3 | CPU | Name, cores, speed, temperature |
| 4 | RAM | Total + each stick (size/type/speed) |
| 5 | Disk | SSD/HDD type, health status, free space |
| 6 | GPU | Graphics card, VRAM, driver |
| 7 | Network + Display | IP address, internet response time, monitors |
| 8 | Battery | Charge level, battery health (laptops) |
| 9 | Security | Antivirus, firewall, UAC, BitLocker |
| 10 | Startup Programs | Apps that run at boot |
| 11 | Audio / USB / Bluetooth | Connected devices |
| 12 | Installed Apps | Browsers, office, media, etc. (8 categories) |
| 13 | Dev Tools | Deep scan of **193 tools** (17 categories) |
| 14 | WSL | Windows Subsystem for Linux status |
| 15 | Score | Rating out of 100 + recommendations |
| 0 | Exit | Close the tool |

See the **[Complete Beginner's Guide](./GUIDE.md)** for a detailed explanation of each item.

---

## The score system

Your PC is rated out of **100 points across 5 categories**.

| Category | Max | What's measured |
|---|---|---|
| CPU | 20 | Core count (8+ = full marks) |
| RAM | 20 | Total memory (32GB+ = full marks) |
| Storage | 15 | SSD/NVMe type + free space |
| GPU | 10 | Dedicated GPU + VRAM size |
| Dev Tools | 35 | Essential tools installed |

**Grades**: S(85–100) · A(70–84) · B(55–69) · C(40–54) · D(0–39)
Specific weaknesses and recommendations are shown below the score.

---

## Prerequisites

| Item | Required? |
|---|---|
| Windows 10 / 11 | ✅ Required (no Mac/Linux) |
| PowerShell | ✅ Required but **built into Windows** |
| Internet | 🔵 Optional (works without it) |
| Administrator rights | 🔵 Optional (a few temps show N/A without) |
| Extra installs | ❌ Not needed |

---

## FAQ

- **Is it safe?** → Yes. It only reads info — no install, change, or transmission.
- **Need admin rights?** → No. Only a few temperatures show `N/A`.
- **Works on Windows 10?** → Yes, both 10 and 11.
- **Works on Mac/Linux?** → No, Windows only.
- **It's slow** → A full scan can take 30–60 seconds.

More questions and fixes are in the **[guide's troubleshooting section](./GUIDE.md#16-troubleshooting--error-handling)**.

---

## Example output

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

## Documents

| Document | Description |
|---|---|
| [README.md](./README.md) / [README.ko.md](./README.ko.md) | EN/KO intro (this file) |
| [GUIDE.md](./GUIDE.md) / [GUIDE.ko.md](./GUIDE.ko.md) | EN/KO complete beginner's guide |
| `*.pdf` | PDF versions of the above (identical content) |
| [LICENSE](./LICENSE) / [NOTICE](./NOTICE) | Full license / copyright notice |

---

## License

This project is distributed under the **Apache License 2.0**. © 2026 SoDam AI Studio.

- ✅ Anyone may **use, modify, redistribute, and use it commercially — for free**
- 📌 When redistributing, include the **copyright notice and a copy of the license**, and **mark changes** if modified
- 🚫 No trademark rights are granted (don't use the name/logo as if it were your own product)
- ⚠️ Provided **"AS IS"** · **no warranty** · use at your own risk

Full text in [`LICENSE`](./LICENSE); a plain-language explanation is in [guide section 21](./GUIDE.md#21-license--copyright--commercial-use).

---

## Contributing

Found a tool that isn't detected, or a missing install path?
Open an [Issue](../../issues) or [Pull Request](../../pulls). Contributions are provided under Apache 2.0.

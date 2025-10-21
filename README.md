# Repop

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-v0.1.0-blue.svg)](https://github.com/ChrisClements1987/repop/releases)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Issues](https://img.shields.io/github/issues/ChrisClements1987/repop)](https://github.com/ChrisClements1987/repop/issues)

A simple, configurable Windows utility to "re-pop" a specific browser tab to the foreground at a set interval.

---

## 🎯 What is Repop?

In a world of a dozen browser tabs and endless distractions, it's easy to forget about that one "single source of truth" tab you're supposed to be checking. For some, it's a Trello board. For others, it's a calendar, a dashboard, or a to-do list.

`Repop` is your persistent, automated "nag" to keep that priority tab in view.

It's a lightweight tool that runs silently in the background. At an interval you choose, it finds your specific URL in your chosen browser and brings it to the foreground, "re-popping" it over your other windows for your attention.

![Repop Demo GIF](docs/repop-demo.gif)
*(A demo GIF showing the utility in action would be perfect here)*

## ✨ Features

* **Bring any URL to the foreground:** `https://trello.com`, `https://calendar.google.com`, a local Grafana dashboard, anything.
* **Set any pop-up frequency:** Every 15 minutes, every hour, every 4 hours—it's up to you.
* **Choose your target browser:** Explicitly supports Firefox, Chrome, Edge, Brave, and more.
* **Intelligent opening:** If the tab is already open, it just brings it to the front. If it's closed, it opens it for you.
* **Silent operation:** Uses the native Windows Task Scheduler for a 100% "headless" operation. No terminal windows ever flash on your screen.
* **Lightweight & No Dependencies:** Written in PowerShell. It uses only the native components built into Windows 10 & 11.

## ⚙️ How It Works

`Repop` is a single PowerShell script that is run by the **Windows Task Scheduler**.

1.  You provide your settings in a simple `config.ps1` file.
2.  You run the `install.ps1` script (one time).
3.  This installer script creates a new task in Windows Task Scheduler, configured to run `repop.ps1` silently at your chosen frequency.
4.  The `repop.ps1` script handles the logic of finding or opening your browser tab and forcing the window to the foreground.

## 🚀 Installation & Configuration

Getting started is a 2-minute process.

1.  **Get the Code:**
    * **Recommended:** Clone the repository:
        ```bash
        git clone [https://github.com/ChrisClements1987/repop.git](https://github.com/ChrisClements1987/repop.git)
        ```
    * **Alternative:** [Download the .ZIP file](https://github.com/ChrisClements1987/repop/archive/refs/heads/main.zip) and extract it.

2.  **Navigate:**
    * Open the `repop` directory you just downloaded.
        ```powershell
        cd repop
        ```

3.  **Configure:**
    * Open the `config.ps1` file in your favourite text editor (like VS Code or Notepad). This is the **only file you need to edit.**
    * Update the variables to match your needs.

4.  **Install:**
    * Right-click the `install.ps1` file and select **"Run with PowerShell"**.
    * This script will read your `config.ps1` and automatically create the Windows Scheduled Task for you.

That's it! The task is now scheduled and will run at its next interval.

### The `config.ps1` File

This is where you define the behaviour of `Repop`.

```powershell
# -----------------------------------------------------------------
# Repop Configuration File
# -----------------------------------------------------------------

$Config = @{
    # The full URL you want to pop up.
    URL = "[https://trello.com/b/your-board-id](https://trello.com/b/your-board-id)"

    # The frequency (in minutes) for the pop-up.
    # The task will run on this schedule (e.g., 60 = every hour).
    FrequencyMinutes = 60

    # The .exe name of your target browser.
    # Common values:
    # "firefox"
    # "chrome"
    # "msedge"
    # "brave"
    BrowserExeName = "firefox"

    # The full path to your browser's executable.
    # The script will try to find this automatically, but if it fails,
    # you can set it manually here.
    # Example: "C:\Program Files\Mozilla Firefox\firefox.exe"
    BrowserExePath = ""

    # The string to search for in the window title to "find" the browser.
    # This is what the script uses to bring the window to the front.
    # Common values:
    # "Mozilla Firefox"
    # "Google Chrome"
    # "Microsoft Edge"
    # "Brave"
    WindowTitleSearch = "Mozilla Firefox"
}
````

### Example: My Personal Trello Setup

This is the configuration I use to pop up my main Trello board in Firefox every hour.

```powershell
$Config = @{
    URL = "[https://trello.com/b/qjXFqZ8k/my-main-board](https://trello.com/b/qjXFqZ8k/my-main-board)"
    FrequencyMinutes = 60
    BrowserExeName = "firefox"
    BrowserExePath = "C:\Program Files\Mozilla Firefox\firefox.exe"
    WindowTitleSearch = "Mozilla Firefox"
}
```

## 🔧 Making Changes

If you want to change the frequency or URL, just:

1.  Edit the `config.ps1` file and save it.
2.  Run the `install.ps1` script again. It will automatically delete the old task and create a new one with your updated settings.

## 🗑️ Uninstalling

To remove `Repop` completely:

1.  Right-click the `uninstall.ps1` file.
2.  Select **"Run with PowerShell"**.
3.  This will find and delete the scheduled task from Windows Task Scheduler.
4.  You can then safely delete the `repop` folder.

## 🐛 Reporting Issues & Requesting Features

We use GitHub Issues to track bugs, feature requests, and enhancements. Before creating a new issue, please:

1. **Search existing issues** to see if your bug/feature has already been reported
2. **Check our roadmap** in the issues to see if your feature is already planned
3. **Provide clear details** when reporting bugs (OS version, browser, error messages)

### 🎯 Issue Types

- **🐛 Bug Reports**: Something isn't working as expected
- **✨ Feature Requests**: New functionality you'd like to see
- **📝 Documentation**: Improvements to docs or examples
- **🚀 Enhancements**: Improvements to existing features

### 📋 How to Report

1. **Go to [Issues](https://github.com/ChrisClements1987/repop/issues)**
2. **Click "New Issue"**
3. **Choose the appropriate template** (if available)
4. **Fill out all relevant sections**

### 🎯 Current Roadmap

Check our [GitHub Issues](https://github.com/ChrisClements1987/repop/issues) to see:
- ✅ **Completed features** (marked as closed)
- 🚧 **In progress** (currently open with assignees)
- 🎯 **Planned features** (labeled as "enhancement")

## 🤝 Contributing

Pull requests are welcome! If you have ideas for new features, bug fixes, or improvements, please open an issue first to discuss what you would like to change.

### Development Workflow

1. **Fork the Project**
2. **Create your Feature Branch** (`git checkout -b feature/AmazingFeature`)
3. **Make your changes** and test thoroughly
4. **Update documentation** if needed (README, comments, etc.)
5. **Commit your Changes** (`git commit -m 'Add some AmazingFeature'`)
6. **Push to the Branch** (`git push origin feature/AmazingFeature`)
7. **Open a Pull Request** with a clear description of your changes

### 📝 Contribution Guidelines

- **Test your changes** on Windows before submitting
- **Follow PowerShell best practices** and maintain code style consistency
- **Update the README** if you add new configuration options
- **Add comments** for complex logic or Windows API calls
- **Keep commits focused** - one feature/fix per PR when possible

## 📜 License

This project is distributed under the MIT License. See `LICENSE.txt` for more information.

```
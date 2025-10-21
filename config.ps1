# -----------------------------------------------------------------
# Repop Configuration File
# -----------------------------------------------------------------
#
# Edit these variables to match your needs.
# After editing, run install.ps1 to apply the changes.
#

$Config = @{
    # The full URL you want to pop up.
    URL = "https://trello.com/b/oxNHbQTb/tasks"

    # The frequency (in minutes) for the pop-up.
    FrequencyMinutes = 60

    # The .exe name of your target browser.
    # Common values: "firefox", "chrome", "msedge", "brave"
    BrowserExeName = "firefox"

    # The full path to your browser's executable.
    # Leave this blank ("") to let the script try to find it.
    BrowserExePath = ""

    # The string to search for in the window title to "find" the browser.
    # "Mozilla Firefox", "Google Chrome", "Microsoft Edge", "Brave"
    WindowTitleSearch = "Mozilla Firefox"
}
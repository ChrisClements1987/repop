\## 🏛️ Architecture Decision Records (ADRs)



Here are the key technical decisions made for this utility, using a lean ADR format.



\### ### ADR-001: Task Scheduling Mechanism



\* \*\*Title:\*\* Use Windows Task Scheduler for Script Execution

\* \*\*Status:\*\* Decided

\* \*\*Context:\*\* The utility must run automatically every hour, 24/7, and survive system reboots. We need a reliable, low-overhead scheduling system.

\* \*\*Decision:\*\* We will use the native \*\*Windows Task Scheduler\*\* to trigger the script.

\* \*\*Consequences:\*\*

&nbsp;   \* \*\*Pro:\*\* Extremely reliable and robust. It's built into the OS.

&nbsp;   \* \*\*Pro:\*\* No need to write a custom, long-running Python process with a `while True:` loop and `time.sleep()`.

&nbsp;   \* \*\*Pro:\*\* The task configuration is persisted and automatically starts after a reboot.

&nbsp;   \* \*\*Con:\*\* Configuration is "external" to the script. If the script is moved, the Task Scheduler must be manually updated.



---



\### ### ADR-002: Scripting Language Choice



\* \*\*Title:\*\* Choice of Scripting Language for Browser Interaction

\* \*\*Status:\*\* Options Presented

\* \*\*Context:\*\* The script must be able to 1) open a new Firefox tab, and 2) force the Firefox window to the foreground. This requires both web-launch and OS-level window management capabilities.

\* \*\*Decision:\*\* Two primary options were identified: \*\*PowerShell\*\* (native) or \*\*Python\*\* (with `pywin32`).

\* \*\*Consequences:\*\*

&nbsp;   \* \*\*PowerShell Option:\*\*

&nbsp;       \* \*\*Pro:\*\* Native to Windows 11. No external dependencies need to be installed.

&nbsp;       \* \*\*Pro:\*\* Simple one-line commands for `Start-Process` and `AppActivate`.

&nbsp;   \* \*\*Python Option:\*\*

&nbsp;       \* \*\*Pro:\*\* More robust and precise window-finding using `pywin32`'s `EnumWindows` and callback functions.

&nbsp;       \* \*\*Pro:\*\* Easier to extend with more complex logic later (like the "Snooze" feature).

&nbsp;       \* \*\*Con:\*\* Requires a Python interpreter to be installed.

&nbsp;       \* \*\*Con:\*\* Requires an external library (`pip install pywin32`).



---



\### ### ADR-003: Invisible Execution (Hiding the Terminal)



\* \*\*Title:\*\* Ensure Silent, Invisible Script Execution

\* \*\*Status:\*\* Decided

\* \*\*Context:\*\* When Task Scheduler runs a script, it can briefly flash a terminal (CMD/PowerShell) window. This is visually disruptive and undesirable for a background utility.

\* \*\*Decision:\*\* The script execution must be hidden from the user.

\* \*\*Consequences:\*\*

&nbsp;   \* \*\*If using PowerShell:\*\* The Task Scheduler action for `powershell.exe` will include the \*\*`-WindowStyle Hidden`\*\* argument.

&nbsp;   \* \*\*If using Python:\*\* The script will be saved with the \*\*`.pyw`\*\* file extension. This tells Windows to use `pythonw.exe` (the windowless interpreter) instead of `python.exe`.




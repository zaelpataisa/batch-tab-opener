# Batch Tab Opener

A hybrid batch (`.bat` / PowerShell) tool designed to open multiple instances of a URL concurrently in Windows. It provides full control over the browser instance and the navigation environment (Normal or Incognito / InPrivate).

---

## Features

* **Self-Contained Hybrid Script:** A `.bat` executable file that invokes its own internal PowerShell logic, seamlessly bypassing system script restrictions (`ExecutionPolicy Bypass`).
* **Active Window Injection:** Allows you to select an already open browser window and inject tabs directly into it via UI automation (`Wscript.Shell`), preventing the creation of multiple scattered windows.
* **Privacy Control:**
  * **Automatic:** Detects if the target window is in Incognito/InPrivate mode and opens the new tabs within that same private context.
  * **Force Incognito / InPrivate:** Forces all tabs to open in private browsing mode, regardless of the target window's state.
  * **Force Normal:** Forces all tabs to open in standard browsing mode.
* **Multi-Browser Support:** Automatically detects and operates on Microsoft Edge, Google Chrome, Brave, Mozilla Firefox, and Opera.
* **Secure URL Handling:** Auto-corrects URL prefixes (`http://` / `https://`) and transfers URLs with complex characters using the system clipboard to prevent CLI truncation issues.

---

## Requirements

* **Operating System:** Windows 10 or Windows 11 (32-bit or 64-bit).
* **Environment:** PowerShell 5.1 or higher (pre-installed by default on Windows).
* **Supported Browsers:** Microsoft Edge, Google Chrome, Brave, Mozilla Firefox, or Opera.

---

## Installation & Usage

1. Save the source code into a file with a `.bat` extension (e.g., `opener.bat`).
2. Double-click the file or run it directly from the Command Prompt (CMD):

```cmd
opener.bat
```

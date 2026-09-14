# PCITScripts

Centralized PowerShell script repository consumed by [PCITLauncher](https://github.com/PCIT-LLC/PCITLauncher). Add a `.ps1` file, update `config.json`, and every launcher on the network gets the new script on next pull.

## Repo Structure

```
PCITScripts/
├── config.json          ← menu definition (categories + script references)
├── Network/             ← example category folder
│   ├── flush-dns.ps1
│   └── reset-tcpip.ps1
├── Git/
│   └── pull-all-repos.ps1
└── System/
    └── disk-cleanup.ps1
```

Each top-level folder is a **category**. Scripts inside are the **menu items** in that category.

## `config.json` Layout

```json
{
  "categories": [
    {
      "name": "Network",
      "scripts": [
        {
          "label": "Flush DNS",
          "script": "Network/flush-dns.ps1",
          "elevated": true
        },
        {
          "label": "Reset TCP/IP Stack",
          "script": "Network/reset-tcpip.ps1",
          "elevated": true
        }
      ]
    },
    {
      "name": "Git",
      "scripts": [
        {
          "label": "Pull All Repos",
          "script": "Git/pull-all-repos.ps1",
          "elevated": false
        }
      ]
    }
  ]
}
```

### Field Reference

| Field | Required | Description |
|---|---|---|
| `categories` | ✅ | List of menu categories |
| `categories[].name` | ✅ | Category label shown in the tray menu |
| `categories[].scripts` | ✅ | List of scripts in this category |
| `scripts[].label` | ✅ | Menu item text |
| `scripts[].script` | ✅ | Path to `.ps1` file relative to repo root (use `/` separators) |
| `scripts[].elevated` | ✅ | `true` = UAC prompt + admin rights; `false` = current user |

## Adding a New Script

1. Create your `.ps1` file in a category folder (or create a new folder for a new category).
2. Add an entry to `config.json` under the appropriate category.
3. Commit and push to `main`.
4. Launcher users pull the update and the new menu item appears automatically.

### Example: Adding a script to an existing category

Add `Network/flush-arp.ps1` to the repo, then append to `Network`'s scripts array:

```json
{
  "label": "Flush ARP Cache",
  "script": "Network/flush-arp.ps1",
  "elevated": true
}
```

### Example: Adding a new category

Create a `Docker/` folder with scripts, then add a new top-level entry to `categories`:

```json
{
  "name": "Docker",
  "scripts": [
    {
      "label": "Prune All",
      "script": "Docker/prune.ps1",
      "elevated": false
    }
  ]
}
```

## Scripting Conventions

- **Write-Host** for status messages — captured in logs and transcripts.
- **Write-Error** for failures — also captured and shown in logs.
- **Throw** for fatal errors — causes a non-zero exit code the launcher logs.
- **No Read-Host** — scripts run non-interactively. If you need input, pass it as a parameter.

### Network scripts

| Script | Description |
|---|---|
| `Network/flush-dns.ps1` | Clears the DNS resolver cache |
| `Network/reset-tcpip.ps1` | Resets the TCP/IP stack |
| `Network/set-wired-dhcp.ps1` | Detects the active wired adapter and sets it to DHCP |

### Example template:

```powershell
# Network/flush-dns.ps1
Write-Host "Flushing DNS resolver cache..."
try {
    Clear-DnsClientCache
    Write-Host "Done. DNS cache flushed."
} catch {
    Write-Error "Failed: $_"
    throw
}
```

## PR Validation

Every PR is automatically checked for:

- ✅ `config.json` is valid JSON
- ✅ All required fields present (`name`, `label`, `script`, `elevated`)
- ✅ Every `script` path in `config.json` points to a real `.ps1` file
- ⚠️ Warning if any `.ps1` file exists but isn't referenced in `config.json` (orphaned)

Fix any errors before merging.

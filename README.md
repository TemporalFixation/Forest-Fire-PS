# 🌲🔥 ForestFirePS

**Burn through red tape. Automate the forest.**

ForestFirePS is a curated collection of PowerShell tools built for sysadmins managing tangled forests (Active Directory), cloudy ridgelines (Azure/Entra), and overgrown jungles (Google Admin via GAM). Whether you're herding accounts, pruning access, or digging through license reports — this toolkit is designed to make the job faster, safer, and more fun.

---

## 🧰 Core Features

### 🌳 Active Directory Management (Primary Focus)
- 🔓 Unlock and reset user accounts
- 🧼 Identify and remove stale/inactive users
- 🧮 Enumerate nested group membership
- 📜 Audit permissions and group assignments
- 🔄 Rotate passwords securely

### ✈️ User Lifecycle Automation
- 👤 **Onboarding**
  - Create AD users with consistent naming conventions
  - Auto-assign security groups and OUs
  - Trigger mailbox creation or cloud sync flags
- 🪦 **Offboarding**
  - Disable users across AD and Azure
  - Archive or convert mailboxes (shared/forwarded)
  - Remove licenses and document access removal
  - Log everything (for HR/audit trail compliance)

### 📦 Licensing Insights
- 🔎 Query assigned Microsoft 365 / Azure licenses
- 📊 Export usage and assignment breakdowns
- 🚫 Identify unused or orphaned licenses for cleanup

### ☁️ Azure & Entra ID (Planned/Partial)
- Create/update users via MS Graph or Entra cmdlets
- Assign or audit Conditional Access and roles
- Group management with RBAC in mind

### 🧢 Google Admin (via GAM, Future Module)
- GAM wrapper scripts to:
  - Query users, org units, and groups
  - Suspend or delete accounts
  - Generate exports for compliance

---

## 📁 Folder Structure (Planned)

```plaintext
ForestFirePS/
├── Kindling_AD/            # Most AD scripts (Creation, Offboarding, Syncing)
├── Exchange_Watchtower/    # Exchange Scripts (permissions to send as)
├── Permission_Pyro/        # Ondrive/Sharepoint Management (conditional access, licenses)
├── Blaze_Azure/            # Azure/Entra scripts (conditional access, licenses)
├── SmokeSignals_GAM/       # GAM scripts for Google Admin (user mgmt, audits)
├── Firebreaks/             # Audit & safety tools, backups, dry runs
└── Docs/                   # Usage guides, config templates, internal docs
```

---

## 🚀 Getting Started

1. Clone the repo:
   ```bash
   git clone https://github.com/YourUsername/ForestFirePS.git
   cd ForestFirePS
   ```

2. Launch in VS Code:
   ```bash
   code .
   ```

3. Review and run:
   - Scripts include clear `-WhatIf` and `-Confirm` support when appropriate
   - Most accept parameters or are modular for pipelining
   - Logging and error handling are included in critical scripts

---

## ⚠️ Requirements

- PowerShell 5.1+ or PowerShell 7+
- RSAT tools for AD cmdlets (on Windows)
- Microsoft Graph / Entra modules (for cloud features)
- GAM installed and configured (for Google Admin tools)

---

## 🧯 Safety First

ForestFirePS is built with guardrails — but it’s still a flame-thrower.

Please test in development environments or use `-WhatIf` mode before applying any changes in production.

> “With great power comes great responsibility. Also, backups.”

---

## 🔥 Example Tools (In Progress)

| Script | Purpose |
|--------|---------|
| `New-OnboardUser.ps1` | Fully onboard a new user (AD + cloud) |
| `Invoke-OffboardUser.ps1` | Gracefully offboard user (disable, archive, delicense) |
| `Get-LicenseSummary.ps1` | View assigned M365/Azure licenses |
| `Get-StaleUsers.ps1` | List inactive accounts across domains |
| `Test-GroupNesting.ps1` | Report nested group structures |
| `Check-UserMailboxPermissions.ps1` | Asks for a mailbox, reports all shared mailboxes it has Send As and Full Access to |
| `Start-ControlledBurn.ps1` | Batch execute changes with safety flags |
| `Write-SmokeSignal.ps1` | Email or log alerts after scripted actions |
| `Write-SmokeSignal.ps1` | Email or log alerts after scripted actions |

---

## 🧼 .gitignore Example

Included to keep the repo clean:

```gitignore
*.ps1~
*.psm1~
*.log
.vscode/
.DS_Store
Thumbs.db
```

---

## 📜 License

**MIT License**  
Use it, fork it, make it better — just don’t light your production forest on fire without a plan.

---

## ☕ Contribute

Feel like writing a 🔥 function? Fork and PR it.  
Find a bug? Open an issue.  
Need a new feature? Make a request or send a smoke signal.

---

> _Because sometimes, you don’t clean up the forest — you burn it down and plant it better._

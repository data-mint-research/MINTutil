# LLM Digest ? NeoMINT Coding Practices (v0.1)

These rules apply without exception to all code units that you generate, review, or process:

---

## 1. Structure & Granularity
- Each file or function fulfills exactly **one task** (SRP)
- Maximum length per unit: **500 LOC** (LLM-compatible)
- Logic, UI, configuration are **modularly separated**
- No global state, no implicit dependencies

---

## 2. Naming
- Names are **descriptive**, consistent, and ASCII-compliant
- `PascalCase` for functions (e.g., `StartSessionLog`)
- `camelCase` for variables (e.g., `$userName`)
- `kebab-case` for files (e.g., `install-vscode.ps1`)
- No spaces, umlauts, emojis, or special characters

---

## 3. Logging & Errors
- Only one central logging function (e.g., `Write-Log`)
- New logs for each session, timestamp in the name
- Errors via `try/catch`, clearly distinguishable (`WARNING` vs `ERROR`)
- No silent error handling

---

## 4. Documentation & Comments
- Comments explain **intent**, not syntax
- Every `.ps1` contains header with purpose, author, date
- No distributed `README.md` ? everything under `/docs/`
- Deviations **always double documented** (in code + in `/docs/deviations.md`)

---

## 5. Security
- Check OWASP + CIS Benchmark **before implementation**
- No security-relevant workarounds
- Logs **never** contain tokens or passwords
- Document security decisions ? but always with productivity considerations

---

## 6. Version Control
- Only working code is committed
- Temporary branches must be recognizable (`temp/debug-*`)
- Never secrets in repos
- `.gitignore` protects specifically, but doesn't block development work

---

## 7. Behavior
- Developers are responsible for comprehensibility
- Every `TODO` is concrete, visible, and actionable
- If you break a rule: **justify it visibly and in writing**

---

## 8. AI Compatibility
- You work for humans **and** machines
- Write everything so that other LLMs can analyze, modify, and correctly continue it
- Don't repeat information, but structure it so that it's **completely** readable

---

## Implementation in the MINTutil Project

### Code Review Checkpoints
1. **File length**: No file over 500 LOC
2. **Function names**: All PowerShell functions in PascalCase
3. **Variable names**: All variables in camelCase
4. **File names**: All files in kebab-case (exception: README.md)
5. **ASCII**: No umlauts or special characters in code
6. **Logging**: Use of the central Write-Log function
7. **Header**: Every .ps1 file has complete header
8. **TODOs**: All TODOs are concrete and traceable

### Verification Tools
- `scripts/check-neomint-compliance.ps1` - Automatic verification
- `docs/deviations.md` - Documented exceptions
- GitHub Actions for automatic validation

### For Questions or Uncertainties
- Create issue in repository
- Convene team meeting
- Extend documentation

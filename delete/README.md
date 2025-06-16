# Dateien zum L?schen

Dieser Ordner enth?lt Dateien, die aus dem Repository entfernt werden sollen.

## Enthaltene Dateien:
- `.env` - Sollte niemals im Repository sein (enth?lt sensible Konfigurationsdaten)

## Wichtig:
Diese Dateien m?ssen aus der Git-Historie entfernt werden mit:
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all
```
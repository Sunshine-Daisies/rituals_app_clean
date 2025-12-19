---
description: Pushing changes to the git repository
---

This workflow automates the process of staging, committing, and pushing changes to the `main` branch.

1. Review the changes to ensure accuracy.
2. Stage all modifications and new files.
// turbo
3. Commit the changes with a descriptive message.
// turbo
4. Push the committed changes to the `main` branch on the remote repository.

```powershell
git add .
git commit -m "[type](scope): [message]"
git push origin main
```

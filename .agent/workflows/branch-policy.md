---
description: Branch creation policy - always create a branch before making code changes
---

# Branch Creation Policy

**CRITICAL**: Always create a new branch before making any code changes in this repository.

## Steps

1. Check current branch status
```bash
git status
```

2. Ensure you're on the main/master branch and it's up to date
```bash
git checkout main
git pull origin main
```

3. Create a new feature branch with a descriptive name
```bash
git checkout -b feature/descriptive-branch-name
```

Branch naming conventions:
- `feature/` - for new features
- `fix/` - for bug fixes
- `refactor/` - for code refactoring
- `docs/` - for documentation changes

4. Verify you're on the new branch
```bash
git branch --show-current
```

5. Now proceed with code changes

## Important Notes

- **Never** make changes directly on main/master
- Always use descriptive branch names that reflect the work being done
- Create a new branch for each logical unit of work

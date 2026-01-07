---
description: Run full pre-commit checks before committing
---

Run the complete pre-commit workflow:

1. Run `./scripts/lint.sh` and ensure it passes with no violations
2. Run `./scripts/test-quick.sh` and ensure all unit tests pass
3. If both pass, report success and confirm ready to commit
4. If either fails, report the specific failures and suggest fixes

This is MANDATORY before any commit. Do not skip any steps.

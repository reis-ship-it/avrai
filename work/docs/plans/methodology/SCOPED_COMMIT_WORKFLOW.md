# Scoped Commit Workflow

Use this workflow to avoid accidental mixed commits when the working tree is noisy.

## Rule

- Never run `git commit` directly for scoped changes.
- Use `scripts/git/commit_scoped.sh`.

## Command

```bash
scripts/git/commit_scoped.sh "refactor(scope): message" path/to/file1 path/to/file2
```

## What it guarantees

1. Clears the git index first with `git restore --staged :/`.
2. Stages only the explicit paths you pass.
3. Verifies staged files exactly match requested paths.
4. Commits only that scoped set.

If the staged set differs, it fails before commit.

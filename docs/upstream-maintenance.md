# Upstream Maintenance

VaDa Symphony Jira Workflow is upstream-first. The orchestration core should stay close to
OpenAI Symphony, while local changes should concentrate on Jira support, ENV/Docker runtime setup,
tests, and operational documentation.

## Recommended Remotes

```bash
git remote rename origin upstream
git remote add origin https://github.com/itilys/vada-symphony-jira-workflow.git
git remote -v
```

If your local checkout still points at the original bootstrap repository name, update `origin` to the
current public URL:

```bash
git remote set-url origin https://github.com/itilys/vada-symphony-jira-workflow.git
```

## Sync From OpenAI Symphony

```bash
git fetch upstream
git checkout main
git merge --ff-only upstream/main
git rev-parse HEAD > UPSTREAM_SHA
```

If `main` contains local commits, use a dedicated sync branch instead:

```bash
git fetch upstream
git checkout -b sync/openai-symphony-YYYYMMDD
git merge upstream/main
```

After resolving conflicts:

```bash
cd elixir
mise exec -- mix format --check-formatted
mise exec -- mix test
mise exec -- mix compile --warnings-as-errors
```

## Push To Itilys

```bash
git push origin main
```

If the remote repository only contains the initial license commit and this repository history starts
from OpenAI Symphony, the first push may need to be a conscious replacement:

```bash
git push origin main --force-with-lease
```

Use `--force-with-lease`, not `--force`, so Git refuses to overwrite unexpected remote work.

## Pull Request Checklist

- State the OpenAI Symphony upstream SHA.
- Explain any changes outside Jira, tracker abstraction, ENV/Docker, tests, or docs.
- Confirm `tracker.kind: linear` still works.
- Confirm `tracker.kind: memory` still works.
- Confirm `tracker.kind: jira` config validates.
- Include test evidence.
- Mention security or secret-handling impact.

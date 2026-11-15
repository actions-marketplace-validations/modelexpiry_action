# ModelExpiry for GitHub Actions

Fail a pull request that adds an AI model ID its provider is retiring, before calls to it start failing in production.

- **Annotations** on the lines, with the shutdown date, the official replacement and the provider's source.
- **Diff mode** on pull requests: only the model IDs a pull request adds can fail it, not the ones already in the repository.
- **A job summary** listing every retiring model in the repository: model, shutdown date, replacement, files.
- **SARIF** for GitHub code scanning.

Your code never leaves the runner: the Action runs the [`modelexpiry`](https://www.npmjs.com/package/modelexpiry) CLI there, and its only request is a download of the public registry, [modelexpiry.com/registry.json](https://modelexpiry.com/registry.json).
Every date in it links to the provider's own deprecation page: see [modelexpiry.com/deprecations](https://modelexpiry.com/deprecations).
Only IDs the registry knows are reported, so a model it does not know is never a false alarm.

## Usage

```yaml
name: Model lifecycle

on:
  pull_request:
  schedule:
    - cron: "0 8 * * 1" # every Monday: the whole repository, as dates come closer

permissions:
  contents: read

jobs:
  models:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: modelexpiry/action@v1
```

On a pull request, the job fails when the pull request adds a model ID that is retired, or shuts down within 90 days.
On the weekly run, it fails when any model ID in the repository does, and GitHub emails you about it.

### With code scanning

```yaml
jobs:
  models:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v7
      - uses: modelexpiry/action@v1
        with:
          fail-on: none
          sarif-file: modelexpiry.sarif
      - uses: github/codeql-action/upload-sarif@v4
        with:
          sarif_file: modelexpiry.sarif
```

## Inputs

| Input        | Default                        | Meaning                                                                                                                                     |
| ------------ | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `fail-on`    | `retiring`                     | `retired`: already shut down. `retiring`: shut down, or shuts down within `warn-days`. `deprecated`: any shutdown date. `none`: never fail. |
| `warn-days`  | `warn_days` in config, else 90 | For `retiring`, the days before a shutdown that count.                                                                                      |
| `diff-only`  | `true`                         | On pull requests, fail only on model IDs in the lines the pull request changes.                                                             |
| `base`       | the pull request's base        | The commit `diff-only` compares to.                                                                                                         |
| `directory`  | `.`                            | The directory to scan.                                                                                                                      |
| `config`     | `.modelexpiry.yml`             | The config file: `fail_on`, `warn_days`, `channel`, `ignore`, `aliases`.                                                                    |
| `sarif-file` |                                | Also write a SARIF 2.1.0 report there.                                                                                                      |
| `registry`   | modelexpiry.com                | A mirror of `registry.json` (URL) or a copy of it (path).                                                                                   |
| `version`    | pinned per release             | The `modelexpiry` CLI version to run.                                                                                                       |

Mentions in comments and docs are annotated but never fail the job.

## Fix what it finds

```sh
npx modelexpiry fix      # swaps each retiring ID for its replacement, and nothing else
npx modelexpiry prompt   # or hand the migration to your coding agent
```

The [ModelExpiry GitHub App](https://modelexpiry.com) opens those pull requests for you, and keeps a retirement report up to date in each repository.

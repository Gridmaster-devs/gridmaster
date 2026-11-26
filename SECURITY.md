# Security Policy

## Supported versions

Gridmaster is deployed continuously from the `main` branch. We fix security
issues only in the latest `main` and the live deployment built from it. We do
not patch older commits or forks.

## Reporting a vulnerability

**Do not report security vulnerabilities in public issues, pull requests or
discussions.**

Report them privately through GitHub:

1. Go to the repository's **Security** tab.
2. Click **Report a vulnerability**.
3. Fill in the form.

Your report is visible only to you and the maintainers.

Please include:

- The affected part (game server, web client, editors, game definition files,
  build or deployment configuration).
- Steps to reproduce, or a proof of concept.
- What an attacker could do with it.
- The commit or date of the version you tested.

## Scope

In scope:

- The game server (`grid-master-app/server/`).
- The web game client and the editors.
- Loading and transferring game definition files.
- Build and deployment configuration in this repository (Dockerfiles,
  `infra/`, `.github/workflows/`).

Out of scope:

- Any testing against servers or services we host.
- Social engineering of maintainers or players.
- Vulnerabilities in third-party software, such as the Godot engine or
  Azure. Please report those to their maintainers.

## Testing guidelines

Do not test against any server or service we host. Run your own local copy
of the code instead (see `docs/integration-testing.md`).

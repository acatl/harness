# Security Policy

This repo is a set of Claude Code skills — Markdown prompts, a few shell scripts (`scripts/`), and
CI config. The realistic attack surface is: a skill instructing an unsafe action, or a shell script
run in CI/locally doing something it shouldn't.

## Reporting a Vulnerability

Please **do not** open a public issue for a security concern.

- Preferred: on this repo's **Security** tab, choose **"Report a vulnerability"** (GitHub private
  vulnerability reporting). Navigation-based so it survives a repo rename/transfer.
- Fallback: email [acatl.pacheco@gmail.com](mailto:acatl.pacheco@gmail.com) with a description and,
  if possible, reproduction steps.

You should expect an initial response within 5 business days.

## Scope

- Skill content (`skills/**/SKILL.md`, `templates/`, `rules/`) that could instruct unsafe or
  destructive actions.
- Shell scripts (`scripts/*.sh`) and CI workflows (`.github/workflows/*.yml`).

Out of scope: vulnerabilities in upstream dependencies (report those upstream — e.g.
[OpenSpec](https://github.com/Fission-AI/OpenSpec/security)) or in Claude Code itself (report via
Anthropic's channels).

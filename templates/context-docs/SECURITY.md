<!-- HARNESS TEMPLATE — author this file, then delete this line. harness:init will not proceed while this marker is present. -->
# Security

The attack/risk surface and the rules that contain it. Input for security review. State the defining risk fact
up front: where untrusted input enters and what boundary it crosses.

## Trust boundaries

- Where trusted and untrusted contexts meet; what is allowed to cross each.
- The containment rules at each boundary (what a component may/may not reach).

## Untrusted input

- Every source of attacker- or user-controlled data and how it's handled.
- Validation/sanitization rules — validate before acting; never pass raw input into a sink (path, query, eval, render).

## Secrets & credentials

- What secrets exist, where they live, how they're loaded — and how they must NOT (no hardcoding, no logging, no commit).

## Sensitive-data handling

- What data is sensitive, where it may be stored, and the rule against widening it (no telemetry/upload/exfil without approval).
- Supply-chain rule: how external assets/deps are pinned and verified; a bump is a surface-changing action.

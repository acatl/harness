# Sensor baseline matrix

Per-stack expected toolchain `harness:init` (Step 2a) assesses the project against. For each sensor:
the expected tool + how to detect it (config file / dep / script).

**Tiers:**
- **Essential — HARD-STOP if missing:** build/compile gate · test runner · linter · type-check.
- **Recommended — WARN, proceed:** formatter · structured logging.
- **logging is warn/ASK** — no canonical marker, undetectable; ask the operator, never hard-stop.
  It feeds behavioral-verify's log signal.

**Compiled-stack rule:** for compiled stacks the build gate IS the type-check (`swift build`,
`cargo build`, `go build`) — don't double-count, don't double-stop. type-check hard-stops only as a
*separate* expected gate (`tsc`, `mypy`) when absent.

---

## Swift
| sensor | tier | expected | detect |
| --- | --- | --- | --- |
| build | essential | `swift build` | `Package.swift` |
| test | essential | `swift test` | `Tests/` dir |
| lint | essential | SwiftLint | `.swiftlint.yml` / `.tools/swiftlint` |
| type-check | essential | via `swift build` (compiled — no separate gate) | — (covered by build) |
| format | recommended | swift-format | `.swift-format` |
| logging | recommended (warn/ask) | `os.Logger` / structured log sink | no marker — ask |

## Node / TypeScript
| sensor | tier | expected | detect |
| --- | --- | --- | --- |
| build | essential | build script / bundler | `package.json` `build` script / bundler config |
| test | essential | jest / vitest / `node --test` | test config or `test` script / `__tests__` |
| lint | essential | ESLint / Biome | `eslint.config.*` / `.eslintrc*` / `biome.json` |
| type-check | essential (SEPARATE gate) | `tsc` | `tsconfig.json` |
| format | recommended | Prettier | `.prettierrc*` |
| logging | recommended (warn/ask) | logger dep (pino / winston) or console policy | dep or no marker — ask |

## Rust
| sensor | tier | expected | detect |
| --- | --- | --- | --- |
| build | essential | `cargo build` | `Cargo.toml` |
| test | essential | `cargo test` | `Cargo.toml` / `tests/` dir |
| lint | essential | clippy | `cargo clippy` available |
| type-check | essential | via `cargo build` (compiled — no separate gate) | — (covered by build) |
| format | recommended | rustfmt | `rustfmt.toml` / `cargo fmt` available |
| logging | recommended (warn/ask) | `log` / `tracing` crate | dep or no marker — ask |

## Go
| sensor | tier | expected | detect |
| --- | --- | --- | --- |
| build | essential | `go build` | `go.mod` |
| test | essential | `go test` | `go.mod` / `_test.go` files |
| lint | essential | `go vet` / golangci-lint | `.golangci.yml` / `go vet` available |
| type-check | essential | via `go build` (compiled — no separate gate) | — (covered by build) |
| format | recommended | gofmt | `gofmt` available |
| logging | recommended (warn/ask) | `slog` | dep or no marker — ask |

## Python
| sensor | tier | expected | detect |
| --- | --- | --- | --- |
| build | essential | build/package gate | `pyproject.toml` / `setup.py` |
| test | essential | pytest / unittest | `pytest.ini` / `pyproject.toml` `[tool.pytest]` / `tests/` |
| lint | essential | ruff / flake8 | `ruff.toml` / `.flake8` / `pyproject.toml` config |
| type-check | essential (SEPARATE gate) | mypy / pyright | `mypy.ini` / `pyrightconfig.json` / `pyproject.toml` config |
| format | recommended | black / ruff format | `pyproject.toml` `[tool.black]` / ruff config |
| logging | recommended (warn/ask) | `logging` | no marker — ask |

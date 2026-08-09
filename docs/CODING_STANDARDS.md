# GLB Coding Standards

**Version:** 0.1
**Status:** Living Document

---

# Purpose

This document defines the coding standards used throughout the GLB project.

The goal is to keep the codebase readable, maintainable, and consistent regardless of who contributes to the project.

When in doubt:

> **Choose clarity over cleverness.**

---

# General Principles

* Every module has a single responsibility.
* Every function should do one job.
* Avoid duplicated code.
* Prefer readability over short code.
* Keep modules small and focused.
* Every new feature should be testable.

---

# Project Structure

```
GLB/
├── completions/     # bash/zsh/fish completion scripts for `glb` itself
├── docs/            # documentation, including docs/design/ for feature
│                     #   design docs and docs/reference/ for cheat sheets
├── lib/              # library modules, sourced by the `glb` dispatcher
├── profiles/         # named profiles (default, developer, server), each
│                     #   with packages.txt/extras.txt/dotfiles
├── snapshots/         # glb export output (machine state snapshots), when present
├── tests/             # bats test suite
├── glb
├── README.md
├── CHANGELOG.md
├── LICENSE
└── VERSION
```

New modules belong in the `lib/` directory unless there is a clear reason otherwise.

---

# Naming Conventions

## Public Functions

Every public function begins with:

```
glb_
```

Examples:

```
glb_show_banner
glb_log_info
glb_log_error
glb_detect_os
glb_install_fish
```

## Private Functions

Internal helper functions begin with:

```
_glb_
```

Examples:

```
_glb_color
_glb_print_prefix
```

---

# Variables

Global variables should be limited and use uppercase names.

Examples:

```
GLB_ROOT
GLB_VERSION
GLB_CONFIG_DIR
```

Function-local variables should always use:

```
local variable_name
```

---

# Shell Standards

* Target Bash 5.x or newer.
* Start executable scripts with:

```bash
#!/usr/bin/env bash
```

* Enable strict mode unless there is a documented reason not to:

```bash
set -euo pipefail
```

* Quote variable expansions unless word splitting is explicitly required.

Good:

```bash
"$GLB_ROOT"
```

Avoid:

```bash
$GLB_ROOT
```

---

# Function Design

Functions should:

* Perform one task.
* Return meaningful exit codes.
* Print through the logging module rather than using `echo` directly.

Example:

```
glb_log_info "Installing Fish..."
```

instead of:

```
echo "Installing Fish..."
```

---

# Error Handling

Every module should:

* Validate inputs.
* Return non-zero on failure.
* Produce clear error messages.
* Never fail silently.

---

# Logging

All user-facing output should be handled through the logging library.

Supported log levels:

* INFO
* SUCCESS
* WARNING
* ERROR
* DEBUG

---

# Module Design

Each library module should focus on one responsibility.

Examples:

```
banner.sh
logging.sh
detect.sh
utils.sh
```

As GLB grows:

```
package.sh
git.sh
ssh.sh
fish.sh
zsh.sh
ranger.sh
fresh.sh
```

---

# Comments

Every module begins with a standard project header.

Public functions should include a brief description explaining their purpose.

Comments should explain **why**, not simply repeat **what** the code does.

---

# Git Workflow

Every development session follows the same pattern:

1. Review repository status.
2. Select one milestone.
3. Implement one module or feature.
4. Test.
5. Commit.
6. Update the changelog if appropriate.

---

# Development Philosophy

GLB is intended to be a reusable, cross-distribution Linux workstation bootstrap and customization framework.

Every manual workstation setup step should eventually become an automated GLB feature.

The project values:

* Simplicity
* Reliability
* Repeatability
* Modularity
* Maintainability

over shortcuts or unnecessary complexity.

---

# Future Revisions

This document is expected to evolve as GLB grows. New standards should improve consistency while preserving backward compatibility whenever practical.


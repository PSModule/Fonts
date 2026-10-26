# Contributing

Fonts welcomes bug reports, feature requests, documentation improvements, and code contributions.
Read the [README](README.md), search [existing issues](https://github.com/PSModule/Fonts/issues), and open an issue
when you need to report a problem or discuss a change. Include the module version, PowerShell version, operating system,
expected and actual behavior, and steps to reproduce the problem. Remove secrets and personal information from logs.

Follow the [code of conduct](CODE_OF_CONDUCT.md). Use the private reporting route in [SECURITY.md](SECURITY.md) for
security vulnerabilities and [SUPPORT.md](SUPPORT.md) for support questions.

## Making a change

1. Start a focused branch from `main`.
2. Follow the canonical [repository standard](https://psmodule.io/Process-PSModule/reference/repository-standard/)
   and [PowerShell module standard](https://psmodule.io/Process-PSModule/reference/powershell-module-standard/),
   subject to the PowerShell compatibility exception below.
3. Keep module source under `src/`, behavioral tests under `tests/`, and realistic usage examples under `examples/`.
   Declare external module dependencies with `#Requires -Modules` in the function files that use them.
   The build collects those declarations into the compiled manifest; do not add `RequiredModules` to `src/manifest.psd1`.
4. Add or update tests and comment-based help for changed behavior. Test files use
   `#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.1.0'; MaximumVersion = '6.*' }`.
5. Run the relevant checks in an isolated environment as described below, then open a draft pull request against `main`.
   Describe the user-facing outcome and include validation results and any unavailable platform checks.
   Push focused commits and address review feedback before a maintainer moves the pull request to ready for review.

The [MSX contribution workflow](https://msx.no/docs/Ways-of-Working/Contribution-Workflow/) and
[PR format](https://msx.no/docs/Ways-of-Working/PR-Format/) provide the shared review and pull request conventions.

## PowerShell 5.1 compatibility exception

Fonts retains Windows PowerShell 5.1 support and `PowerShellVersion = '5.1'` in `src/manifest.psd1`.
This is an explicitly approved repository exception to Process-PSModule's latest-LTS-only runtime policy.
Framework and template upgrades must preserve this minimum runtime and existing module behavior.

Keep shipped source compatible with Windows PowerShell 5.1 and its .NET Framework APIs.
Do not introduce PowerShell Core-only syntax or APIs, remove Desktop support, or raise the manifest's minimum version
as part of framework alignment. Any change to this compatibility commitment requires a separate, explicit decision.

Build tools and Pester tests follow the current framework's tooling requirements; those requirements do not change
the module's supported runtime. Current-PowerShell parsing, static compatibility checks, and the normal cross-platform
pipeline are useful checks, but they do not prove execution on Windows PowerShell 5.1.
When changing shipped code, verify the built module's import and affected commands with Windows PowerShell 5.1
on an isolated Windows host. Report unavailable minimum-runtime validation explicitly.

## Validation and font safety

[Process-PSModule](https://psmodule.io/Process-PSModule/guides/calling-the-workflow/) runs the repository's build,
source checks, module tests, coverage checks, and documentation build. Repository overrides live in `.github/PSModule.yml`;
the coverage target is 80%. Important-file patterns include source, README, tests, workflow/settings files, linter settings,
and the Zensical site configuration.

The existing `tests/Fonts.Tests.ps1` suite installs and uninstalls fonts. Run it only on a disposable runner or with the
built module's font-folder and registry boundaries redirected to test-owned temporary locations.
Isolate registry operations and font-cache refreshes as needed for the platform. Do not point local tests at your real
user or system font folders, and do not run them elevated on a normal workstation.
Preserve installed fonts and restore any test-specific mappings after the run.

Use the [module-test guide](https://psmodule.io/Process-PSModule/guides/writing-module-tests/) for Pester discovery and
test setup. Structural checks such as `git diff --check` and `actionlint .github/workflows/Process-PSModule.yml`
do not require font installation.

The documentation site uses `.github/zensical.toml`. The workflow stages generated command help, the README, and the icon
under `.PSModule/site/docs`, then builds the staged configuration with Zensical.
Keep generated `.PSModule/` artifacts out of commits.

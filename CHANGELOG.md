# CHANGELOG

## Unreleased
- fix: `ensure => latest` no longer upgrades on every run, nor fails, with the `homebrew` and `brewcask` providers: `latest` relied on parsing `brew info`'s text output
- change: brew now decides which packages are outdated (`brew info` / `brew outdated` JSON, one set of calls per run); an up-to-date or pinned package keeps its installed value
- change: packages from an untrusted tap are no longer upgraded; a warning is logged instead
- fix: a failed `latest` query reports brew's error; `brewcask` raises instead of triggering an upgrade

## 3.2.0 (2026-09-15)
- fix: installing on Intel failed with `Homebrew on macOS is only supported on Apple Silicon processors!` — Homebrew/install dropped x86_64 on 2026-09-11 (`e078684`), with no opt-out and no `/usr/local` prefix. The installer is now pinned **on Intel only** to `0f5b7666`, the last commit that supports it (it knows macOS 27 and checks out the latest brew tag); Apple Silicon keeps `HEAD`. `brew` itself still runs on Intel, as a Tier 3 platform
- fix: `homebrew::install` decides everything architecture-dependent from a single `if $facts['is_arm64']`. The installer URL came from a separate `true =>` selector, which a stringified fact (cached `facts.yaml`, ENC or PuppetDB) made disagree with the prefix test: `/opt/homebrew` together with the x86_64-pinned installer
- fix: `homebrew_tap` now trusts a tap **before** cloning it. Homebrew 7.0.0 made tap verification unconditional (`verify: true` in `cmd/tap.rb`), and `brew tap` validates a clone by loading its formulae and casks — refused for an untrusted tap, reported as `Cannot tap <name>: invalid syntax in tap!`, clone deleted, so the resource failed identically on every run. Trust used to be applied after the tap, i.e. never
- fix: a tap with a custom `url` records trust against that URL rather than the `user/repo` name. Homebrew matches a name entry only against the canonical `github.com/user/homebrew-<repo>` remote (`Tap#matches_reference?`) and cannot resolve the real remote before the clone, so the URL has to be passed explicitly
- fix: changing a tap's `url` no longer drops its `force_auto_update`. `brew tap --custom-remote` runs `config.delete(:forceautoupdate)` in `Tap#install`'s already-installed branch; the property having not drifted, it was never re-applied — Puppet reported the resource converged while the tap had stopped refreshing on `brew update`
- fix: changing a tap's `url` no longer untrusts it. Trust is keyed on the remote and migrated only when git reports a redirect, so the entry for the previous URL stopped matching and none existed for the new one. `trust` is now re-applied after a URL change and the stale entry revoked
- internal: in the property-update path, `url` is applied before `trust`. `brew tap --custom-remote` does *not* re-run the tap verification (`Tap#install` returns from its already-installed branch before the `Readall` check), so an untrusted tap's remote can be corrected, and trusting afterwards leaves no entry for a remote the tap never adopted
- fix: `homebrew_tap` reports tap-info's `trusted` as read instead of the value that was asked for, and warns when the two disagree — naming the causes that are otherwise invisible: an `url` that does not match the remote byte for byte (outside github.com, gitlab.com and codeberg.org a `.git` suffix or trailing slash is significant) and the per-user trust store (Puppet writes the brew owner's `~/.homebrew/trust.json`)
- fix: `trust => false` revokes every reference the entry may be recorded under, the `user/repo` name as well as the known URLs. Homebrew deletes an exact string, so a bare-name entry — what an earlier release recorded before the clone — survived a URL-keyed revocation; a missing entry exits 0, so the extra calls are idempotent
- fix: `ensure => absent` revokes trust when this resource manages it. `brew untap` leaves the trust store untouched, so the entry outlived the tap and silently trusted a later re-tap of the same URL
- improvement: a tap failure points at the trust check only when brew's output names an untrusted tap, or when trust is not granted here. `brew tap` reports *any* formula or cask it cannot load as `Cannot tap <name>: invalid syntax in tap!`, so a genuine syntax error is no longer blamed on trust; when it is the trust check, the error names `trust => true` and the URL the entry will be recorded under
- improvement: `homebrew_tap` reads each tap's remote from `brew tap-info --installed --json` instead of a `git config` per tap — half the privileged subprocesses per run, and no git "dubious ownership" refusal on a clone owned by another user. The git read remains as a fallback
- fix: the `homebrew` package provider no longer aborts every run with `Could not prefetch package provider 'homebrew': No resource and no name in property hash`, preceded by `Could not match <tap file>:<line>` warnings. Listing packages loads every tap's formulae and casks, and brew writes each deprecation it meets to stderr, which Puppet merges into stdout: those lines parsed as phantom packages and `nil` entries, and a single `nil` fails the prefetch of *every* package in the catalog — hence unrelated resources reporting `Skipping because provider prefetch failed`. brew's stderr is now kept out of every parsed listing and unparseable lines are discarded
- fix: the `homebrew` package provider builds its inventory from `brew list --json --versions` when brew can serve it, falling back to the text listing. The JSON form does not abort with `Error: Cask <token> exists in multiple taps` when two taps ship the same cask token, and is one invocation instead of two. It needs `jq` — brew serves `--json` only from its Bash fast path (`Library/Homebrew/list.sh`), and `cmd/list.rb` raises a `UsageError` for it — which macOS ships only from 15 on, hence the fallback rather than a hidden `jq` dependency
- fix: the `brewcask` and `brew` package providers are hardened the same way: brew's stderr stays out of the parsed listings, a blank line no longer produces an empty `Could not match` warning, and neither can carry a `nil` into the instance list. `brewcask` shares the JSON-with-text-fallback listing (`brew_list_json` in `PuppetX::Homebrew::BrewCommand`) and truncates the version exactly as its text parser and `latest` do — `docker-desktop 4.89.0,238018` stays `4.89.0` — so `ensure => latest` no longer upgrades on every run. Its single-package lookup also stops treating a not-yet-installed cask as an error

## 3.1.3 (2026-09-14)
- fix: brew commands no longer abort with `getcwd: cannot access parent directories` and `USER: unbound variable` — every privileged brew invocation now runs with a cwd the brew owner can read (their home, `/tmp` as fallback) and with `USER`/`LOGNAME` set, which a launchd-started Puppet agent does not provide. Affects every brew-invoking provider: the `brew`, `homebrew`, `brewcask` and `tap` package providers and the `homebrew_tap`, `homebrew_pin`, `homebrew_service` and `homebrew_bundle` types

## 3.1.2 (2026-07-20)
- feature: `homebrew_environment` (and `github_token`) now also write `$HOME/.homebrew/brew.env`, the file Homebrew (>= 4.1) natively reads on startup — the mechanism actually honored by `brew` invocations, unlike `/etc/environment` which macOS doesn't read automatically. New optional `user_home` parameter overrides the assumed `/Users/<user>` home directory for non-standard accounts
- internal: environment-variable-to-line formatting is now computed once and shared between `/etc/environment` and `brew.env` to avoid the two files drifting out of sync

## 3.1.1 (2026-07-08)
- fix: the `homebrew` package provider now falls back to a cask lookup when a formula is not found, so installed casks are reported accurately
- internal: `run_brew` accepts a `failonfail` parameter so expected non-zero exit codes are treated as normal outcomes, plus improved debug logging for package installation status
- fix: the `install-clt` exec now uses `/bin/test` instead of `/usr/bin/test` in its `unless` guard for Command Line Tools installation compatibility

## 3.1.0 (2026-07-07)
- feature: optional idempotent `brew update` to refresh taps, via the new opt-in `homebrew::update` class and the `manage_update` / `update_frequency` parameters on the `homebrew` class (#4)
- internal: the update runs at most once per interval (guarded by a timestamp marker) so it produces no per-run `changed` churn, is bounded by a finite `timeout`, and swallows transient failures for retry on the next run

## 3.0.0 (2026-07-06)
- feature: native `homebrew_tap` type/provider for managing taps, including custom (non-GitHub/private) git remotes with in-place drift correction and tap priority (#3)
- feature: native `homebrew_pin` type/provider to pin/unpin installed formulae against `brew upgrade`
- feature: native `homebrew_service` type/provider to manage `brew services` daemons (running/stopped)
- feature: native `homebrew_bundle` type/provider to apply a `Brewfile` declaratively (idempotence via `brew bundle check`)
- feature: `is_arm64` fact and Apple Silicon support (`/opt/homebrew` prefix) across install and all providers
- internal: shared `PuppetX::Homebrew::BrewCommand` mixin — brew commands drop privileges to the brew owner and set `HOMEBREW_NO_AUTO_UPDATE=1` on reads; brew/brewcask/homebrew/tap package providers refactored on top of it
- compatibility: now requires Puppet >= 8, Ruby >= 3.2, and puppetlabs/stdlib >= 9 (breaking)

## 1.9.1 (2021-09-23)
- internal: fixup overly-narrow stdlib version pin
- feature: upgrade casks

## 1.9.0 (2021-04-21)
- fix: update cask syntax for brew changes (#144) ([6a273ca4](6a273ca4))
- fix: fixup "ensure" for specific version pins (#114) ([defc03f3](defc03f3))
- internal: build via pdk (#122) ([07607a68](07607a68))
- internal: fixup linters and test matrix for newer ruby versions

## 1.8.3
- fix: avoid mangling names when resource target is a url (#110)

## 1.8.2
- compatibility: first release to officially support Puppet 5 (previous versions worked unofficially)

## 1.8.1
- fix: fix installation of first-ever Brew package on machine (#98)

## 1.8.0
- feature: support multi-user environments with new `$multiuser` flag (#89)
- fix: support for High Sierra
- compatibility: drop support for Puppet 3

## 1.7.1
- fix: include ruby 1.8.3 in metadata.json
- compatibility: last release to include Puppet 3 support

## 1.7.0
- feature: allow usage within non-brew and bundler environments
- feature: support ruby 1.8.3 installations
- meta: more and better linting

## 1.6.0
- feature: permission management more closely aligns to brew install
- bugfix: ensure providers load regardless of configured puppet load order
- bugfix: ensure facts work on all puppet versions
- bugfix: ensure packages with 'homebrew-' prefix are not re-installed
- bugfix: do not allow homebrew root install

## 1.5.0
- feature: allow package to set HOMEBREW_GITHUB_API_TOKEN
- feature/bugfix: stop parsing homebrew output, parse response codes instead
- bugfix: manage /usr/local/Homebrew rather than parent directory
- meta: speed up tests

## 1.4.3
- bugfix: manage objects (packages, taps, etc) case-insensitively
- meta: deprecate root-owned homebrew
- meta: clean up tests

## 1.4.2
- bugfix: fixed bug where brew-cask provider didn't work the first time
- meta: updated to new homebrew install location

## 1.4.1
- feature: allow usage by any member of homebrew group

## 1.4.0
- feature: remove files with invalid checksums for easier retrying
- bugfix: ensure `install_options` propgates correctly
- bugfix: detect and fail properly on checksum errors
- meta: include README section on ordering taps/packages

## 1.3.3
- feature: allow user/group override
- bugfix: remove `err` from facter code

## 1.3.2
- bugfix: fix compat issues for facter booleans
- bugfix: use puppet warning over ruby warn

## 1.3.1
- bugfix: only download CLI tools if values are set
- meta: move away from params class

## 1.3.0
- feature: allow users to manage taps
- meta: better testing, OSX-specific tests on Travis
- meta: fix typos, add contributer list

## 1.2.0
- bugfix: set directory permissions to brew defaults
- bugfix: fix brewcask parsing
- meta: enable auto-testing

## 1.1.1
- bugfix: ensure brew is called with correct user

## 1.1.0
- feature: add install_options
- feature: add upgradeable
- tech debt: clean up inheritance pattern

## 1.0.1
- documentation fixes

## 1.0.0
- initial release

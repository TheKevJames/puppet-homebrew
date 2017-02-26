# CHANGELOG

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

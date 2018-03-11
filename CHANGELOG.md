# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to
[Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 2.1.0 - Unreleased
### Added
- Added new command for easily signing and tagging multiple sustaining releases:
  `tag-sustaining-branches`

- Added experimental Bash completion support.
  See instructions at the top of `./bash_completion/wren-deploy.sh`.

### Changed
- Fixed critical regressions in `create-sustaining-branches` and 
  `delete-sustaining-branches`.
  
- Fixed failure invoking GIT when running the new 
  `capture-unapproved-artifact-sigs` command.
  
- Makes minor changes to command output to make it easier to read.

### Removed
- Deprecated BinTray credential handling, since it is no longer needed in 2.x.

## 2.0.0 - 2018-03-10
### Added
- Added this changelog file.

- Added new command for publishing archived FR artifacts:
  `deploy-consensus-verified-artifacts`

- Added new command for easily updating the dependencies trusted in the Wren
  whitelist: `capture-unapproved-artifact-sigs`

- Added missing prompts for the GPG passphrase when using compile commands.
  
- Added `help, `version`, and `--version` Commands

### Changed
- Switched release-related commands to observe `sustaining/` branches rather
  than version tags, so that they operate on releases being prepared rather
  than historical releases.

- Fixed publishing of POM-only artifacts when using `sign-3p-artifacts`.

- Renamed `preload_creds.sh` to `wren-preload-creds.sh`, to follow naming
  convention of master script.
  
- No longer require an `.rc` for several commands, including:
  - `deploy-consensus-verified-artifacts`
  - `sign-tools-jar`
  - `version`
  - `help`

- Reorganized CLI help & parsing.

- Clarified help and docs.

### Removed
- Deprecated the `--provider` CLI Option.

- Deprecated the `PROJECTS` Constant.

- Deprecated the need for `BINTRAY_PACKAGE` and `JFROG_PACKAGE` variables in
  `.wren-deploy.rc`.

- Removed commands for deploying and deleting multiple projects in bulk
  (includes `delete-all-releases` sub-command,
  `delete_all_deployed_packages.sh`, and `deploy_all_packages.sh`.

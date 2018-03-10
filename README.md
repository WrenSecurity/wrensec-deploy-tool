# Wren Deploy
A swiss-army command-line tool for managing, compiling, and publishing multiple
versions of a Maven package and then deploying them to BinTray or JFrog.

Usage: `wren-deploy.sh <COMMAND>`

Where `COMMAND` can be any of the following:
  - `create-sustaining-branches`  
    Creates `sustaining/X.Y.Z` branches in the current package from all release
    tags in the package.

  - `delete-sustaining-branches`  
    Deletes all `sustaining/X.Y.Z` branches from the current package.

  - `patch-all-releases [SRC-REF] [STARTING-RELEASE-TAG]`  
    Cherry-picks either `HEAD` or `SRC-REF` on to all `sustaining/` release 
    branches, optionally targeting only the release identified by the specified 
    `STARTING-RELEASE-TAG` and later releases (typically to resume a cherry pick 
    after fixing conflicts).

  - `compile-all-releases`  
    Sequentially checks out each sustaining release of the current package and 
    compiles it.

  - `compile-current-release`  
    Compiles whatever version of the current package is checked out.

  - `deploy-all-releases`  
    Sequentially checks out each sustaining release of the current package, 
    compiles it, signs it, and then deploys it to JFrog.

  - `deploy-current-release`  
    Compiles whatever version of the current package is checked out, then signs 
    it and deploys it to JFrog.

  - `verify-all-releases`  
    Sequentially checks out each sustaining release of the current package and 
    verifies the GPG signatures of all its dependencies.

  - `verify-current-release`  
    Verifies the GPG signatures of all dependences for whatever version of the 
    current package is checked out.

  - `list-unapproved-artifact-sigs`  
    Lists the name and GPG signature of each artifact dependency that is not on
    the Wren whitelist. The whitelist is located at
    http://wrensecurity.org/trustedkeys.properties.

  - `capture-unapproved-artifact-sigs WRENSEC-HOME-PATH [--push] [--amend] [--force]`
    Appends the name and GPG signature of each artifact dependency to the 
    whitelist in a checked-out copy of the `wrensec-home` project, then commits 
    the change. This can be used to rapidly add multiple artifacts to the 
    whitelist with a minimum of manual effort.

    **Options:**
    - `--push`
      Pushes the resulting changes to the default remote of the `wrensec-home`
      project.

    - `--amend`
      Amends the previous commit of the 'wrensec-home' project, instead of 
      creating a new commit. Used with caution, this option allows a maintainer 
      to iterate on dependency signatures for an artifact as build failures are
      encountered during re-packaging.

    - `--force`
      When used with --push, the last commit is force-pushed to the default 
      remote. This should be used with caution as it re-writes repository 
      history and can result in a loss of other changes in the project if 
      multiple maintainers are making changes in the repository at the same 
      time.

  - `sign-3p-artifacts`  
    Generates GPG signatures for all unsigned third-party artifacts using the 
    Wren Security third-party key, then deploys the artifacts to JFrog.

  - `sign-tools-jar`  
    Generates a GPG signature for the version of the JDK `tools.jar` currently 
    in use on the local machine using the Wren Security third-party key, then 
    deploys the artifact signature (not the JAR itself) to JFrog.

In addition, a `.wren-deploy.rc` file must exist in the current working
directory in order for the package in the current directory to be deployable. At
a minimum, the file must export the variable `MAVEN_PACKAGE`. It can optionally
export `MVN_COMPILE_ARGS` to modify the command line passed to Maven during 
compilation. Finally, it can also define the function 
`package_accept_release_tag()` in order to control which release tags are 
processed; if the function is not defined, all releases are processed, by
default.

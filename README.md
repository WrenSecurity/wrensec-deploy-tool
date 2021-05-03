# Wren Deploy
A swiss-army command-line tool for managing, compiling, and publishing multiple
versions of a Maven package and then deploying them to JFrog.

Usage: `wren-deploy.sh <COMMAND>`

Where `COMMAND` can be any of the following:
  - `create-sustaining-branches`  
    Creates `sustaining/X.Y.Z` branches in the current package from all release
    tags in the package.
    
  - `tag-sustaining-branches`  
    Tags all `sustaining/X.Y.Z` branches of the current package. Each tag is 
    annotated and signed with the GPG signature of the current GIT user.

    Before running this command, you will need to generate a GPG
    key with `gpg --gen-key` and then set that as your GIT
    signing key with:

    ```
      git config --global user.signingkey KEY_ID
    ```

    With KEY_ID being the ID of the key (e.g. `1FA76C5D`).

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

  - `capture-unapproved-artifact-sigs WRENSEC-WHITELIST-PATH
      [--push] [--force-amend] [--force]`  
    Appends the name and GPG signature of each artifact dependency to the 
    whitelist in a checked-out copy of the `wrensec-pgp-whitelist` project, then 
    commits the change. This can be used to rapidly add multiple artifacts to 
    the whitelist with a minimum of manual effort.

    **Options:**
    - `--push`  
      Pushes the resulting changes to the default remote of the 
      `wrensec-pgp-whitelist` project.

    - `--force-amend`  
      Forcibly amends the previous commit of the `wrensec-pgp-whitelist` 
      project, instead of creating a new commit.

      Amending allows a maintainer to iterate on dependency signatures for an 
      artifact as he or she encounters build failures while preparing a release 
      of the artifact.

      This tool automatically determines if it should amend the last commit or 
      create a new commit, based on the subject line of HEAD. Therefore, it is 
      typically not necessary to use this option unless automatic commit 
      handling is not working properly. Use with care to avoid rewriting the
      history of commits that have already been shared.

    - `--force`  
      When used with `--push`, the last commit of the `wrensec-pgp-whitelist` 
      project is force-pushed to the default remote. This should be used with 
      caution as it re-writes repository history and can result in a loss of 
      other changes in the project if multiple maintainers are making changes in 
      the repository at the same time.

  - `deploy-consensus-verified-artifacts 
       --repo-root=REPO-ROOT-PATH SEARCH-PATH  
       [--packaging=jar|pom|zip]`

    Searches `SEARCH_PATH` for all deployable artifacts, interpreting 
    `REPO-ROOT-PATH` as the root of the archived repository (i.e. this is the 
    equivalent to `~/.m2/repository`, but for an archived copy of a maven 
    repository). Each artifact recognized is copied to a temporary folder, 
    signed using the Wren Security third-party key, then deployed to JFrog 
    under this project:
    https://wrensecurity.jfrog.io/artifactory/forgerock-archive.
    
    For example, this would deploy `form2js` from a local Maven repository
    archive located in `./forgerock-archive`:
    ```
      wren-deploy deploy-consensus-verified-artifact \
        --repo-root=./forgerock-archive \
        ./forgerock-archive/org/forgerock/commons/ui/libs/form2js
    ```

    The optional `--packaging` parameter can be used if there is a difference 
    between the packaging specified in the POM file and the desired file 
    extension on the remote server. For example, OSGi packages for Apache Felix
    often have a POM packaging of 'bundle' but need to be deployed as a JAR.


  - `sign-3p-artifacts`  
    Generates GPG signatures for all unsigned third-party artifacts using the 
    Wren Security third-party key, then deploys the artifacts to JFrog.

  - `sign-tools-jar`  
    Generates a GPG signature for the version of the JDK `tools.jar` currently 
    in use on the local machine using the Wren Security third-party key, then 
    deploys the artifact signature (not the JAR itself) to JFrog.

  - `version` or `--version`  
    Displays the version number of Wren Deploy.


  - `help` or `--help`  
    Displays command usage text.

In addition, a `.wren-deploy.rc` file must exist in the current working
directory in order for the package in the current directory to be deployable. At
a minimum, the file must export the variable `MAVEN_PACKAGE`. It can optionally
export `MVN_COMPILE_ARGS` to modify the command line passed to Maven during 
compilation. Finally, it can also define the function 
`package_accept_release_tag()` in order to control which release tags are 
processed; if the function is not defined, all releases are processed, by
default.

# Wren Deploy
A swiss-army command-line tool for managing, compiling, and publishing multiple
versions of a Maven package and then deploying them to BinTray or JFrog.

Usage: `wren-deploy.sh <COMMAND> [--with-provider=PROVIDER]`

Where `COMMAND` can be any of the following:
  - `create-sustaining-branches`  
    Creates 'sustaining/X.Y.Z' branches in the current package
    from all release tags in the package.

  - `delete-sustaining-branches`  
    Deletes all 'sustaining/X.Y.Z' branches from the current
    package.

  - `patch-all-releases [SRC-REF] [STARTING-RELEASE-TAG]`  
    Cherry-picks either HEAD or SRC-REF on to all release
    branches, optionally targeting only the release identified by
    the specified STARTING-RELEASE-TAG and later releases
    (typically to resume a cherry pick after fixing conflicts).

  - `compile-all-releases`  
    Sequentially checks out each release of the current package
    and compiles it.

  - `compile-current-release`  
    Compiles whatever version of the current package is checked
    out.

  - `deploy-all-releases`  
    Sequentially checks out each release of the current package,
    compiles it, signs it, and then deploys it to a provider.

  - `deploy-current-release`  
    Compiles whatever version of the current package is checked
    out, then signs it and deploys it to a provider.

  - `delete-all-releases`  
    Deletes all versions of the current package from a remote
    provider.

`PROVIDER` can be either of the following:
  - `jfrog`
  - `bintray`

In addition, a `.wren-deploy.rc` file must exist in the current working
directory in order for it to be deployable. At a minimum this file must export
the variables `BINTRAY_PACKAGE`, `JFROG_PACKAGE`, and `MAVEN_PACKAGE`, but it
can also define the function 'package_accept_release_tag()' in order to control 
which release tags are processed. If the function is not defined, by default all
release tags are processed.

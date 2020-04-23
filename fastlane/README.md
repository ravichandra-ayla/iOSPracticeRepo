fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
### ensure_repo_has_public_remote
```
fastlane ensure_repo_has_public_remote
```
Make sure the repo has the "public" remote url set correctly. Set it, if not.
### release
```
fastlane release
```
Draft, tag, and publish an existing release branch.

This lane requires that:

 - The "public" and "origin" remotes be configured for the local copy

 - Release notes have already been added to the README.md

 - Version number strings have been bumped (use the 'set_version' lane.

 - A 'release/x.y.z' branch already exists on the remote repo. (Developers should  create and merge a PR from release branch to master.) The release engineer will merge that request, then run the `fastlane release` command
### get_version_from_tag
```
fastlane get_version_from_tag
```

### release_new
```
fastlane release_new
```
Draft, tag, and publish an release branch and Github release.
### push_master_branch_to_public
```
fastlane push_master_branch_to_public
```

### push_release_branch_to_public
```
fastlane push_release_branch_to_public
```

### tag_and_release
```
fastlane tag_and_release
```
Crafts a Github release on public, with the correct release tag, and syncs it back to internal repos
### tag_only
```
fastlane tag_only
```
Used only when not crafting a Github release.  Creates release tag and syncs it to remotes.
### create_mergeback_pr
```
fastlane create_mergeback_pr
```

### check_provisional_release_tag
```
fastlane check_provisional_release_tag
```

### update_branch_specifiers
```
fastlane update_branch_specifiers
```

### remove_provisional_release_tag
```
fastlane remove_provisional_release_tag
```
If present, removes the provisional git tag used to trigger an automated release.
### untag
```
fastlane untag
```
Remove a git tag from a release.

Used to add new commits to a release after it has already been tagged.

Run the "release" lane again after new changes are added to push them.

----

## iOS
### ios run_all_tests
```
fastlane ios run_all_tests
```
Runs any tests present in project
### ios get_version
```
fastlane ios get_version
```
Display the current version number as returned from get_version_string function.
### ios show_version
```
fastlane ios show_version
```
Alias to 'get_version' for compatibility
### ios set_version
```
fastlane ios set_version
```
Set the version number for the project using provided option "version:x.y.z".
### ios set_build_tool_version
```
fastlane ios set_build_tool_version
```
Automatically set the version numbers of tools in the README.md file
### ios fasttest_core
```
fastlane ios fasttest_core
```
For internal fastfile testing.
### ios fasttest_base
```
fastlane ios fasttest_base
```

### ios preflight_checks
```
fastlane ios preflight_checks
```
Run basic verifications on app before submitting a build.
### ios get_app_store_version
```
fastlane ios get_app_store_version
```

### ios increment_build
```
fastlane ios increment_build
```
Increment to a specified build number provided as an option "build_number:xx"
### ios current_build
```
fastlane ios current_build
```
Display the currently set build number
### ios setup_install_dependencies
```
fastlane ios setup_install_dependencies
```
Run any setup scripts or dependency install routines (such as cocoapods)
### ios build_version_check
```
fastlane ios build_version_check
```

### ios beta_old
```
fastlane ios beta_old
```
Submit a new beta build to TestFlight
### ios beta
```
fastlane ios beta
```
Submit a new beta build to TestFlight
### ios applestore
```
fastlane ios applestore
```
Deploy a new version directly to the App Store
### ios fasttest
```
fastlane ios fasttest
```
Description of what the lane does
### ios ci_test
```
fastlane ios ci_test
```
Simple test to check whether the 'is_ci' fastlane conditional is functioning as expected.

----

## independent
### independent indie_test
```
fastlane independent indie_test
```
Test lane for use with platform idependent projects, such as common_sepia.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

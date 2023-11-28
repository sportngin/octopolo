Octopolo
========

[![Build Status][build_status_image]][build_status]

A set of Github workflow scripts.


### GitHub Octopolo

#### Octopolo Installation

`$ gem install octopolo`

#### GitHub Setup

Interactively set up your local machine for GitHub octopolo, including
configuring your user-level setting and setting up a GitHub API token for our
scripts to use.

    octopolo setup


#### Create New Branch

Create a new branch from the main branch and push it out to GitHub.

    new-branch bug-123-something

#### Create Pull Request for Current Branch

Create a pull-request against the project's deploy branch, associating with the
given GitHub issue, if one is provided.

    pull-request

#### Deploy Current Branch to Staging

From within a bugfix branch, merge to the current staging branch.

    stage-up

#### Merge Release Into Your Branch

From within a bugfix branch, merge the latest released code (or, optionally,
another named branch) into your current branch.

    sync-branch
    sync-branch some-other-branch
#### Automatic Merge Conflict Resolution

Optionally you can add the line `merge_resolver: <path/to/script>` to the `.octopolo.yml` to
have Octopolo try to resolve conflicts automatically via a script upon merge failure.

#### Review Changes In Releases

Select from recent release tags and generate a link to the GitHub compare view.

    compare-releases


[build_status]: https://github.com/sportngin/octopolo/actions
[build_status_image]: https://github.com/sportngin/octopolo/actions/workflows/ruby.yml/badge.svg

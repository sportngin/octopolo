Octopolo
========

[![Build Status][build_status_image]][build_status]

A set of Github workflow scripts.


### GitHub Octopolo

#### Octopolo Installation

`$ rvm use system && brew gem uninstall sportngin-octopolo-workflow && brew gem install sportngin-octopolo-workflow
` or part of the brew gem quickstart [script](https://sportngin.atlassian.net/wiki/display/DEV/Brew+Gem)

#### GitHub Setup

Interactively set up your local machine for GitHub octopolo, including
configuring your user-level setting and setting up a GitHub API token for our
scripts to use.

    octopolo-setup


#### Create New Branch

Create a new branch from the master branch and push it out to GitHub.

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

#### Review Changes In Releases

Select from recent release tags and generate a link to the GitHub compare view.

    compare-releases


[build_status]: https://travis-ci.org/sportngin/octopolo
[build_status_image]: https://travis-ci.org/sportngin/octopolo.svg?branch=master

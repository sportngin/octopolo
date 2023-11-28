#!/usr/bin/env bash
set -e
set -o pipefail

# Gem deployment
# Depends on the following environment variables set:
#
# Common:
# GITHUB_ACTION
# GITHUB_RUN_NUMBER
# GITHUB_SHA
# GITHUB_REF
# GITHUB_HEAD_REF
# GITHUB_TOKEN from github action secrets

# Publish gem if needed
if git show -m --pretty=format:%H --name-only $GITHUB_SHA | \
        grep -q 'lib/octopolo/version.rb'; then
    rm -rf *.gem
    mkdir -p $HOME/.gem
    touch $HOME/.gem/credentials
    chmod 0600 $HOME/.gem/credentials
    printf -- "---\n:github: ${GITHUB_TOKEN}\n" > $HOME/.gem/credentials

    gem build octopolo.gemspec
    package=$(echo *.gem)

    echo "Publishing $package to github..."
    gem push --KEY github --host https://rubygems.pkg.github.com/sportngin $package
fi

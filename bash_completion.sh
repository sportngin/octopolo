_op() {
  cur="${COMP_WORDS[COMP_CWORD]}"

  # Currently the Faraday Builds warning is keeping us from doing the
  # following, so the hard coded list is required for now.
  #   local commands=`op help -c`
  local commands=" \
    accept-pull \
    compare-release \
    deployable \
    github-auth \
    help \
    new-branch \
    new-deployable \
    new-staging \
    pivotal-auth \
    pull-request \
    setup \
    signoff \
    stage-up \
    stale-branches \
    sync-branch \
    tag-release"

  COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
  return 0
}

complete -F _op op

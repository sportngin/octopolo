_op() {
  cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ -z $OCTOPOLO_0_0_1_COMMANDS ]]; then
    OCTOPOLO_0_0_1_COMMANDS=`op help -c`
  fi

  COMPREPLY=($(compgen -W "${OCTOPOLO_0_0_1_COMMANDS}" -- ${cur}))
  return 0
}

complete -F _op op
complete -F _op octopolo

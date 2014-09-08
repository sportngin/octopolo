#!/usr/bin/env zsh

if [[ ! -o interactive ]]; then
    return
fi

compctl -K _octopolo octopolo op

_octopolo() {
  local words completions
  read -cA words
  completions="$(op help -c)"
  reply=("${(ps:\n:)completions}")
}

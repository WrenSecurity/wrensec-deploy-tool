#!/usr/bin/env bash
################################################################################
# Rudimentary Bash completion support for Wren Deploy
#
# Installation Instructions:
#   1. Add the following lines to your `~/.bashrc` file:
#
#      WRENDEPLOY_HOME="/PATH/TO/wrensec-deploy-tool"
#
#      alias wren-deploy="${WRENDEPLOY_HOME}/wren-deploy.sh"
#      alias wren-preload-creds="source ${WRENDEPLOY_HOME}/wren-preload-creds.sh"
#
#   2. If your `~/.bashrc` file doesn't source `~/.bash_completion`, then add
#      this to the end of your `~/.bashrc` file
#
#      source ~/.bash_completion
#
#   3. Follow steps 1 & 2 in this answer:
#      https://serverfault.com/a/831184
#
#   4. Symlink ~/.bash_completion.d/wren-deploy to this file, as follows:
#
#      ln -snf /PATH/TO/wrensec-deploy-tool/bash_completion/wren-deploy.sh \
#        ~/.bash_completion.d/wren-deploy
#
#   5. Either log out of your session and log back in; or, run:
#
#      source ~/.bashrc
#
# @author Kortanul (kortanul@protonmail.com)
#
################################################################################
_wren_deploy_complete() {
  local cur_word prev_word type_list

  # TODO: Move this to Wren Deploy constants, and then load the constants
  #       instead of having to repeat the commands here.
  local commands_allowed=(\
    "help" \
    "version" \
    "create-sustaining-branches" \
    "tag-sustaining-branches" \
    "delete-sustaining-branches" \
    "patch-all-releases" \
    "compile-all-releases" \
    "compile-current-release" \
    "deploy-all-releases" \
    "deploy-current-release" \
    "verify-all-releases" \
    "verify-current-release" \
    "list-unapproved-artifact-sigs" \
    "capture-unapproved-artifact-sigs" \
    "deploy-consensus-verified-artifacts" \
    "sign-3p-artifacts" \
    "sign-tools-jar" \
  )

  # COMP_WORDS is an array of words in the current command line.
  # COMP_CWORD is the index of the current word (the one the cursor is
  # in).
  first_word="${COMP_WORDS[1]}"
  cur_word="${COMP_WORDS[COMP_CWORD]}"
  prev_word="${COMP_WORDS[COMP_CWORD-1]:-}"

  # COMPREPLY is the array of possible completions, generated with
  # the compgen builtin.

  COMPREPLY=()

  ## Commands ##
  if [[ ${COMP_CWORD} -eq 1 && "${cur_word}" != -* ]] ; then
    COMPREPLY=( $(compgen -W "${commands_allowed[*]}" -- "${cur_word}") )

  ## Options: deploy-consensus-verified-artifacts ##
  elif [[ "${first_word}" == 'deploy-consensus-verified-artifacts' ]]; then
    if [[ "${COMP_CWORD}" -eq 2 || "${cur_word}" == -* ]]; then
      options_allowed=( '--repo-root=' '--packaging=' )

      compopt -o nospace

      COMPREPLY=( $(compgen -W "${options_allowed[*]}" -- "${cur_word}") )

    elif [[ "${COMP_CWORD}" -gt 2 ]]; then
      # Path completion

      if [ "${cur_word}" == "=" ]; then
        cur_word="."
      fi

      _wren_complete_path
    fi

  ## Options: capture-unapproved-artifact-sigs ##
  elif [[ "${first_word}" == 'capture-unapproved-artifact-sigs' ]]; then
    if [[ "${COMP_CWORD}" -eq 2 ]]; then
      _wren_complete_path

    elif [[ "${COMP_CWORD}" -gt 2 ]]; then
      options_allowed=( '--push' '--amend' '--force' )

      COMPREPLY=( $(compgen -W "${options_allowed[*]}" -- "${cur_word}") )
    fi
  fi

  return 0
}

_wren_complete_path() {
  local IFS=$'\n'

  paths=$( \
    compgen -o plusdirs -f -- "${cur_word}" | \
      sed -e 's/ /\\ /g' | \
      sed "s#^\~#${HOME}#" \
  )

  COMPREPLY=( ${paths[*]} )

  compopt -o nospace
}

# Register `_wren_deploy_complete` to provide completion for the following commands
complete -F _wren_deploy_complete wren-deploy

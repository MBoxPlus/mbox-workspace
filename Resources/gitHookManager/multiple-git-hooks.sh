#!/bin/sh

script_dir=$(dirname $0)
hook_name=$(basename $0)

HOOKS=()

mbox_cli=mbox
# if ! [[ -z "$MBOX2_DEVELOPMENT_ROOT" ]]; then
#   source ~/.profile
#   shopt -s expand_aliases
#   mbox_cli=mdev
# fi
export PATH=$PATH:/usr/local/bin

if [[ -z "$MBOX_PLUGIN_PATHS" ]]; then
  plugin_dirs=$($mbox_cli env --only plugins --api plain --no-launcher 2>/dev/null)
  IFS=$'\n' array=($plugin_dirs)
else
  IFS=$':' array=($MBOX_PLUGIN_PATHS)
fi
for dir in "${array[@]}"
do
  hook_path="$dir/Resources/gitHooks/$hook_name"
  if [[ -f "$hook_path" ]]; then
    HOOKS+=($hook_path)
  fi
done

if [[ -z "$MBOX_ROOT" ]]; then
  export MBOX_ROOT=$($mbox_cli status --only root --api plain --no-launcher 2>/dev/null)
fi
workspace_hook="$MBOX_ROOT/.mbox/git/hooks"
hook_path="$workspace_hook/$hook_name"
if [[ -f "$hook_path" ]]; then
  HOOKS+=($hook_path)
fi

repo_hook="$PWD/gitHooks/$hook_name"
if [[ -f "$repo_hook" ]]; then
  HOOKS+=($repo_hook)
fi

repo_hook="$(git rev-parse --git-common-dir 2>/dev/null)/hooks/$hook_name"
if [[ -f "$repo_hook" ]]; then
  HOOKS+=($repo_hook)
fi

if [ -z "$HOOKS" ]; then
  exit 0
fi

stdin=$(cat /dev/stdin)

for hook in "${HOOKS[@]}"
do
  echo "Running '$hook'" >&2
  echo "$stdin" | $hook "$@"

  exit_code=$?

  if [ $exit_code != 0 ]; then
    exit $exit_code
  fi
done

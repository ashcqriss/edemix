#!/bin/sh
# shellcheck shell=sh disable=SC1090,SC2148
# Edemint shell helper — sourced by ~/.bashrc / ~/.zshrc (the branding hook
# wires the include line). Two features:
#
#  1. `?ai` (or `eai`) — explain the LAST failed command using edemint-ai.
#     The previous command's stderr/exit code are passed in as context.
#     Cloud or local backend (per edemint-ai config). Runs only when you
#     explicitly type ?ai; never on every prompt.
#
#  2. `gmr` — short alias for gamemoderun mangohud (gaming mode).

# Capture the last command + exit status by hooking the prompt.
__edemint_capture() {
    __edemint_last_cmd="$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')"
    __edemint_last_exit=$?
}
if [ -n "${BASH_VERSION:-}" ]; then
    PROMPT_COMMAND="__edemint_capture${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

# ?ai — ask edemint-ai what went wrong with the last command.
ai_explain_last() {
    cmd="${__edemint_last_cmd:-}"
    code="${__edemint_last_exit:-0}"
    if [ -z "$cmd" ]; then
        echo "No prior command captured." >&2
        return 1
    fi
    out="$(eval "$cmd" 2>&1 || true)"
    prompt="The shell command \`$cmd\` exited with status $code and produced this output:
$out

In 5 sentences or fewer, explain what went wrong and propose a fix."
    edemint-ai chat "$prompt"
}
alias '?ai'='ai_explain_last'
alias eai='ai_explain_last'

# Gaming mode launch alias.
alias gmr='gamemoderun mangohud'

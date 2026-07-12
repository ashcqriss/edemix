#!/bin/sh
# shellcheck shell=sh disable=SC1090,SC2148
# Edemint shell helper — sourced by ~/.bashrc / ~/.zshrc (the branding hook
# wires the include line). Two features:
#
#  1. `?ai` (or `eai`) — explain the LAST failed command using edemint-ai.
#     The previous command line and exit code are passed in as context. The
#     command is deliberately NOT re-executed to capture its output: re-running
#     an arbitrary failed command (a partial mv, a destructive script) is not
#     safe. Cloud or local backend (per edemint-ai config). Runs only when you
#     explicitly type ?ai; never on every prompt.
#
#  2. `gmr` — short alias for gamemoderun mangohud (gaming mode).

# Capture the last command + exit status by hooking the prompt. $? must be
# read before anything else runs in this function, or it reflects the
# capture pipeline instead of the user's command.
__edemint_capture() {
    __edemint_last_exit=$?
    __edemint_last_cmd="$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')"
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
    prompt="The shell command \`$cmd\` exited with status $code.

In 5 sentences or fewer, explain the most likely causes and propose a fix.
If the cause is ambiguous, say what output or check would disambiguate it."
    edemint-ai chat "$prompt"
}
alias '?ai'='ai_explain_last'
alias eai='ai_explain_last'

# Gaming mode launch alias.
alias gmr='gamemoderun mangohud'

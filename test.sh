#!/usr/bin/env bash
FAILURES=0

apply() {
    sudo BUNDLE_GEMFILE="$GEMFILE" FUTURE_PARSER="$FUTURE_PARSER" bundle exec \
        puppet apply --detailed-exitcodes --debug "$@" || [ $? -eq 2 ]
    FAILURES=$((FAILURES + $?))
}
check() {
    "$@"
    FAILURES=$((FAILURES + $?))
}

if [ "${CIRCLE_NODE_INDEX}" = "0" ]; then
    echo 'Apply init.pp...'
    apply tests/init.pp
    check which brew
elif [ "${CIRCLE_NODE_INDEX}" = "1" ]; then
    echo 'Test apply token.pp...'
    apply tests/token.pp
    check cat /etc/environment | grep HOMEBREW_GITHUB_API_TOKEN
else
    echo 'Apply install_options.pp...'
    apply tests/install_options.pp
    check which ack

    echo 'Apply packages.pp...'
    apply tests/packages.pp
    check stat /Applications/clementine.app/Contents/MacOS/clementine
    check which git
    check stat "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    check which bzr

    echo 'Apply tap.pp...'
    apply tests/tap.pp
    check which gc2qif

    echo 'Apply tap_priority.pp...'
    apply tests/tap_priority.pp
    check brew list ncl
fi

if [ "$FAILURES" -ne "0" ]; then
    exit 1
fi

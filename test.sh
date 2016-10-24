#!/usr/bin/env bash
FAILURES=0

apply() {
    sudo BUNDLE_GEMFILE="$GEMFILE" FUTURE_PARSER="$FUTURE_PARSER" bundle exec puppet apply --detailed-exitcodes --debug "$@" || [ $? -eq 2 ]
    FAILURES=$((FAILURES + $?))
}
check() {
    "$@"
    FAILURES=$((FAILURES + $?))
}

if [ -n "$SLOW_TESTS" ]; then
    if [ "$SLOW_TESTS" = "init.pp" ]; then
        echo 'Apply init.pp...'

        echo -en 'travis_fold:start:script.test.init\\r'
        apply tests/init.pp
        check which brew
        echo -en 'travis_fold:end:script.test.init\\r'
    fi

    if [ "$SLOW_TESTS" = "token.pp" ]; then
        echo 'Test apply token.pp...'

        echo -en 'travis_fold:start:script.test.token\\r'
        apply tests/token.pp
        check cat /etc/environment | grep HOMEBREW_GITHUB_API_TOKEN
        echo -en 'travis_fold:end:script.test.token\\r'
    fi
else
    echo 'Apply install_options.pp...'

    echo -en 'travis_fold:start:script.test.install_options\\r'
    apply tests/install_options.pp
    check which ack
    echo -en 'travis_fold:end:script.test.install_options\\r'


    echo 'Apply packages.pp...'

    echo -en 'travis_fold:start:script.test.packages\\r'
    apply tests/packages.pp
    check stat /Applications/clementine.app/Contents/MacOS/clementine
    check which git
    check stat "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    check which bzr
    echo -en 'travis_fold:end:script.test.packages\\r'


    echo 'Apply tap.pp...'

    echo -en 'travis_fold:start:script.test.tap\\r'
    apply tests/tap.pp
    check which gc2qif
    echo -en 'travis_fold:end:script.test.tap\\r'


    echo 'Apply tap_priority.pp...'

    echo -en 'travis_fold:start:script.test.tap_priority\\r'
    apply tests/tap_priority.pp
    check brew list ncl
    echo -en 'travis_fold:end:script.test.tap_priority\\r'
fi

if [ "$FAILURES" -ne "0" ]; then exit 1; fi

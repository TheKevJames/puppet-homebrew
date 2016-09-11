# == Class homebrew::params
#
# This class is meant to be called from module
# It sets variables according to platform
#
class homebrew::params {
  case $::osfamily {
    'Darwin': {
      $user                       = ''
      $group                      = 'admin'
      $command_line_tools_package = undef
      $command_line_tools_source  = undef
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }

  if $homebrew::user == 'root' {
    warning('Homebrew will be dropping support for root-owned brew by November 2016. Though this module will not prevent you from installing homebrew as root, you may run into unexpected issues. It is highly recommended you follow brew guidelines (install as a non-root user) -- this module will enforce this once homebrew has officially dropped support for root-owned installations.')
  }

}

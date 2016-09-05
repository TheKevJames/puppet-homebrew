class homebrew (
  $user,
  $command_line_tools_package = undef,
  $command_line_tools_source  = undef,
  $group = 'admin'
) {

  if $::operatingsystem != 'Darwin' {
    err('This Module works on Mac OS X only!')
    fail('Exit')
  }

  if $homebrew::user == 'root' {
    warning('Homebrew will be dropping support for root-owned brew by November 2016. Though this module will not prevent you from installing homebrew as root, you may run into unexpected issues. It is highly recommended you follow brew guidelines (install as a non-root user) -- this module will enforce this once homebrew has officially dropped support for root-owned installations.')
  }

  include homebrew::compiler
  include homebrew::install

}

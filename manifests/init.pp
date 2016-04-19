class homebrew (
  $command_line_tools_package = undef,
  $command_line_tools_source  = undef,
  $user                       = 'root'
) {
  if $::operatingsystem != 'Darwin' {
    err('This Module works on Mac OS X only!')
    fail('Exit')
  }

  include homebrew::compiler
  include homebrew::install

}

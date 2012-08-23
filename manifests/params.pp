class homebrew::params {
  if $operatingsystem != 'Darwin' {
    err('This Module works on Mac OS X only!')
    fail('Exit')
  }

  $command_line_tools_package = 'command_line_tools_for_xcode_os_x_lion_aug_2013.dmg'
  $command_line_tools_source  = 'http://puppet/command_line_tools_for_xcode_os_x_lion_aug_2013.dmg'
  $user                       = 'root'
}

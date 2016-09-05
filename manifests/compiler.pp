# == Class homebrew::compiler
# 
# Installs Command Line Tools from user provided package if OS version > 10.7
# 
class homebrew::compiler {

  if $::has_compiler == true {
  } elsif versioncmp($::macosx_productversion_major, '10.7') < 0 {
    warning('Please install the Command Line Tools bundled with XCode manually!')
  } elsif ($homebrew::command_line_tools_package and $homebrew::command_line_tools_source) {

    notice('Installing Command Line Tools.')

    package { $homebrew::command_line_tools_package:
      ensure   => present,
      provider => pkgdmg,
      source   => $homebrew::command_line_tools_source,
    }
  } else {
    warning('No Command Line Tools detected and no download source set. Please set download sources or install manually.')
  }

}

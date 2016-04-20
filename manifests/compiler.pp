class homebrew::compiler {

  if $::has_compiler == true {
  } elsif versioncmp($::macosx_productversion_major, '10.7') < 0 {
    warning('Please install the Command Line Tools bundled with XCode manually!')
  } else {

    if ($homebrew::command_line_tools_package and $homebrew::command_line_tools_source) {

      notice('Installing Command Line Tools.')

      package { $homebrew::command_line_tools_package:
        ensure   => present,
        provider => pkgdmg,
        source   => $homebrew::command_line_tools_source,
      }

    } else {
      warning('No Command Line Tools detected and no download source set. If Command Line Tools is installed, this may be a false positive. If not, please set download sources or install manually.')
    }

  }

}

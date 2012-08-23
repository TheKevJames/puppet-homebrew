class homebrew::compiler {
  if $has_compiler == 'true' {
    $package = [ ]
  }
  elsif versioncmp($macosx_productversion_major, '10.7') < 0 {
    warn('Please install the Command Line Tools bundled with XCode manually!')
    $package = [ ]
  }
  else {
    notice('Installing Command Line Tools.')
    $package = $homebrew::command_line_tools_package
    $source  = $homebrew::command_line_tools_source
  }

  package { $package:
    ensure   => present,
    provider => pkgdmg,
    source   => $source,
  }
}

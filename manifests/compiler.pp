class homebrew::compiler {

  if $facts['has_compiler'] {
    notice('Compiler already present; skipping command line tools installation.')
  } elsif $homebrew::command_line_tools_package and $homebrew::command_line_tools_source {
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

class homebrew::compiler {

  if $facts['has_compiler'] {
    notice('Compiler already present; skipping command line tools installation.')
  } elsif $homebrew::command_line_tools_package and $homebrew::command_line_tools_source {
    notice('Installing Command Line Tools from DMG.')

    package { $homebrew::command_line_tools_package:
      ensure   => present,
      provider => pkgdmg,
      source   => $homebrew::command_line_tools_source,
    }
  } else {
    notice('Installing Command Line Tools via softwareupdate.')

    $clt_placeholder = '/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress'

    exec { 'clt-placeholder':
      command => "/usr/bin/touch ${clt_placeholder}",
      creates => $clt_placeholder,
    }

    exec { 'install-clt':
      command   => '/bin/bash -c "PROD=$(/usr/sbin/softwareupdate -l | /usr/bin/grep \"\*.*Command Line\" | /usr/bin/head -n 1 | /usr/bin/awk -F\"\\*\" \x27{print $2}\x27 | /usr/bin/sed -e \x27s/^ *//\x27 | /usr/bin/sed -e \x27s/Label: //\x27 | /usr/bin/tr -d \x27\\n\x27) && /usr/sbin/softwareupdate -i \"$PROD\""', # lint:ignore:140chars
      creates   => '/Library/Developer/CommandLineTools',
      timeout   => 0,
      logoutput => on_failure,
      require   => Exec['clt-placeholder'],
    }

    exec { 'clt-placeholder-cleanup':
      command => "/bin/rm -f ${clt_placeholder}",
      onlyif  => "/bin/test -f ${clt_placeholder}",
      require => Exec['install-clt'],
    }
  }
}

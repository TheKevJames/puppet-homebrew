class homebrew::installarm {

  $homebrew_prefix = '/opt/homebrew'
  $homebrew_repository = "${homebrew_prefix}"

  $homebrew_missing_folders = [$homebrew_prefix, "${homebrew_prefix}/bin"]

  file { $homebrew_missing_folders:
    ensure => directory,
    owner  => $homebrew::user,
    group  => $homebrew::group,
  }

  $brew_sys_folders = [
    "${homebrew_prefix}/etc",
    "${homebrew_prefix}/include",
    "${homebrew_prefix}/lib",
    "${homebrew_prefix}/lib/pkgconfig",
    "${homebrew_prefix}/var",
  ]
  $brew_sys_folders.each | String $brew_sys_folder | {
    if !defined(File[$brew_sys_folder]) {
      file { $brew_sys_folder:
        ensure => directory,
        owner  => $homebrew::user,
        group  => $homebrew::group,
      }
    }
  }

  $brew_sys_chmod_folders = [
    "${homebrew_prefix}/bin",
    "${homebrew_prefix}/include",
    "${homebrew_prefix}/lib",
    "${homebrew_prefix}/etc",
    "${homebrew_prefix}/var",

  ]
  $brew_sys_chmod_folders.each | String $brew_sys_chmod_folder | {
    exec { "brew-chmod-sys-${brew_sys_chmod_folder}":
      command => "/bin/chmod -R 775 ${brew_sys_chmod_folder}",
      unless  => "/usr/bin/stat -f '%OLp' ${brew_sys_chmod_folder} | /usr/bin/grep -w '775'",
      notify  => Exec["set-${brew_sys_chmod_folder}-directory-inherit"],
    }
    exec { "set-${brew_sys_chmod_folder}-directory-inherit":
      command     => "/bin/chmod -R +a '${homebrew::group}:allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit' ${brew_sys_chmod_folder}", # lint:ignore:140chars
      refreshonly => true,
    }
  }

  $brew_folders = [
    "${homebrew_prefix}/opt",
    "${homebrew_prefix}/Caskroom",
    "${homebrew_prefix}/Cellar",
    "${homebrew_prefix}/var/homebrew",
    "${homebrew_prefix}/share",
    "${homebrew_prefix}/share/doc",
    "${homebrew_prefix}/share/info",
    "${homebrew_prefix}/share/man",
    "${homebrew_prefix}/share/man1",
    "${homebrew_prefix}/share/man2",
    "${homebrew_prefix}/share/man3",
    "${homebrew_prefix}/share/man4",
    "${homebrew_prefix}/share/man5",
    "${homebrew_prefix}/share/man6",
    "${homebrew_prefix}/share/man7",
    "${homebrew_prefix}/share/man8",
  ]

  file { $brew_folders:
    ensure => directory,
    owner  => $homebrew::user,
    group  => $homebrew::group,
  }

  if $homebrew::multiuser == true {
    $brew_folders.each | String $brew_folder | {
      exec { "chmod-${brew_folder}":
        command => "/bin/chmod -R 775 ${brew_folder}",
        unless  => "/usr/bin/stat -f '%OLp' '${brew_folder}' | /usr/bin/grep -w '775'",
        notify  => Exec["set-${brew_folder}-directory-inherit"]
      }
      exec { "chown-${brew_folder}":
        command => "/usr/sbin/chown -R :${homebrew::group} ${brew_folder}'",
        unless  => "/usr/bin/stat -f '%Sg' '${brew_folder}' | /usr/bin/grep -w '${homebrew::group}'",
      }
      exec { "set-${brew_folder}-directory-inherit":
        command     => "/bin/chmod -R +a '${homebrew::group}:allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit' ${brew_folder}",  # lint:ignore:140chars
        refreshonly => true,
      }
    }
  }

  exec { 'install-homebrew-arm':
    cwd       => $homebrew_repository,
    command   => "/usr/bin/su ${homebrew::user} -c '/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL https://github.com/homebrew/brew/tarball/master | /usr/bin/tar xz -m --strip 1\"'",
    creates   => "${homebrew_repository}/bin/brew",
    logoutput => on_failure,
    timeout   => 0,
  }
  file { '/etc/paths.d/homebrew':
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    content => '/opt/homebrew/bin:/opt/homebrew/sbin',
    require => Exec['install-homebrew-arm']
  }

}

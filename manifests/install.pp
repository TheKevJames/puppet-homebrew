class homebrew::install {

  $brew_sys_folders = [
    '/usr/local/bin',
    '/usr/local/etc',
    '/usr/local/Frameworks',
    '/usr/local/include',
    '/usr/local/lib',
    '/usr/local/lib/pkgconfig',
    '/usr/local/var',
  ]
  $brew_sys_folders.each | String $brew_sys_folder | {
    if !defined(File[$brew_sys_folder]) {
      file { $brew_sys_folder:
        ensure => directory,
        group  => $homebrew::group,
      }
    }
  }

  $brew_sys_chmod_folders = [
    '/usr/local/bin',
    '/usr/local/include',
    '/usr/local/lib',
    '/usr/local/etc',
    '/usr/local/Frameworks',
    '/usr/local/var',

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
    '/usr/local/opt',
    '/usr/local/Homebrew',
    '/usr/local/Caskroom',
    '/usr/local/Cellar',
    '/usr/local/var/homebrew',
    '/usr/local/share',
    '/usr/local/share/doc',
    '/usr/local/share/info',
    '/usr/local/share/man',
    '/usr/local/share/man1',
    '/usr/local/share/man2',
    '/usr/local/share/man3',
    '/usr/local/share/man4',
    '/usr/local/share/man5',
    '/usr/local/share/man6',
    '/usr/local/share/man7',
    '/usr/local/share/man8',
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

  exec { 'install-homebrew':
    cwd       => '/usr/local/Homebrew',
    command   => "/usr/bin/su ${homebrew::user} -c '/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL https://github.com/homebrew/brew/tarball/master | /usr/bin/tar xz -m --strip 1\"'",
    creates   => '/usr/local/Homebrew/bin/brew',
    logoutput => on_failure,
    timeout   => 0,
  }
  ~> file { '/usr/local/bin/brew':
    ensure => 'link',
    target => '/usr/local/Homebrew/bin/brew',
    owner  => $homebrew::user,
    group  => $homebrew::group,
  }

}

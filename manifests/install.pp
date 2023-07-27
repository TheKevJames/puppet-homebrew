class homebrew::install {

  $brew_prefix = $facts['brew_prefix']
  $brew_prefix_folder_if_arm = $brew_prefix ? {
      '/opt/homebrew' => ['/opt/homebrew'],
      default => [],
  }
  $brew_allow_attributes = [
    'list,add_file,search,add_subdirectory,delete_child',
    'readattr,writeattr,readextattr,writeextattr,readsecurity',
    'file_inherit,directory_inherit'
  ].join(',')

  $brew_sys_folders = $brew_prefix_folder_if_arm + [
    "${brew_prefix}/bin",
    "${brew_prefix}/etc",
    "${brew_prefix}/Frameworks",
    "${brew_prefix}/include",
    "${brew_prefix}/lib",
    "${brew_prefix}/lib/pkgconfig",
    "${brew_prefix}/var",
    "/Users/${homebrew::user}/Library/Caches/Homebrew",
  ]
  $brew_sys_folders.each | String $brew_sys_folder | {
    if !defined(File[$brew_sys_folder]) {
      file { $brew_sys_folder:
        ensure => directory,
        group  => $homebrew::group,
        owner  => $homebrew::user,
      }
    }
  }

  $brew_sys_chmod_folders = $brew_prefix_folder_if_arm + [
    "${brew_prefix}/bin",
    "${brew_prefix}/include",
    "${brew_prefix}/lib",
    "${brew_prefix}/etc",
    "${brew_prefix}/Frameworks",
    "${brew_prefix}/var",
  ]
  $brew_sys_chmod_folders.each | String $brew_sys_chmod_folder | {
    exec { "brew-chmod-sys-${brew_sys_chmod_folder}":
      command => "/bin/chmod -R 775 ${brew_sys_chmod_folder}",
      unless  => "/usr/bin/stat -f '%OLp' ${brew_sys_chmod_folder} | /usr/bin/grep -w '775'",
      notify  => Exec["set-${brew_sys_chmod_folder}-directory-inherit"],
    }
    exec { "set-${brew_sys_chmod_folder}-directory-inherit":
      command     => "/bin/chmod -R +a 'group:${homebrew::group}:allow ${brew_allow_attributes}' ${brew_sys_chmod_folder}",
      refreshonly => true,
    }
  }

  $brew_folders = [
    "${brew_prefix}/opt",
    "${brew_prefix}/Homebrew",
    "${brew_prefix}/Caskroom",
    "${brew_prefix}/Cellar",
    "${brew_prefix}/var/homebrew",
    "${brew_prefix}/var/homebrew/linked",
    "${brew_prefix}/share",
    "${brew_prefix}/share/doc",
    "${brew_prefix}/share/info",
    "${brew_prefix}/share/man",
    "${brew_prefix}/share/man1",
    "${brew_prefix}/share/man2",
    "${brew_prefix}/share/man3",
    "${brew_prefix}/share/man4",
    "${brew_prefix}/share/man5",
    "${brew_prefix}/share/man6",
    "${brew_prefix}/share/man7",
    "${brew_prefix}/share/man8",
    "${brew_prefix}/share/zsh",
    "${brew_prefix}/share/zsh/site-functions",
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
        command     => "/bin/chmod -R +a 'group:${homebrew::group}:allow ${brew_allow_attributes}' ${brew_folder}",
        refreshonly => true,
      }
    }
  }

  exec { 'install-homebrew':
    cwd         => $brew_prefix,
    command     => "/bin/bash -o pipefail -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
    creates     => "${brew_prefix}/bin/brew",
    environment => ['NONINTERACTIVE=1', "HOME=/Users/${homebrew::user}"],
    logoutput   => on_failure,
    user        => $homebrew::user,
    timeout     => 0,
  }
  if $facts['os']['architecture'] != 'arm64' {
    file { "${brew_prefix}/bin/brew":
      ensure    => 'link',
      target    => "${brew_prefix}/Homebrew/bin/brew",
      owner     => $homebrew::user,
      group     => $homebrew::group,
      subscribe => Exec['install-homebrew'],
    }
  }
}

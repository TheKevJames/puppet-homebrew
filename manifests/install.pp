class homebrew::install {

  # Homebrew install target depends on architecture.
  if $facts['is_arm64'] {
    $brew_root          = '/opt/homebrew'
    $inst_dir           = $brew_root
    $link_bin           = false
    $brew_folders_extra = []
  } else {
    $brew_root          = '/usr/local'
    $inst_dir           = "${brew_root}/Homebrew"
    $link_bin           = true
    $brew_folders_extra = ["${brew_root}/Homebrew"]
  }

  $brew_sys_folders = [
    "${brew_root}/bin",
    "${brew_root}/etc",
    "${brew_root}/Frameworks",
    "${brew_root}/include",
    "${brew_root}/lib",
    "${brew_root}/lib/pkgconfig",
    "${brew_root}/var",
  ]

  $brew_sys_folders.each |String $brew_sys_folder| {
    unless defined(File[$brew_sys_folder]) {
      file { $brew_sys_folder:
        ensure => directory,
        owner  => $homebrew::user,
        group  => $homebrew::group,
      }
    }
  }

  $brew_sys_chmod_folders = [
    "${brew_root}/bin",
    "${brew_root}/include",
    "${brew_root}/lib",
    "${brew_root}/etc",
    "${brew_root}/Frameworks",
    "${brew_root}/var",
  ]

  $brew_sys_chmod_folders.each |String $brew_sys_chmod_folder| {
    exec { "brew-chmod-sys-${brew_sys_chmod_folder}":
      command => "/bin/chmod -R 775 ${brew_sys_chmod_folder}",
      unless  => "/usr/bin/stat -f '%OLp' ${brew_sys_chmod_folder} | /usr/bin/grep -w '775'",
      notify  => Exec["set-${brew_sys_chmod_folder}-directory-inherit"],
    }

    exec { "set-${brew_sys_chmod_folder}-directory-inherit":
      command     => "/bin/chmod -R +a 'group:${homebrew::group}:allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit' ${brew_sys_chmod_folder}", # lint:ignore:140chars
      refreshonly => true,
    }
  }

  $brew_folders = flatten(
    $brew_folders_extra,
    [
      "${brew_root}/opt",
      "${brew_root}/Caskroom",
      "${brew_root}/Cellar",
      "${brew_root}/var/homebrew",
      "${brew_root}/share",
      "${brew_root}/share/doc",
      "${brew_root}/share/info",
      "${brew_root}/share/man",
    ],
  )

  file { $brew_folders:
    ensure => directory,
    owner  => $homebrew::user,
    group  => $homebrew::group,
  }

  if $homebrew::multiuser {
    $brew_folders.each |String $brew_folder| {
      exec { "chmod-${brew_folder}":
        command => "/bin/chmod -R 775 ${brew_folder}",
        unless  => "/usr/bin/stat -f '%OLp' '${brew_folder}' | /usr/bin/grep -w '775'",
        notify  => Exec["set-${brew_folder}-directory-inherit"],
      }

      exec { "chown-${brew_folder}":
        command => "/usr/sbin/chown -R :${homebrew::group} ${brew_folder}",
        unless  => "/usr/bin/stat -f '%Sg' '${brew_folder}' | /usr/bin/grep -w '${homebrew::group}'",
      }

      exec { "set-${brew_folder}-directory-inherit":
        command     => "/bin/chmod -R +a 'group:${homebrew::group}:allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit' ${brew_folder}", # lint:ignore:140chars
        refreshonly => true,
      }
    }
  }

  $homebrew_install_script = '/tmp/homebrew-install.sh'
  $homebrew_install_url = 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'
  $homebrew_install_cmd = join([
    '/usr/bin/curl -fsSL -o',
    $homebrew_install_script,
    $homebrew_install_url,
    '&&',
    '/usr/bin/env NONINTERACTIVE=1 /bin/bash',
    $homebrew_install_script,
  ], ' ')

  exec { 'install-homebrew':
    cwd       => '/tmp',
    command   => "/usr/bin/su ${homebrew::user} -c '${homebrew_install_cmd}'",
    creates   => "${brew_root}/bin/brew",
    logoutput => on_failure,
    timeout   => 0,
  }

  if $link_bin {
    file { "${brew_root}/bin/brew":
      ensure => link,
      target => "${inst_dir}/bin/brew",
      owner  => $homebrew::user,
      group  => $homebrew::group,
    }
  }
}

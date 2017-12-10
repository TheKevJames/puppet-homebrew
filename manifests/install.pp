class homebrew::install {

  $brew_root = '/usr/local'
  $brew_subfolders = [
                    '/usr/local/bin',
                    '/usr/local/Cellar',
                    '/usr/local/etc',
                    '/usr/local/Frameworks',
                    '/usr/local/include',
                    '/usr/local/lib',
                    '/usr/local/lib/pkgconfig',
                    '/usr/local/opt',
                    '/usr/local/share',
                    '/usr/local/share/doc',
                    '/usr/local/share/man',
                    '/usr/local/var',
                  ]

  # High Sierra no longer allows us to set perms on /usr/local
  if $facts['os']['macosx']['version']['major'] == '10.13' {
    $brew_folders = $brew_subfolders
  } else {
    $brew_folders = concat([$brew_root], $brew_subfolders)
  }

  file { $brew_folders:
    ensure => directory,
    group  => $homebrew::group,
    mode   => '0775',
  } ->
  file { '/usr/local/Homebrew':
    ensure => directory,
    owner  => $homebrew::user,
    group  => $homebrew::group,
    mode   => '0775',
  } ->
  exec { 'install-homebrew':
    cwd       => '/usr/local/Homebrew',
    command   => "/usr/bin/su ${homebrew::user} -c '/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL https://github.com/homebrew/brew/tarball/master | /usr/bin/tar xz -m --strip 1\"'",
    creates   => '/usr/local/Homebrew/bin/brew',
    logoutput => on_failure,
    timeout   => 0,
  } ~>
  file { '/usr/local/bin/brew':
    ensure => 'link',
    target => '/usr/local/Homebrew/bin/brew',
    owner  => $homebrew::user,
    group  => $homebrew::group,
    mode   => '0775',
  }

}

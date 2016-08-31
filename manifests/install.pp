class homebrew::install {

  file { ['/usr/local', '/Library/Caches/Homebrew']:
    ensure  => directory,
    owner   => $homebrew::user,
    group   => $homebrew::group,
    mode    => '0644',
    recurse => true,
  } ->
  file { '/usr/local/Library': ensure => directory } ->
  file { '/usr/local/Library/Homebrew': ensure => directory } ->
  file { '/usr/local/Library/Homebrew/cask': ensure => directory }
  file { '/usr/local/Library/Homebrew/shims':
    ensure  => directory,
    require => File['/usr/local/Library/Homebrew'],
  }

  file { ['/usr/local/Library/Homebrew/cask/cmd',
          '/usr/local/Library/Homebrew/shims/scm',
          '/usr/local/Library/Homebrew/shims/super',
          '/usr/local/bin',
          '/usr/local/Cellar']:
    ensure  => directory,
    mode    => '0755',
    recurse => true,
    require => [File['/usr/local/Library/Homebrew/cask'],
                File['/usr/local/Library/Homebrew/shims']],
  }

  exec { 'install-homebrew':
    cwd       => '/usr/local',
    command   => "/usr/bin/su ${homebrew::user} -c '/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL https://github.com/homebrew/brew/tarball/master | /usr/bin/tar xz -m --strip 1\"'",
    creates   => '/usr/local/bin/brew',
    logoutput => on_failure,
    timeout   => 0,
    require   => File['/usr/local'],
  } ~>
  file { '/usr/local/bin/brew':
    owner => $homebrew::user,
    group => $homebrew::group,
    mode  => '0775',
  }

}

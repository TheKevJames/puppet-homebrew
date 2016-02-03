include homebrew

package { 'git':
  ensure   => present,
  provider => brew,
  require  => Class['homebrew']
}

package { 'tmux':
  ensure   => present,
  provider => homebrew,
  require  => Class['homebrew']
}

package { 'google-chome':
  ensure   => present,
  provider => brewcask,
  require  => Class['homebrew']
}

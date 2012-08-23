class { 'homebrew': }

package { 'git':
  ensure   => present,
  provider => brew,
  require  => Class['homebrew']
}

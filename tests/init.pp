class { 'homebrew': }

package { 'git':
  ensure   => present,
  provider => brew,
}

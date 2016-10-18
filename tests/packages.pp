package { 'git':  # in brew
  ensure   => present,
  provider => brew,
}

package { 'bazaar':  # in brew
  ensure   => present,
  provider => homebrew,
}

package { 'clementine':  # in brewcask
  ensure   => present,
  provider => homebrew,
}

package { 'google-chrome':  # in brewcask
  ensure   => present,
  provider => brewcask,
}

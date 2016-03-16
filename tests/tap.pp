package { 'neovim/neovim':
  ensure   => present,
  provider => tap,
} ->
package { 'neovim':
  ensure   => present,
  provider => homebrew,
}

package { 'homebrew/versions':
  ensure   => absent,
  provider => tap,
}

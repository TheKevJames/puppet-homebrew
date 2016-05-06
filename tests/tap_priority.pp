Package <| provider == tap |> -> Package <| provider == homebrew |>

package { 'neovim/neovim':
  ensure   => present,
  provider => tap,
}

package { 'neovim':
  ensure   => present,
  provider => homebrew,
}

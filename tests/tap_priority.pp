Package <| provider == tap |> -> Package <| provider == homebrew |>

package { 'homebrew/science':
  ensure   => present,
  provider => tap,
}

package { 'ncl':
  ensure   => present,
  provider => homebrew,
}

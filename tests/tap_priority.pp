Package <| provider == tap |> -> Package <| provider == homebrew |>

package { 'homebrew/science':
  ensure   => present,
  provider => tap,
}

package { 'bact':
  ensure   => present,
  provider => homebrew,
}

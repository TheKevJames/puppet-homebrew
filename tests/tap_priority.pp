Package <| provider == tap |> -> Package <| provider == homebrew |>

package { 'simeji/jid':
  ensure   => present,
  provider => tap,
}

package { 'jid':
  ensure   => present,
  provider => homebrew,
}

# Package <| provider == tap |> -> Package <| provider == homebrew |>

package { 'meanbee/tap':
  ensure   => present,
  provider => tap,
} ->

package { 'gc2qif':
  ensure   => present,
  provider => homebrew,
}


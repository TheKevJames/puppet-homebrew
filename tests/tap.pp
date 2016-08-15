package { 'meanbee/tap':
  ensure   => present,
  provider => tap,
} ->
package { 'gc2qif':
  ensure   => present,
  provider => homebrew,
}

package { 'homebrew/versions':
  ensure   => absent,
  provider => tap,
}

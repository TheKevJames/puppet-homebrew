package { 'ack':
  ensure          => latest,
  provider        => homebrew,
  install_options => [
    '--with-default-names',
  ],
}

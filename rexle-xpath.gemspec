Gem::Specification.new do |s|
  s.name = 'rexle-xpath'
  s.version = '0.2.15'
  s.summary = 'Under development, and is not currently used by the Rexle gem.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rexle-xpath.rb']
  s.add_runtime_dependency('rexle-xpath-parser', '~> 0.1', '>=0.1.13')
  s.signing_key = '../privatekeys/rexle-xpath.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/rexle-xpath'
end

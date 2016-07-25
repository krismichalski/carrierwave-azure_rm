lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'carrierwave/azure_rm/version'

Gem::Specification.new do |gem|
  gem.name          = 'carrierwave-azure_rm'
  gem.version       = Carrierwave::AzureRM::VERSION
  gem.authors       = ['nooulaif']
  gem.email         = ['contact@nooulaif.com']
  gem.summary       = %q{Microsoft Azure Storage blob support for CarrierWave}
  gem.description   = %q{Allows file upload to Azure with the new official sdk}
  gem.homepage      = 'https://github.com/nooulaif/carrierwave-azure_rm'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^spec})
  gem.require_paths = ['lib']

  gem.add_dependency 'carrierwave'
  gem.add_dependency 'azure-storage', '~> 0.10.2.preview'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3'
end

require 'carrierwave'
require 'carrierwave/azure_rm/version'
require 'carrierwave/storage/azure_rm'

class CarrierWave::Uploader::Base
  add_config :azure_storage_account_name
  add_config :azure_storage_access_key
  add_config :azure_storage_blob_host
  add_config :azure_container
  add_config :public_access_level

  configure do |config|
    config.public_access_level = 'blob'
    config.storage_engines[:azure_rm] = 'CarrierWave::Storage::AzureRM'
  end
end

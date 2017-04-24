# Carrierwave::AzureRM

Microsoft Azure Storage blob support for [CarrierWave](https://github.com/carrierwaveuploader/carrierwave).

Heavily inspired by @unosk [carrierwave-azure](https://github.com/unosk/carrierwave-azure) gem, which seems to be no longer maintained.

Uses new [azure-storage](https://github.com/Azure/azure-storage-ruby) sdk to support [ARM](https://azure.microsoft.com/en-us/documentation/articles/resource-group-overview/).

## Installation

Add this line to your application's Gemfile:

    gem 'carrierwave-azure_rm'

And then execute:

    $ bundle

## Usage

First configure CarrierWave with your Azure storage credentials

see [Azure/azure-storage-ruby](https://github.com/Azure/azure-storage-ruby#via-code)

```ruby
CarrierWave.configure do |config|
  config.azure_storage_account_name = 'YOUR STORAGE ACCOUNT NAME'
  config.azure_storage_access_key = 'YOUR STORAGE ACCESS KEY'
  config.azure_storage_blob_host = 'YOUR STORAGE BLOB HOST' # optional
  config.azure_container = 'YOUR CONTAINER NAME'
  config.asset_host = 'YOUR CDN HOST' # optional
end
```

And then in your uploader, set the storage to `:azure_rm`

```ruby
class ExampleUploader < CarrierWave::Uploader::Base
  storage :azure_rm
end
```

## Private blobs
If your container access policy is set to private, carrierwave-azure_rm can automatically
return signed urls on the files. Enable auto_sign in the configuration:

```ruby
config.auto_sign_urls = true
```

If you wish a newly created container to be initialized with a specific access_level you can set the following in
your config:

```ruby
config.public_access_level = 'private' # optional - possible values are blob, private, container
```

This config is only required if your container does not exist and you want it to be configured automatically.

[Manage access to blobs](https://docs.microsoft.com/en-us/azure/storage/storage-manage-access-to-resources) 

## Issues
If you have any problems with or questions about this image, please contact me through a [GitHub issue](https://github.com/nooulaif/carrierwave-azure_rm/issues).

## Contributing
You are invited to contribute new features, fixes, or updates, large or small.

I'm always thrilled to receive pull requests, and do my best to process them as fast as I can.

In order to run the integration specs you will need to configure some environment variables.
A sample file is provided as `spec/environment.rb.sample`.
Copy it over and plug in the appropriate values.

```bash
cp spec/environment.rb.sample spec/environment.rb
```

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
Released under the MIT License. See [LICENSE](https://github.com/nooulaif/carrierwave-azure_rm/blob/master/LICENSE) file for details.

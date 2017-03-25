require 'spec_helper'

describe CarrierWave::Uploader::Base do
  it 'should define azure as a storage engine' do
    expect(described_class.storage_engines[:azure_rm]).to eq 'CarrierWave::Storage::AzureRM'
  end

  it 'should define azure options' do
    is_expected.to respond_to(:azure_storage_account_name)
    is_expected.to respond_to(:azure_storage_access_key)
    is_expected.to respond_to(:azure_storage_blob_host)
    is_expected.to respond_to(:azure_container)
    is_expected.to respond_to(:auto_sign_urls)
  end

  it 'should have public_access_level blob by default' do
    expect(described_class.public_access_level).to eq 'blob'
  end
end

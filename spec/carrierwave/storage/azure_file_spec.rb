require 'spec_helper'

describe CarrierWave::Storage::AzureRM::File do
  class TestUploader < CarrierWave::Uploader::Base
    storage :azure_rm
  end

  let(:uploader) { TestUploader.new }
  let(:storage)  { CarrierWave::Storage::AzureRM.new uploader }

  describe '#url' do
    before do
      allow(uploader).to receive(:azure_container).and_return('test')
    end

    subject { CarrierWave::Storage::AzureRM::File.new(uploader, storage.connection, 'dummy.txt', storage.signer).url }

    context 'with storage_blob_host' do
      before do
        # This must be first!
        allow(uploader).to receive(:azure_storage_blob_host).and_return('http://example.com')

        # automatic resolving won't work for non existent url
        struct = Struct.new('Container', :public_access_level).new
        struct.public_access_level = 'blob'
        allow(storage.connection).to receive(:get_container_acl).and_return(struct)
      end

      it 'should return on asset_host' do
        expect(subject).to eq 'http://example.com/test/dummy.txt'
      end
    end

    context 'with asset_host' do
      before do
        allow(uploader).to receive(:asset_host).and_return('http://example.com')
      end

      it 'should return on asset_host' do
        expect(subject).to eq 'http://example.com/test/dummy.txt'
      end
    end
  end

  describe '#exists?' do
    before do
      allow(storage.connection).to receive(:get_blob).and_return(nil)
    end

    subject { CarrierWave::Storage::AzureRM::File.new(uploader, storage.connection, 'dummy.txt', storage.signer).exists? }

    context 'when blob file does not exist' do
      it 'should return false' do
        expect(subject).to eql false
      end
    end
  end
end

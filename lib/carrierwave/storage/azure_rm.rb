require 'azure/storage'

module CarrierWave
  module Storage
    class AzureRM < Abstract
      def store!(file)
        azure_file = CarrierWave::Storage::AzureRM::File.new(uploader, connection, uploader.store_path)
        azure_file.store!(file)
        azure_file
      end

      def retrieve!(identifer)
        CarrierWave::Storage::AzureRM::File.new(uploader, connection, uploader.store_path(identifer))
      end

      def connection
        @connection ||= begin
          %i(storage_account_name storage_access_key storage_blob_host).each do |key|
            ::Azure::Storage.send("#{key}=", uploader.send("azure_#{key}"))
          end
          Azure::Storage::Blob::BlobService.new
        end
      end

      class File
        attr_reader :path

        def initialize(uploader, connection, path)
          @uploader = uploader
          @connection = connection
          @path = path
        end

        def ensure_container_exists(name)
          unless @connection.list_containers.any? { |c| c.name == name }
            @connection.create_container(name, public_access_level: 'blob')
          end
        end

        def store!(file)
          ensure_container_exists(@uploader.send("azure_container"))
          @content_type = file.content_type
          file_to_send  = ::File.open(file.file, 'rb')
          blocks        = []

          until file_to_send.eof?
            block_id = Base64.urlsafe_encode64(SecureRandom.uuid)

            @content = file_to_send.read 4194304 # Send 4MB chunk
            @connection.put_blob_block @uploader.azure_container, @path, block_id, @content
            blocks << [block_id]
          end

          # Commit block blobs
          @connection.commit_blob_blocks @uploader.azure_container, @path, blocks, content_type: @content_type

          true
        end

        def url(options = {})
          path = ::File.join @uploader.azure_container, @path
          if @uploader.asset_host
            "#{@uploader.asset_host}/#{path}"
          else
            @connection.generate_uri(path).to_s
          end
        end

        def read
          content
        end

        def content_type
          @content_type = blob.properties[:content_type] if @content_type.nil? && !blob.nil?
          @content_type
        end

        def content_type=(new_content_type)
          @content_type = new_content_type
        end

        def exists?
          blob.nil?
        end

        def size
          blob.properties[:content_length] unless blob.nil?
        end

        def filename
          URI.decode(url).gsub(/.*\/(.*?$)/, '\1')
        end

        def extension
          @path.split('.').last
        end

        def delete
          begin
            @connection.delete_blob @uploader.azure_container, @path
            true
          rescue ::Azure::Core::Http::HTTPError
            false
          end
        end

        private

        def blob
          load_content if @blob.nil?
          @blob
        end

        def content
          load_content if @content.nil?
          @content
        end

        def load_content
          @blob, @content = begin
            @connection.get_blob @uploader.azure_container, @path
          rescue ::Azure::Core::Http::HTTPError
          end
        end
      end
    end
  end
end

require 'azure/storage'

module CarrierWave
  module Storage
    class AzureRM < Abstract
      def store!(file)
        azure_file = CarrierWave::Storage::AzureRM::File.new(uploader, connection, uploader.store_path, signer)
        azure_file.store!(file)
        azure_file
      end

      def retrieve!(identifer)
        CarrierWave::Storage::AzureRM::File.new(uploader, connection, uploader.store_path(identifer), signer)
      end

      def connection
        @connection ||= begin
          %i(storage_account_name storage_access_key storage_blob_host).each do |key|
            ::Azure::Storage.send("#{key}=", uploader.send("azure_#{key}"))
          end
          ::Azure::Storage::Blob::BlobService.new
        end
      end

      def signer
        @signer ||= begin
          ::Azure::Storage::Core::Auth::SharedAccessSignature.new
        end
      end

      class File
        attr_reader :path

        def initialize(uploader, connection, path, signer = nil)
          @uploader = uploader
          @connection = connection
          @signer = signer
          @path = path
        end

        def ensure_container_exists(name)
          unless @connection.list_containers.any? { |c| c.name == name }
            @connection.create_container(name, access_level_option)
          end
        end

        def access_level
          unless @public_access_level
            container, signed_identifiers = @connection.get_container_acl(@uploader.send("azure_container"))
            @public_access_level = container.public_access_level || 'private' # when container access level is private, it returns nil
          end
          @public_access_level
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
            uri = @connection.generate_uri(URI.encode(path))
            if sign_url?(options)
              @signer.signed_uri(uri, false, { permissions: 'r',
                                               resource: 'b',
                                               start: 1.minute.ago.utc.iso8601,
                                               expiry: expires_at}).to_s
            else
              uri.to_s
            end
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
          !blob.nil?
        end

        def size
          blob.properties[:content_length] unless blob.nil?
        end

        def filename
          URI.decode(url(skip_signing: true)).gsub(/.*\/(.*?$)/, '\1')
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

        def access_level_option
          lvl = @uploader.public_access_level
          raise "Invalid Access level #{lvl}." unless %w(private blob container).include? lvl
          lvl == 'private' ? {} : { :public_access_level => lvl }
        end

        def expires_at
          expiry = Time.now + @uploader.token_expire_after
          expiry.utc.iso8601
        end

        def sign_url?(options)
          @uploader.auto_sign_urls && !options[:skip_signing] && access_level == 'private'
        end

        def blob
          load_blob if @blob.nil?
          @blob
        end

        def content
          load_content if @content.nil?
          @content
        end

        def load_blob
          @blob = begin
            @connection.get_blob_properties @uploader.azure_container, @path
          rescue ::Azure::Core::Http::HTTPError
          end
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

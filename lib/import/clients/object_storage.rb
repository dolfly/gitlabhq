# frozen_string_literal: true

module Import
  module Clients
    class ObjectStorage
      include Gitlab::Utils::StrongMemoize

      DownloadError = Class.new(StandardError)
      UploadError = Class.new(StandardError)
      ConnectionError = Class.new(StandardError)

      MULTIPART_THRESHOLD = 100.megabytes
      PREFIX_SEPARATOR = '/'

      FOG_PROVIDER_MAP = {
        aws: 'AWS',
        s3_compatible: 'AWS'
      }.with_indifferent_access.freeze

      FOG_ERRORS = [Fog::Errors::Error, Excon::Error].freeze

      def initialize(provider:, bucket:, credentials:)
        @provider = provider
        @bucket = bucket
        @credentials = credentials
      end

      def request_url(object_key)
        storage.request_url(bucket_name: bucket, object_name: object_key)
      end

      def test_connection!
        wrapped_object_storage_errors(ConnectionError, s_('OfflineTransfer|Unable to access object storage bucket.')) do
          storage.head_bucket(bucket).status == 200
        end
      end

      def store_file(object_key, local_path)
        check_for_path_traversal!(local_path)
        validate_file_exists!(local_path)

        wrapped_object_storage_errors(UploadError, 'Object storage upload failed',
          extra_log_context: { object_key: object_key, local_path: local_path }) do
          directory = storage.directories.new(key: bucket)
          File.open(local_path, 'rb') do |file|
            directory.files.create(
              key: object_key,
              body: file,
              multipart_chunk_size: MULTIPART_THRESHOLD
            )
          end
          true
        end
      end

      def stream(object_key, &block)
        wrapped_object_storage_errors(DownloadError, 'Object storage download failed',
          extra_log_context: { object_key: object_key }) do
          directory = storage.directories.new(key: bucket)
          file = directory.files.get(object_key, &block)

          raise DownloadError, "Object not found" unless file

          true
        end
      end

      private

      attr_reader :provider, :credentials, :bucket

      def validate_file_exists!(local_path)
        return if File.exist?(local_path)

        raise UploadError, "File not found: #{local_path}"
      end

      def storage
        ::Fog::Storage.new(
          provider: FOG_PROVIDER_MAP[provider],
          **credentials
        )
      end
      strong_memoize_attr :storage

      def check_for_path_traversal!(local_path)
        Gitlab::PathTraversal.check_path_traversal!(local_path)
      end

      def base_log_context
        { provider: provider, bucket: bucket }
      end

      def wrapped_object_storage_errors(error_class, message, extra_log_context: {})
        result = yield
        raise error_class, message unless result

        result
      rescue *FOG_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, **base_log_context, **extra_log_context)
        raise error_class, message
      rescue NoMethodError => e
        # Fog currently mishandles redirects, resulting in a NoMethodError when
        # parsing the response body from AWS. If the cause here is an ExconError,
        # we treat it as a failed connection.
        if e.cause.is_a?(Excon::Error)
          Gitlab::ErrorTracking.track_exception(e, **base_log_context, **extra_log_context)
          raise error_class, s_('OfflineTransfer|Unable to access object storage bucket.')
        end

        raise e
      end
    end
  end
end

# frozen_string_literal: true

module SlackRubyBotServer
  module Events
    module Config
      extend self

      ATTRIBUTES = %i[
        signing_secret
        signature_expires_in
        callbacks
      ].freeze

      attr_accessor(*Config::ATTRIBUTES)

      def reset!
        self.callbacks = Hash.new { |h, k| h[k] = [] }
        self.signing_secret = ENV.fetch('SLACK_SIGNING_SECRET', nil)
        self.signature_expires_in = 5 * 60

        on :event, 'url_verification' do |event|
          { challenge: event[:challenge] }
        end
      end

      def on(type, *values, &block)
        value_key = values.compact.join('/') if values.any?
        key = [type.to_s, value_key].compact.join('/')
        callbacks[key] << block
      end

      def run_callbacks(type, value, args)
        callbacks = []

        keys = ([type.to_s] + Array(value)).compact

        # more specific callbacks first
        while keys.any?
          key = keys.join('/')
          callbacks += self.callbacks[key].map { |c| [key, c] }
          keys.pop
        end

        callbacks.each do |key, c|
          rc = run_callback(key, c, args || value)
          return rc if rc
        end

        nil
      end

      private

      def run_callback(key, callback, args)
        callback.call(args)
      rescue StandardError => e
        location = callback.source_location&.first(2)&.join(':')
        SlackRubyBotServer::Api::Middleware.logger.error(
          "#{e.class.name} in #{key} callback defined at #{location || 'an unknown location'}: #{e.message}"
        )
        raise
      end
    end

    class << self
      def configure
        block_given? ? yield(Config) : Config
      end

      def config
        Config
      end
    end
  end
end

SlackRubyBotServer::Events::Config.reset!

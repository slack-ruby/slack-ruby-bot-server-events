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

      # Register a callback for a type and an optional path of values, e.g. on(:event, 'event_callback', 'team_join').
      # The path may also be given as a single array. An array within the path lists alternatives, and the callback
      # is registered for each combination, e.g. on(:event, 'event_callback', %w[pin_added pin_removed]).
      def on(type, *values, &block)
        values = values.first if values.size == 1 && values.first.is_a?(Array)
        alternatives = values.compact.map { |value| Array(value).map(&:to_s) }
        paths = alternatives.empty? ? [[]] : alternatives.first.product(*alternatives.drop(1))
        paths.each do |path|
          callbacks[[type.to_s, *path].join('/')] << block
        end
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

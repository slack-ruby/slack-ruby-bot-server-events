# frozen_string_literal: true

module SlackRubyBotServer
  module Slack
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
        self.signing_secret = ENV['SLACK_SIGNING_SECRET']
        self.signature_expires_in = 5 * 60

        on :event, 'url_verification' do |event|
          { challenge: event[:challenge] }
        end
      end

      def on(types, value = nil, &block)
        Array(types).each do |type|
          value_key = Array(value).compact.join('/') if value
          key = [type.to_s, value_key].compact.join('/')
          callbacks[key] << block
        end
      end

      def run_callbacks(type, value, args)
        callbacks = []

        keys = ([type.to_s] + Array(value)).compact

        # more specific callbacks first
        while keys.any?
          callbacks += self.callbacks[keys.join('/')]
          keys.pop
        end

        return nil unless callbacks&.any?

        callbacks.each do |c|
          rc = c.call(args || value)
          return rc if rc
        end

        nil
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

SlackRubyBotServer::Slack::Config.reset!

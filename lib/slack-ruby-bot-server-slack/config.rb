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

        on :event do |event|
          case event[:type]
          when 'url_verification'
            { challenge: event[:challenge] }
          end
        end
      end

      def on(*types, &block)
        Array(types).each do |type|
          callbacks[type.to_s] << block
        end
      end

      def run_callbacks(type, args)
        callbacks = self.callbacks[type.to_s]
        return nil unless callbacks&.any?

        callbacks.each do |c|
          rc = c.call(args)
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

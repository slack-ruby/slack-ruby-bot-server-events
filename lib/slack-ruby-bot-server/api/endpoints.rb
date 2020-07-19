# frozen_string_literal: true

module SlackRubyBotServer
  module Api
    module Endpoints
      class RootEndpoint
        namespace :slack do
          format :json

          before do
            begin
              ::Slack::Events::Request.new(
                request,
                signing_secret: SlackRubyBotServer::Events.config.signing_secret,
                signature_expires_in: SlackRubyBotServer::Events.config.signature_expires_in
              ).verify!
            rescue ::Slack::Events::Request::TimestampExpired
              error!('Invalid Signature', 403)
            end
          end

          mount SlackRubyBotServer::Events::Api::Endpoints::Slack::CommandsEndpoint
          mount SlackRubyBotServer::Events::Api::Endpoints::Slack::ActionsEndpoint
          mount SlackRubyBotServer::Events::Api::Endpoints::Slack::EventsEndpoint
        end
      end
    end
  end
end

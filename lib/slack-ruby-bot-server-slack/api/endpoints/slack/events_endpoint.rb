# frozen_string_literal: true

module SlackRubyBotServer
  module Slack
    module Api
      module Endpoints
        module Slack
          class EventsEndpoint < Grape::API
            desc 'Handle Slack events.'
            params do
              requires :token, type: String
              requires :type, type: String
              optional :challenge, type: String
            end
            post '/event' do
              event = SlackRubyBotServer::Slack::Requests::Event.new(params, request)
              SlackRubyBotServer::Slack.config.run_callbacks(:event, event) || body(false)
            end
          end
        end
      end
    end
  end
end

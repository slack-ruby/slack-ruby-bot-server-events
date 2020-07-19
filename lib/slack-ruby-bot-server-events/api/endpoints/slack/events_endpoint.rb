# frozen_string_literal: true

module SlackRubyBotServer
  module Events
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
              event = SlackRubyBotServer::Events::Requests::Event.new(params, request)
              type = event[:type]
              event_type = event[:event][:type] if event.key?(:event)
              key = [type, event_type].compact
              SlackRubyBotServer::Events.config.run_callbacks(:event, key, event) || body(false)
            end
          end
        end
      end
    end
  end
end

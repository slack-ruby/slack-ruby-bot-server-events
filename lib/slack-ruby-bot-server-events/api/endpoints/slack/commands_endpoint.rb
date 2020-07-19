# frozen_string_literal: true

module SlackRubyBotServer
  module Events
    module Api
      module Endpoints
        module Slack
          class CommandsEndpoint < Grape::API
            desc 'Respond to slash commands.'
            params do
              requires :command, type: String
              requires :text, type: String
              requires :token, type: String
              requires :user_id, type: String
              requires :channel_id, type: String
              requires :channel_name, type: String
              requires :team_id, type: String
            end
            post '/command' do
              command = SlackRubyBotServer::Events::Requests::Command.new(params, request)
              command_name = command[:command]
              SlackRubyBotServer::Events.config.run_callbacks(:command, command_name, command) || body(false)
            end
          end
        end
      end
    end
  end
end

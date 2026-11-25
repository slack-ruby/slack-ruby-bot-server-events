# frozen_string_literal: true

module SlackRubyBotServer
  module Events
    module Api
      module Endpoints
        module Slack
          class ActionsEndpoint < Grape::API
            desc 'Respond to interactive slack buttons and actions.'
            params do
              requires :payload, type: JSON do
                requires :type, type: String
                given type: ->(val) { %w[message_action shortcut].include? val } do
                  requires :token, type: String
                  requires :callback_id, type: String
                  optional :trigger_id, type: String
                  optional :response_url, type: String
                  optional :channel, type: Hash do
                    requires :id, type: String
                    optional :name, type: String
                  end
                  requires :user, type: Hash do
                    requires :id, type: String
                    optional :name, type: String
                  end
                  requires :team, type: Hash do
                    requires :id, type: String
                    optional :domain, type: String
                  end
                  optional :actions, type: Array do
                    requires :value, type: String
                  end
                  optional :message, type: Hash do
                    requires :type, type: String
                    optional :user, type: String
                    requires :ts, type: String
                    requires :text, type: String
                  end
                end

                given type: ->(val) { val == 'block_actions' } do
                  optional :trigger_id, type: String
                  optional :response_url, type: String
                  requires :token, type: String
                  requires :user, type: Hash do
                    requires :id, type: String
                    optional :name, type: String
                  end
                  requires :team, type: Hash do
                    requires :id, type: String
                    optional :domain, type: String
                  end
                  requires :actions, type: Array do
                    requires :action_id, type: String
                    optional :block_id, type: String
                    optional :type, type: String
                    optional :action_ts, type: String
                  end
                  optional :message, type: Hash do
                    requires :type, type: String
                    optional :user, type: String
                    requires :ts, type: String
                    requires :text, type: String
                    optional :blocks, type: Array do
                      requires :type, type: String
                      requires :block_id, type: String
                    end
                  end
                end

                given type: ->(val) { val == 'block_suggestion' } do
                  optional :token, type: String
                  requires :action_id, type: String
                  optional :block_id, type: String
                  optional :value, type: String
                  requires :user, type: Hash do
                    requires :id, type: String
                    optional :name, type: String
                  end
                  requires :team, type: Hash do
                    requires :id, type: String
                    optional :domain, type: String
                  end
                end

                given type: ->(val) { %w[view_submission view_closed].include? val } do
                  optional :token, type: String
                  optional :trigger_id, type: String
                  requires :user, type: Hash do
                    requires :id, type: String
                    optional :name, type: String
                  end
                  requires :team, type: Hash do
                    requires :id, type: String
                    optional :domain, type: String
                  end
                  requires :view, type: Hash do
                    requires :id, type: String
                    optional :type, type: String
                    optional :callback_id, type: String
                    optional :private_metadata, type: String
                  end
                end
              end
            end
            post '/action' do
              action = SlackRubyBotServer::Events::Requests::Action.new(params, request)
              payload_type = params[:payload][:type]
              callback_id = if %w[view_submission view_closed].include?(payload_type)
                              params[:payload].dig(:view, :callback_id).presence
                            else
                              params[:payload][:callback_id]
                            end
              action_ids = if payload_type == 'block_suggestion'
                             [params[:payload][:action_id]]
                           else
                             params[:payload].fetch(:actions, []).map { |entity| entity[:action_id] }
                           end
              SlackRubyBotServer::Events.config.run_callbacks(
                :action,
                ([payload_type, callback_id] + action_ids).compact,
                action
              ) || body(false)
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Events::Api::Endpoints::Slack::ActionsEndpoint do
  include SlackRubyBotServer::Events::Api::Test::EndpointTest

  it 'checks signature' do
    post '/api/slack/action'
    expect(last_response.status).to eq 403
    response = JSON.parse(last_response.body)
    expect(response).to eq('error' => 'Invalid Signature')
  end

  context 'without signature checks' do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    # payload type reference url: https://api.slack.com/reference/interaction-payloads
    context 'given payload type is message_actions' do
      let(:payload) do
        {
          type: 'message_action',
          channel: { id: 'C12345', name: 'channel' },
          user: { id: 'user_id' },
          team: { id: 'team_id' },
          token: 'deprecated',
          callback_id: 'action_id'
        }
      end

      shared_examples 'message_actions handler' do
        it 'performs action' do
          post '/api/slack/action', payload: payload.to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'message_action/action_id')
        end
      end

      context 'with an action handler' do
        before do
          SlackRubyBotServer::Events.configure do |config|
            config.on :action do |action|
              { text: "#{action[:payload][:type]}/#{action[:payload][:callback_id]}" }
            end
          end
        end

        it_behaves_like 'message_actions handler'

        context 'with actions in the payload' do
          before do
            payload.merge!(actions: [{ name: 'id', value: '43749' }])
          end

          it_behaves_like 'message_actions handler'
        end
      end

      context 'with a message type action handler' do
        before do
          SlackRubyBotServer::Events.configure do |config|
            config.on :action, 'message_action', 'unique_id' do |_action|
              { text: 'message_action: exact match' }
            end

            config.on :action, 'message_action' do |_action|
              { text: 'message_action: type match' }
            end

            config.on :action do |action|
              { text: "#{action[:payload][:type]}/#{action[:payload][:callback_id]}" }
            end
          end
        end

        it 'performs specific action' do
          post '/api/slack/action', payload: payload.merge(type: 'message_action', callback_id: 'unique_id').to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'message_action: exact match')
        end

        it 'performs default action' do
          post '/api/slack/action', payload: payload.merge(type: 'message_action', callback_id: 'updated').to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'message_action: type match')
        end

        it 'performs any action' do
          post '/api/slack/action', payload: payload.merge(type: 'global_shortcut', action_id: 'action_id').to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'global_shortcut/action_id')
        end
      end
    end

    context 'given payload type is block_actions' do
      let(:payload) do
        {
          type: 'block_actions',
          response_url: 'https://hooks.slack.com/api/path/to/hook',
          user: { id: 'user_id' },
          team: { id: 'team_id' },
          token: 'deprecated',
          actions: [
            { type: 'button', action_id: 'action_id' }
          ]
        }
      end

      let(:payload_without_response_url) do
        {
          type: 'block_actions',
          user: { id: 'user_id' },
          team: { id: 'team_id' },
          token: 'deprecated',
          actions: [
            { type: 'button', action_id: 'action_id' }
          ]
        }
      end

      context 'with an action handler' do
        before do
          SlackRubyBotServer::Events.configure do |config|
            config.on :action do |action|
              { text: "#{action[:payload][:type]}/#{action[:payload][:actions][0][:action_id]}" }
            end
          end
        end

        it 'performs action' do
          post '/api/slack/action', payload: payload.to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'block_actions/action_id')
        end

        it 'performs action when payload has no response url' do
          post '/api/slack/action', payload: payload_without_response_url.to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'block_actions/action_id')
        end
      end

      context 'with a block type actions handler' do
        before do
          SlackRubyBotServer::Events.configure do |config|
            config.on :action, 'block_actions', 'unique_id' do |_action|
              { text: 'block_actions: exact match' }
            end

            config.on :action, 'block_actions' do |_action|
              { text: 'block_actions: type match' }
            end
          end
        end

        it 'performs specific action' do
          post '/api/slack/action', payload: payload.merge(type: 'block_actions', actions: [{ action_id: 'unique_id' }]).to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'block_actions: exact match')
        end

        it 'performs default action' do
          post '/api/slack/action', payload: payload.merge(type: 'block_actions', actions: [{ action_id: 'updated' }]).to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'block_actions: type match')
        end
      end
    end
  end
end

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

        it 'performs specific action in a view' do
          view = { id: 'view_id', type: 'modal', callback_id: 'view_callback_id' }
          post '/api/slack/action', payload: payload.merge(actions: [{ action_id: 'unique_id' }], view: view).to_json
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq('text' => 'block_actions: exact match')
        end
      end
    end

    context 'given payload type is block_suggestion' do
      let(:payload) do
        {
          type: 'block_suggestion',
          user: { id: 'user_id' },
          team: { id: 'team_id' },
          token: 'deprecated',
          action_id: 'unique_id',
          block_id: 'block_id',
          value: 'query'
        }
      end

      before do
        SlackRubyBotServer::Events.configure do |config|
          config.on :action, 'block_suggestion', 'unique_id' do |action|
            { options: [{ text: { type: 'plain_text', text: action[:payload][:value] }, value: 'exact' }] }
          end

          config.on :action, 'block_suggestion' do |_action|
            { options: [] }
          end
        end
      end

      it 'performs specific action' do
        post '/api/slack/action', payload: payload.to_json
        expect(JSON.parse(last_response.body)).to eq(
          'options' => [{ 'text' => { 'type' => 'plain_text', 'text' => 'query' }, 'value' => 'exact' }]
        )
      end

      it 'performs default action' do
        post '/api/slack/action', payload: payload.merge(action_id: 'updated').to_json
        expect(JSON.parse(last_response.body)).to eq('options' => [])
      end

      it 'requires an action_id' do
        post '/api/slack/action', payload: payload.except(:action_id).to_json
        expect(last_response.status).to eq 400
      end
    end

    %w[view_submission view_closed].each do |type|
      context "given payload type is #{type}" do
        let(:payload) do
          {
            type: type,
            user: { id: 'user_id' },
            team: { id: 'team_id' },
            token: 'deprecated',
            view: { id: 'view_id', type: 'modal', callback_id: 'unique_id', state: { values: { block: { input: { value: 'x' } } } } }
          }
        end

        context 'with a view type actions handler' do
          before do
            SlackRubyBotServer::Events.configure do |config|
              config.on :action, type, 'unique_id' do |action|
                { text: "#{type}: exact match #{action[:payload][:view][:id]} #{action[:payload][:view][:state][:values][:block][:input][:value]}" }
              end

              config.on :action, type do |_action|
                { text: "#{type}: type match" }
              end
            end
          end

          it 'performs specific action' do
            post '/api/slack/action', payload: payload.to_json
            expect(last_response.status).to eq 201
            response = JSON.parse(last_response.body)
            expect(response).to eq('text' => "#{type}: exact match view_id x")
          end

          it 'performs default action' do
            post '/api/slack/action', payload: payload.merge(view: { id: 'view_id', callback_id: 'updated' }).to_json
            expect(last_response.status).to eq 201
            response = JSON.parse(last_response.body)
            expect(response).to eq('text' => "#{type}: type match")
          end

          it 'performs default action when the view has no callback_id' do
            post '/api/slack/action', payload: payload.merge(view: { id: 'view_id', callback_id: '' }).to_json
            expect(last_response.status).to eq 201
            response = JSON.parse(last_response.body)
            expect(response).to eq('text' => "#{type}: type match")
          end

          it 'requires a view' do
            post '/api/slack/action', payload: payload.except(:view).to_json
            expect(last_response.status).to eq 400
            response = JSON.parse(last_response.body)
            expect(response['type']).to eq 'param_error'
          end
        end
      end
    end
  end
end

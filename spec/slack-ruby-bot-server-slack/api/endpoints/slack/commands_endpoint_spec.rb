# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Slack::Api::Endpoints::Slack::CommandsEndpoint do
  include SlackRubyBotServer::Slack::Api::Test::EndpointTest

  it 'checks signature' do
    post '/api/slack/command'
    expect(last_response.status).to eq 403
    response = JSON.parse(last_response.body)
    expect(response).to eq('error' => 'Invalid Signature')
  end

  context 'without signature checks' do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    let(:command) do
      {
        command: '/invalid',
        text: 'invalid`',
        channel_id: 'channel',
        channel_name: 'channel_name',
        user_id: 'user_id',
        team_id: 'team_id',
        token: 'deprecated'
      }
    end

    it 'returns nothing if command is not handled' do
      post '/api/slack/command', command
      expect(last_response.status).to eq 204
    end

    context 'with a command' do
      before do
        SlackRubyBotServer::Slack.configure do |config|
          config.on :command do |command|
            case command[:command]
            when '/test'
              { text: 'Success!' }
            else
              { text: "Unknown command: #{command[:command]}" }
            end
          end
        end
      end

      it 'invokes command' do
        post '/api/slack/command', command.merge(command: '/test')
        expect(last_response.status).to eq 201
        response = JSON.parse(last_response.body)
        expect(response).to eq('text' => 'Success!')
      end

      it 'handles unknown command' do
        post '/api/slack/command', command.merge(command: '/invalid')
        expect(last_response.status).to eq 201
        response = JSON.parse(last_response.body)
        expect(response).to eq('text' => 'Unknown command: /invalid')
      end
    end
  end
end

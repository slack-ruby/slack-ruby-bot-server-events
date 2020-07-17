# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Slack::Api::Endpoints::Slack::EventsEndpoint do
  include SlackRubyBotServer::Slack::Api::Test::EndpointTest

  it 'checks signature' do
    post '/api/slack/event'
    expect(last_response.status).to eq 403
    response = JSON.parse(last_response.body)
    expect(response).to eq('error' => 'Invalid Signature')
  end

  context 'without signature checks' do
    before do
      allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
    end

    context 'with an unfurl event' do
      before do
        SlackRubyBotServer::Slack.configure do |config|
          config.on :event do |event|
            if event[:type] == 'event_callback' && event[:event][:type] == 'link_shared'
              event[:event][:links].each do |link|
                next unless link[:domain] == 'example.com'

                event.logger.info "UNFURL: #{link[:url]}"

                Slack::Web::Client.new.chat_unfurl(
                  channel: event[:event][:channel],
                  ts: event[:event][:message_ts],
                  unfurls: {
                    link[:url] => { text: 'unfurl' }
                  }.to_json
                )
              end
            else
              raise "Event #{event[:type]} is not supported."
            end
          end
        end
      end

      it 'performs built-in event challenge' do
        post '/api/slack/event',
             type: 'url_verification',
             challenge: 'challenge',
             token: 'deprecated'
        expect(last_response.status).to eq 201
        response = JSON.parse(last_response.body)
        expect(response).to eq('challenge' => 'challenge')
      end

      it 'unfurls a URL' do
        expect_any_instance_of(Slack::Web::Client).to receive(:chat_unfurl).with(
          channel: 'C1',
          ts: '1547842100.001400',
          unfurls: {
            'https://www.example.com' => { 'text' => 'unfurl' }
          }.to_json
        )

        post '/api/slack/event',
             token: 'deprecated',
             team_id: 'team_id',
             api_app_id: 'A19GAJ72T',
             event: {
               type: 'link_shared',
               user: 'user_id',
               channel: 'C1',
               message_ts: '1547842100.001400',
               links: [{
                 url: 'https://www.example.com',
                 domain: 'example.com'
               }]
             },
             type: 'event_callback',
             event_id: 'EvFGTNRKLG',
             event_time: 1_547_842_101,
             authed_users: ['U04KB5WQR']

        expect(last_response.status).to eq 201
      end
    end
  end
end

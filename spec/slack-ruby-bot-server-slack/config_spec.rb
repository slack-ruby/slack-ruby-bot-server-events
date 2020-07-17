# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Slack::Config do
  it 'defaults signature_expires_in' do
    expect(SlackRubyBotServer::Slack.config.signature_expires_in).to eq 300
  end
  context 'with ENV[SLACK_SIGNING_SECRET] set' do
    before do
      allow(ENV).to receive(:[]) { |k| "#{k} was set" }
      SlackRubyBotServer::Slack.config.reset!
    end
    it 'sets signing_secret' do
      expect(SlackRubyBotServer::Slack.config.signing_secret).to eq 'SLACK_SIGNING_SECRET was set'
    end
  end
  %i[
    signing_secret
    signature_expires_in
  ].each do |k|
    context "with #{k} set" do
      before do
        SlackRubyBotServer::Slack.configure do |config|
          config.send("#{k}=", 'set')
        end
      end
      it "sets and returns #{k}" do
        expect(SlackRubyBotServer::Slack.config.send(k)).to eq 'set'
      end
    end
  end
end

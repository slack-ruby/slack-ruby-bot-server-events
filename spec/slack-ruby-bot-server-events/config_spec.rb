# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Events::Config do
  it 'defaults signature_expires_in' do
    expect(SlackRubyBotServer::Events.config.signature_expires_in).to eq 300
  end

  context 'with ENV[SLACK_SIGNING_SECRET] set' do
    before do
      allow(ENV).to receive(:fetch) { |k| "#{k} was set" }
      SlackRubyBotServer::Events.config.reset!
    end

    it 'sets signing_secret' do
      expect(SlackRubyBotServer::Events.config.signing_secret).to eq 'SLACK_SIGNING_SECRET was set'
    end
  end

  %i[
    signing_secret
    signature_expires_in
  ].each do |k|
    context "with #{k} set" do
      before do
        SlackRubyBotServer::Events.configure do |config|
          config.send("#{k}=", 'set')
        end
      end

      it "sets and returns #{k}" do
        expect(SlackRubyBotServer::Events.config.send(k)).to eq 'set'
      end
    end
  end

  context 'with a callback that raises an error' do
    let(:logger) { SlackRubyBotServer::Api::Middleware.logger }
    let(:callback) { proc { |_event| raise ArgumentError, 'invalid' } }
    let(:location) { callback.source_location.first(2).join(':') }

    before do
      allow(logger).to receive(:error)
      SlackRubyBotServer::Events.configure do |config|
        config.on :event, 'event_callback', 'team_join', &callback
      end
    end

    def run_callbacks
      SlackRubyBotServer::Events.config.run_callbacks(:event, %w[event_callback team_join], {})
    end

    it 're-raises the error' do
      expect { run_callbacks }.to raise_error(ArgumentError, 'invalid')
    end

    def run_callbacks_ignoring_errors
      run_callbacks
    rescue ArgumentError
      nil
    end

    it 'logs the error class, callback key, location, and message' do
      run_callbacks_ignoring_errors
      expect(logger).to have_received(:error).with(
        "#{ArgumentError.name} in event/event_callback/team_join callback defined at #{location}: invalid"
      )
    end
  end

  context 'with a callback that returns a value' do
    let(:logger) { SlackRubyBotServer::Api::Middleware.logger }

    before do
      allow(logger).to receive(:error)
      SlackRubyBotServer::Events.configure do |config|
        config.on :event, 'event_callback' do |_event|
          { ok: true }
        end
      end
    end

    it 'returns the value without logging an error' do
      SlackRubyBotServer::Events.config.run_callbacks(:event, %w[event_callback team_join], {})
      expect(logger).not_to have_received(:error)
    end
  end
end

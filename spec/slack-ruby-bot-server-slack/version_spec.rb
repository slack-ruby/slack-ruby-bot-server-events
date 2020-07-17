# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Slack do
  it 'has a version' do
    expect(SlackRubyBotServer::Slack::VERSION).to_not be nil
  end
end

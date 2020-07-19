# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Events do
  it 'has a version' do
    expect(SlackRubyBotServer::Events::VERSION).to_not be nil
  end
end

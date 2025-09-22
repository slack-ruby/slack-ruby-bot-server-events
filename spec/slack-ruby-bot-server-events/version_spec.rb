# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Events do
  it 'has a version' do
    expect(SlackRubyBotServer::Events::VERSION).not_to be_nil
  end
end

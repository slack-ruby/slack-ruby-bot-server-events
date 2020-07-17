# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    SlackRubyBotServer::Slack::Config.reset!
  end
end

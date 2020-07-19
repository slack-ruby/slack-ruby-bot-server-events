# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    SlackRubyBotServer::Events::Config.reset!
  end
end

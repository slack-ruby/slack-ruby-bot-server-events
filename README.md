Slack Ruby Bot Server Slack Extensions
======================================

[![Gem Version](https://badge.fury.io/rb/slack-ruby-bot-server-slack.svg)](https://badge.fury.io/rb/slack-ruby-bot-server-slack)
[![Build Status](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-slack.svg?branch=master)](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-slack)

An extension to [slack-ruby-bot-server](https://github.com/slack-ruby/slack-ruby-bot-server) that enables handling of Slack slash commands, interactive buttons and events.

### Sample

See [slack-ruby/slack-ruby-bot-server-slack-sample](https://github.com/slack-ruby/slack-ruby-bot-server-slack-sample) for a working sample.

### Usage

#### Gemfile

Add 'slack-ruby-bot-server-slack' to Gemfile.

```ruby
gem 'slack-ruby-bot-server-slack'
```

#### Configure

```ruby
SlackRubyBotServer::Slack.configure do |config|
  config.signing_secret = 'secret'
end
```

The following settings are supported.

setting               | description
----------------------|------------------------------------------------------------------
signing_secret        | Slack signing secret, defaults is `ENV['SLACK_SIGNING_SECRET']`.
signature_expires_in  | Signature expiration window in seconds, default is `300`.

#### Implement Callbacks

This library supports events, actions and commands. When implementing multiple callbacks for each type, the response from the first callback to return a non `nil` value will be used and no further callbacks will be invoked. Callbacks receive subclasses of [SlackRubyBotServer::Slack::Requests::Request](lib/slack-ruby-bot-server-slack/requests/request.rb).

#### Events

Handle the [Slack Events API](https://api.slack.com/events-api) by implementing `SlackRubyBotServer::Slack::Config#on :event`.

The following example unfurls URLs.

```ruby
SlackRubyBotServer::Slack.configure do |config|
  config.on :event do |event|
    next unless event[:type] == 'event_callback'
    next unless event[:event][:type] == 'link_shared'

    event[:event][:links].each do |link|
      Slack::Web::Client.new(token: '...').chat_unfurl(
        channel: event[:event][:channel],
        ts: event[:event][:message_ts],
        unfurls: {
          link[:url] => { text: 'Unfurled URL.' }
        }.to_json
      )
    end

    true
  end
end
```


#### Actions

Respond to [Interactive Message Buttons](https://api.slack.com/legacy/message-buttons) by implementing `SlackRubyBotServer::Slack::Config#on :action`.

```ruby
SlackRubyBotServer::Slack.configure do |config|
  config.on :action do |action|
    return unless action[:payload][:callback_id] == 'action_id'

    { text: 'Success!' }
  end
end
```

#### Commands

Respond to [Slash Commands](https://api.slack.com/interactivity/slash-commands) by implementing `SlackRubyBotServer::Slack::Config#on :command`.

```ruby
SlackRubyBotServer::Slack.configure do |config|
  config.on :command do |command|
    next unless command[:command] == '/test'

    { text: 'Success!' }
  end
end
```

### Copyright & License

Copyright [Daniel Doubrovkine](http://code.dblock.org) and Contributors, 2020

[MIT License](LICENSE)

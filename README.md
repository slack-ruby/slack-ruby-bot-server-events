Slack Ruby Bot Server Events Extension
======================================

[![Gem Version](https://badge.fury.io/rb/slack-ruby-bot-server-events.svg)](https://badge.fury.io/rb/slack-ruby-bot-server-events)
[![lint](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/rubocop.yml/badge.svg)](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/rubocop.yml)
[![test with mongodb](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/test-mongodb.yml/badge.svg)](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/test-mongodb.yml)
[![test with postgresql](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/test-postgresql.yml/badge.svg)](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/test-postgresql.yml)

An extension to [slack-ruby-bot-server](https://github.com/slack-ruby/slack-ruby-bot-server) that makes it easy to handle Slack slash commands, interactive buttons and events.

### Table of Contents

- [Sample](#sample)
- [Usage](#usage)
  - [Gemfile](#gemfile)
  - [Configure](#configure)
    - [OAuth](#oauth)
    - [Events](#events)
  - [Implement Callbacks](#implement-callbacks)
  - [Events](#events-1)
  - [Actions](#actions)
  - [Commands](#commands)
- [Copyright & License](#copyright--license)

### Sample

See [slack-ruby/slack-ruby-bot-server-events-sample](https://github.com/slack-ruby/slack-ruby-bot-server-events-sample) for a working sample.

### Usage

#### Gemfile

Add 'slack-ruby-bot-server-events' to Gemfile.

```ruby
gem 'slack-ruby-bot-server-events'
```

#### Configure

##### OAuth

Configure your app's [OAuth version](https://api.slack.com/authentication/oauth-v2) and [scopes](https://api.slack.com/legacy/oauth-scopes) as needed by your application.

```ruby
SlackRubyBotServer.configure do |config|
  config.oauth_version = :v2
  config.oauth_scope = ['users:read', 'channels:read', 'groups:read', 'chat:write', 'commands', 'incoming-webhook']
end
```

##### Events

Configure events-specific settings.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.signing_secret = 'secret'
end
```

The following settings are supported.

setting               | description
----------------------|------------------------------------------------------------------
signing_secret        | Slack signing secret, defaults is `ENV['SLACK_SIGNING_SECRET']`.
signature_expires_in  | Signature expiration window in seconds, default is `300`.

Get the signing secret from [your app's](https://api.slack.com/apps) _Basic Information_ settings.

#### Implement Callbacks

This library supports events, actions and commands. When implementing multiple callbacks for each type, the response from the first callback to return a non `nil` value will be used and no further callbacks will be invoked. Callbacks receive subclasses of [SlackRubyBotServer::Events::Requests::Request](lib/slack-ruby-bot-server-events/requests/request.rb).

#### Events

Respond to [Slack Events](https://api.slack.com/events-api) by implementing `SlackRubyBotServer::Events::Config#on :event`.

The following example unfurls URLs.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :event, 'event_callback', 'link_shared' do |event|
    event[:event][:links].each do |link|
      Slack::Web::Client.new(token: ...).chat_unfurl(
        channel: event[:event][:channel],
        ts: event[:event][:message_ts],
        unfurls: {
          link[:url] => { text: 'Unfurled URL.' }
        }.to_json
      )
    end

    true # return true to avoid invoking further callbacks
  end

  config.on :event, 'event_callback' do |event|
    # handle any event callback
    false
  end

  config.on :event do |event|
    # handle any event[:event][:type]
    false
  end
end
```


#### Actions

Respond to [Shortcuts](https://api.slack.com/interactivity/shortcuts) and [Interactive Messages](https://api.slack.com/messaging/interactivity) as well as [Attached Interactive Message Buttons(Outmoded)](https://api.slack.com/legacy/message-buttons) by implementing `SlackRubyBotServer::Events::Config#on :action`.

The following example posts an ephemeral message that counts the letters in a message shortcut.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :action, 'interactive_message', 'action_id' do |action|
    payload = action[:payload]
    message = payload[:message]

    Faraday.post(payload[:response_url], {
      text: "The text \"#{message[:text]}\" has #{message[:text].size} letter(s).",
      response_type: 'ephemeral'
    }.to_json, 'Content-Type' => 'application/json')

    { ok: true }
  end

  config.on :action do |action|
    # handle any other action
    false
  end
end
```

The following example responds to an interactive message.  
You can compose rich message layouts using [Block Kit Builder](https://app.slack.com/block-kit-builder).

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :action, 'block_actions', 'your_action_id' do |action|
    payload = action[:payload]

    Faraday.post(payload[:response_url], {
      text: "The action \"your_action_id\" has been invoked.",
      response_type: 'ephemeral'
    }.to_json, 'Content-Type' => 'application/json')

    { ok: true }
  end
end
```

#### Commands

Respond to [Slash Commands](https://api.slack.com/interactivity/slash-commands) by implementing `SlackRubyBotServer::Events::Config#on :command`.

The following example responds to `/ping` with `pong`.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :command, '/ping' do
    { text: 'pong' }
  end

  config.on :command do |command|
    # handle any other command
    false
  end
end
```

### Copyright & License

Copyright [Daniel Doubrovkine](http://code.dblock.org) and Contributors, 2020

[MIT License](LICENSE)

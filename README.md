# Slack Ruby Bot Server Events Extension

[![Gem Version](https://badge.fury.io/rb/slack-ruby-bot-server-events.svg)](https://badge.fury.io/rb/slack-ruby-bot-server-events) [![Lint](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/lint.yml/badge.svg)](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/lint.yml) [![Test](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/test.yml/badge.svg)](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions/workflows/test.yml)

An extension to [slack-ruby-bot-server](https://github.com/slack-ruby/slack-ruby-bot-server) that makes it easy to handle Slack slash commands, interactive buttons and events.

## Table of Contents

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
- [Testing](#testing)
- [Copyright & License](#copyright--license)

## Sample

See [slack-ruby/slack-ruby-bot-server-events-sample](https://github.com/slack-ruby/slack-ruby-bot-server-events-sample) for a working sample.

## Usage

### Gemfile

Add 'slack-ruby-bot-server-events' to Gemfile.

```ruby
gem 'slack-ruby-bot-server-events'
```

### Configure

#### OAuth

Configure your app's [OAuth version](https://api.slack.com/authentication/oauth-v2) and [scopes](https://api.slack.com/legacy/oauth-scopes) as needed by your application.

```ruby
SlackRubyBotServer.configure do |config|
  config.oauth_version = :v2
  config.oauth_scope = ['users:read', 'channels:read', 'groups:read', 'chat:write', 'commands', 'incoming-webhook']
end
```

#### Events

Configure events-specific settings.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.signing_secret = 'secret'
end
```

The following settings are supported.

setting                | description
---------------------- | ------------------------------------------------------------------
signing_secret         | Slack signing secret, default is `ENV['SLACK_SIGNING_SECRET']`.
signature_expires_in   | Signature expiration window in seconds, default is `300`.

Get the signing secret from [your app's](https://api.slack.com/apps) _Basic Information_ settings.

### Implement Callbacks

This library supports events, actions and commands. When implementing multiple callbacks for each type, the response from the first callback to return a non `nil` value will be used and no further callbacks will be invoked. Callbacks receive subclasses of [SlackRubyBotServer::Events::Requests::Request](lib/slack-ruby-bot-server-events/requests/request.rb). When a callback raises an error, the error is logged with the callback's key, such as `event/event_callback/team_join`, and the file and line where the callback was defined, then raised again.

### Events

Respond to [Slack Events](https://api.slack.com/events-api) by implementing `SlackRubyBotServer::Events::Config#on :event`.

The following example unfurls URLs.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :event, 'event_callback', 'link_shared' do |event|
    team = Team.where(team_id: event[:team_id]).first
    event[:event][:links].each do |link|
      Slack::Web::Client.new(token: team.token).chat_unfurl(
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

Pass an array of values to handle several events with one callback.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :event, 'event_callback', %w[pin_added pin_removed] do |event|
    # handle event[:event][:type] of pin_added or pin_removed
    true
  end
end
```

### Actions

Respond to [Shortcuts](https://api.slack.com/interactivity/shortcuts) and [Interactive Messages](https://api.slack.com/messaging/interactivity) as well as [Attached Interactive Message Buttons (Outmoded)](https://api.slack.com/legacy/message-buttons) by implementing `SlackRubyBotServer::Events::Config#on :action`.

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

The following example responds to an interactive message. You can compose rich message layouts using [Block Kit Builder](https://app.slack.com/block-kit-builder).

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :action, 'block_actions', 'your_action_id' do |action|
    payload = action[:payload]

    Faraday.post(payload[:response_url], {
      text: 'The action "your_action_id" has been invoked.',
      response_type: 'ephemeral'
    }.to_json, 'Content-Type' => 'application/json')

    { ok: true }
  end
end
```

The following example handles the submission of a [modal](https://api.slack.com/surfaces/modals) opened with `callback_id: 'your_callback_id'`. For `view_submission` and `view_closed` payloads the callback ID is read from `payload.view.callback_id`.

```ruby
SlackRubyBotServer::Events.configure do |config|
  config.on :action, 'view_submission', 'your_callback_id' do |action|
    values = action[:payload][:view][:state][:values]
    action.logger.info "Submitted #{values}."
    { response_action: 'clear' }
  end
end
```

### Commands

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

## Testing

Test callbacks by posting a request to the API with [Rack::Test](https://github.com/rack/rack-test) and stubbing Slack's signature verification. Pass the parameters as the second argument to `post`, not as `params:`, and include every parameter that Slack sends and the endpoint requires, otherwise the API responds with a `400` error before any callback runs. Check the response status to catch such errors.

The following spec tests the `/ping` command above.

```ruby
describe '/ping' do
  include Rack::Test::Methods

  def app
    SlackRubyBotServer::Api::Middleware.instance
  end

  before do
    allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
  end

  let(:command) do
    {
      command: '/ping',
      text: '',
      token: 'deprecated',
      user_id: 'U12345',
      channel_id: 'C12345',
      channel_name: 'general',
      team_id: 'T12345'
    }
  end

  it 'responds with pong' do
    post '/api/slack/command', command
    expect(last_response.status).to eq 201
    expect(JSON.parse(last_response.body)).to eq('text' => 'pong')
  end
end
```

Events are posted to `/api/slack/event` and actions to `/api/slack/action` with a JSON `payload` parameter, for example `post '/api/slack/action', payload: { type: 'block_actions', ... }.to_json`. See [spec/slack-ruby-bot-server-events/api/endpoints/slack](spec/slack-ruby-bot-server-events/api/endpoints/slack) for more examples.

## Copyright & License

Copyright [Daniel Doubrovkine](http://code.dblock.org) and Contributors, 2020-2025

[MIT License](LICENSE)

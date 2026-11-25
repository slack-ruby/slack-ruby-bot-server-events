# frozen_string_literal: true

require 'ruby-gem-release/changelog'
require 'ruby-gem-release/workflow/ruby_gem'

# Builds the ruby-gem-release workflow used by the Rakefile, the Release GitHub Actions workflow, and spec/release.
module SlackRubyBotServerEventsRelease
  def self.workflow(**options)
    RubyGemRelease::Workflow::RubyGem.new(
      version: RubyGemRelease::Version::RubyConstant.new(path: 'lib/slack-ruby-bot-server-events/version.rb', constant: 'VERSION'),
      changelog: RubyGemRelease::Changelog::Intridea.new(placeholder: '* Your contribution here.'),
      **options
    )
  end
end

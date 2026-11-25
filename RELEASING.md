# Releasing Slack-Ruby-Bot-Server-Events

There are no hard rules about when to release slack-ruby-bot-server-events. Release bug fixes frequently, features not so frequently and breaking API changes rarely.

## Release

Run tests, check that all tests succeed locally.

```sh
bundle install
rake
```

Check that the last build succeeded in [GitHub Actions](https://github.com/slack-ruby/slack-ruby-bot-server-events/actions) for all supported platforms.

Change "Next" in [CHANGELOG.md](CHANGELOG.md) to the current date.

```markdown
#### 0.2.2 (2015/07/10)
```

Remove the line with "Your contribution here.", since there will be no more contributions to this release.

Commit your changes.

```sh
git add CHANGELOG.md
git commit -m "Preparing for release, 0.2.2."
git push origin master
```

Release.

```text
$ rake release

slack-ruby-bot-server-events 0.2.2 built to pkg/slack-ruby-bot-server-events-0.2.2.gem.
Tagged v0.2.2.
Pushed git commits and tags.
Pushed slack-ruby-bot-server-events 0.2.2 to rubygems.org.
```

## Prepare for the Next Version

Add the next release to [CHANGELOG.md](CHANGELOG.md).

```markdown
#### 0.2.3 (Next)

* Your contribution here.
```

Increment the third version number in [lib/slack-ruby-bot-server-events/version.rb](lib/slack-ruby-bot-server-events/version.rb).

Commit your changes.

```sh
git add CHANGELOG.md lib/slack-ruby-bot-server-events/version.rb
git commit -m "Preparing for next development iteration, 0.2.3."
git push origin master
```

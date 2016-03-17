# ActiveRecordObserver

Designed to help with understanding how a particular block of code changes your `ActiveRecord` objects. See what gets changed, what type of objects are created, and what the values on those objects are. It can also display the sequence of callbacks that was triggered.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record_observer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_observer

## Usage

```
# With defaults:
ActiveRecord::Observer::Watcher.new.observe { @some_ar_object.do_something_that_triggers_callbacks }

# With the tracer disabled:
ActiveRecord::Observer::Watcher.new(:tracer => false).observe { @some_ar_object.do_something_that_triggers_callbacks }
```

To disable the tracker, pass the option `:tracker => false`
To disable the tracer, pass the option `:tracer => false`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ajesler/active_record_observer.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


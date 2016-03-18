# ActiveRecordObserver

Designed to help with understanding how a particular block of code changes your `ActiveRecord` objects. See what gets changed, what type of objects are created, and what the values on those objects are. It can also display the sequence of callbacks that was triggered.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'te_aro'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install te_aro

## Usage

```ruby
# With defaults:
TeAro::Observer.new.observe { @some_ar_object.do_something_that_triggers_callbacks }

# With the tracer disabled:
TeAro::Observer.new(:tracer => false).observe { @some_ar_object.do_something_that_triggers_callbacks }

# Can also use the Kernel#aro method to do
aro { @some_ar_object.do_something }
```


### Output

By default, output is logged to `log/te_aro.log`. This can be changed by passing a `Logger` instance when constructing the observer.

Eg to log to STDOUT
```ruby
TeAro::Observer.new(:logger = Logger.new(STDOUT)).observe { some_ar_object.do_something }
```


### Options

Options are passed as a hash to `Observer.new`.

The following options are available:

* `:tracer` Show the ActiveRecord callbacks that were called. A falsey value will turn this off.
* `:tracker` Show ActiveRecord objects that have been created or changed. A falsey value will turn this off.
* `:logger` Sets the logger used to record output.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powershop/te_aro.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
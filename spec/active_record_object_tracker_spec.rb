require 'spec_helper'
require 'byebug'

ENABLE_LOG = false

LOGGER = Logger.new(STDOUT)
LOGGER.formatter = proc do |severity, datetime, progname, msg|
  "\t#{msg}\n"
end

def maybe_log(tracker)
  tracker.log_results(LOGGER) if ENABLE_LOG
end

describe TeAro::ActiveRecordObjectTracker do
  after(:each) { ObjectSpace.garbage_collect }

  it "raises an error if 'start' is called twice" do
    expect {
      tracker = TeAro::ActiveRecordObjectTracker.new
      tracker.start
      tracker.start
    }.to raise_error(StandardError)
  end

  it "raises an error if 'stop' is called before 'start' is called" do
    expect {
      tracker = TeAro::ActiveRecordObjectTracker.new
      tracker.stop
    }.to raise_error(StandardError)
  end

  it "raises an error if 'stop' is called twice" do
    expect {
      tracker = TeAro::ActiveRecordObjectTracker.new
      tracker.start
      tracker.start
      tracker.start
    }.to raise_error(StandardError)
  end

  it "ignores objects outside of tracked code" do
    tracker = TeAro::ActiveRecordObjectTracker.new

    User.new(name: 'foo', age: 31)
    User.new(name: 'bar', age: 31)
    User.new(name: 'baz', age: 31)

    tracker.start
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:new]).to be_empty
  end

  it "tracks new unpersisted records" do
    tracker = TeAro::ActiveRecordObjectTracker.new
    tracker.start
    user = User.new(name: 'foo', age: 31)
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:new]).to contain_exactly(user)
  end

  it "tracks created objects" do
    tracker = TeAro::ActiveRecordObjectTracker.new
    tracker.start
    user = User.create(name: 'foo', age: 31)
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:created]).to contain_exactly(user)
  end

  it "tracks changed objects" do
    tracker = TeAro::ActiveRecordObjectTracker.new
    user = User.first
    tracker.start
    user.age = user.age + 1
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:changed]).to contain_exactly(user)
  end

  it "tracks updated objects" do
    tracker = TeAro::ActiveRecordObjectTracker.new
    tracker.start
    user = User.first
    user.update(age: 32)
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:updated]).to contain_exactly(user)
  end

  it "tracks detailed object updates made within tracking window" do
    tracker = TeAro::ActiveRecordObjectTracker.new
    user = User.first
    tracker.start
    user.update(age: 33)
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:object_updates].first).to include(user)
  end

  it "tracks deleted objects" do
    tracker = TeAro::ActiveRecordObjectTracker.new
    tracker.start
    # user = User.create(name: 'foo', age: 31)
    user = User.last
    user.destroy
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:deleted]).to contain_exactly user
  end

  it "only tracks given targets" do
    tracker = TeAro::ActiveRecordObjectTracker.new([User])

    tracker.start
    user = User.new(name: 'foo', age: 31)
    post = Post.new(content: 'some text', user: user)
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:new]).to contain_exactly(user)
  end

  it "tracks multiple targets" do
    tracker = TeAro::ActiveRecordObjectTracker.new([User, Post])

    tracker.start
    user = User.new(name: 'foo', age: 31)
    post = Post.new(content: 'some text', user: user)
    tracker.stop

    maybe_log(tracker)

    expect(tracker.results[:new]).to contain_exactly(user, post)
  end
end

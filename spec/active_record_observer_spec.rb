require 'spec_helper'

describe ActiveRecord::Observer::ObjectTracker do
  it "is expected to throw an error if 'before' is called twice" do
    expect {
      tracker = ActiveRecord::Observer::ObjectTracker.new
      tracker.before
      tracker.before
    }.to raise_error(StandardError)
  end

  it "is expected to throw an error if 'after' is called before 'before' is called" do
    expect {
      tracker = ActiveRecord::Observer::ObjectTracker.new
      tracker.after
    }.to raise_error(StandardError)
  end

  it "is expected to throw an error if 'after' is called twice" do
    expect {
      tracker = ActiveRecord::Observer::ObjectTracker.new
      tracker.before
      tracker.after
      tracker.after
    }.to raise_error(StandardError)
  end
end

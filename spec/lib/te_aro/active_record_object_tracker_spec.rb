# frozen_string_literal: true

require 'spec_helper'

require 'support/models/user'
require 'support/models/post'

describe TeAro::ActiveRecordObjectTracker do
  describe 'invocation' do
    let(:tracker) { TeAro::ActiveRecordObjectTracker.new }

    it 'raises an error if #start is called twice' do
      expect do
        tracker.start
        tracker.start
      end.to raise_error(RuntimeError)
    end

    it 'raises an error if #stop is called before #start is called' do
      expect do
        tracker.stop
      end.to raise_error(RuntimeError)
    end

    it 'raises an error if #stop is called twice' do
      expect do
        tracker.start
        tracker.stop
        tracker.stop
      end.to raise_error(RuntimeError)
    end
  end

  describe 'object tracking' do
    before(:each) { ObjectSpace.garbage_collect }
    let(:tracker) { TeAro::ActiveRecordObjectTracker.new }
    after(:each) { maybe_log(tracker) }

    it 'ignores objects created outside of tracking window' do
      User.new(name: 'foo', age: 31)
      User.new(name: 'bar', age: 31)
      User.new(name: 'baz', age: 31)

      tracker.start
      tracker.stop

      expect(tracker.results[:new]).to be_empty
    end

    it 'tracks new unpersisted records' do
      tracker.start
      user = User.new(name: 'foo', age: 31)
      tracker.stop

      expect(tracker.results[:new]).to contain_exactly(user)
    end

    it 'tracks created objects' do
      tracker.start
      user = User.create(name: 'foo', age: 31)
      tracker.stop

      expect(tracker.results[:created]).to contain_exactly(user)
    end

    it 'tracks changed objects' do
      user = User.first
      tracker.start
      user.age = user.age + 1
      tracker.stop

      expect(tracker.results[:changed]).to contain_exactly(user)
    end

    it 'tracks updated objects' do
      tracker.start
      user = User.first
      user.update(age: 32)
      tracker.stop

      expect(tracker.results[:updated]).to contain_exactly(user)
    end

    it 'tracks detailed object updates made within tracking window' do
      user = User.first
      tracker.start
      user.update(age: 33)
      tracker.stop

      expect(tracker.results[:object_updates].first).to include(user)
    end

    it 'tracks deleted objects' do
      tracker.start
      user = User.last
      user.destroy
      tracker.stop

      expect(tracker.results[:deleted]).to contain_exactly user
    end

    context 'given a list of targets' do
      let(:tracker) { TeAro::ActiveRecordObjectTracker.new([User]) }

      it 'only tracks given classes' do
        tracker.start
        user = User.new(name: 'foo', age: 31)
        Post.new(content: 'some text', user: user)
        tracker.stop

        expect(tracker.results[:new]).to contain_exactly(user)
      end
    end

    context 'given multiple target classes' do
      let(:tracker) { TeAro::ActiveRecordObjectTracker.new([User, Post]) }

      it 'tracks multiple targets' do
        tracker.start
        user = User.new(name: 'foo', age: 31)
        post = Post.new(content: 'some text', user: user)
        tracker.stop

        expect(tracker.results[:new]).to contain_exactly(user, post)
      end
    end
  end
end

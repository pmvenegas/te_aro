require "active_record_observer/version"
require "active_record_observer/object_tracker"
require "active_record_observer/action_trace"

module ActiveRecord
  module Observer
    class Watcher
      def initialize(options = {})
        @options = options
        @object_tracker = ObjectTracker.new if tracker?
        @action_tracer = ActionTrace.new if tracer?
      end

      def observe(&block)
        @object_tracker.before if tracker?
        @action_tracer.start if tracer?

        block.call

        @action_tracer.stop if tracer?
        @object_tracker.after if tracker?

        @action_tracer.print_trace if tracer?
        @action_tracer.print_changes if tracer?

        @object_tracker.print_changes if tracker?
      end

      private

      def tracker?
        @options.fetch(:tracker, true)
      end

      def tracer?
        @options.fetch(:tracer, true)
      end
    end
  end
end

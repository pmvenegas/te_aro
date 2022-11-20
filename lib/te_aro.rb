require "te_aro/version"
require "te_aro/object_tracker"
require "te_aro/action_tracer"

module TeAro
  class Observer
    attr_accessor :object_tracker, :action_tracer
    def initialize(options = {})
      @options = options
      @logger = @options.fetch(:logger, nil) || create_logger
      @object_tracker = ObjectTracker.new(@logger) if tracker?
      @action_tracer = ActionTracer.for_active_record(@logger) if tracer?
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
      @options.fetch(:tracer, false)
    end

    def create_logger
      logger = Logger.new('log/te_aro.log')
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
      logger
    end
  end
end

module Kernel
  def aro(&block)
    TeAro::Observer.new.observe { block.call }
  end
end

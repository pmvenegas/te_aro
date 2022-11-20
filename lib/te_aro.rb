require 'te_aro/version'
require 'te_aro/active_record_object_tracker'
require 'te_aro/active_record_action_tracer'
require 'active_record'

module TeAro
  class Observer
    DEFAULT_TARGETS = [ActiveRecord::Base]

    attr_accessor :object_tracker, :action_tracer

    def initialize(options = {})
      @options = options
      @logger = @options.fetch(:logger, nil) || create_logger
      targets = @options.fetch(:targets, DEFAULT_TARGETS)

      @object_tracker = ActiveRecordObjectTracker.new(targets) if tracker?
      @action_tracer = ActiveRecordActionTracer.new(targets) if tracer?
    end

    def observe(&block)
      @object_tracker.start if tracker?
      @action_tracer.start if tracer?

      block.call

      if tracer?
        @action_tracer.stop
        @action_tracer.log_results(@logger)
      end

      if tracker?
        @object_tracker.stop
        @object_tracker.log_results(@logger)
      end

      self
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
    quiet_logger = Logger.new(STDOUT)
    quiet_logger.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    TeAro::Observer.new(logger: quiet_logger).observe { block.call }
  end
end

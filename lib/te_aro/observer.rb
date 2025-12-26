# frozen_string_literal: true

require 'active_record'

module TeAro
  class Observer
    DEFAULT_TARGETS = [::ActiveRecord::Base].freeze

    attr_accessor :object_tracker, :logger

    def initialize(options = {})
      @options = options
      @logger = @options.fetch(:logger, nil) || create_logger
      targets = @options.fetch(:targets, DEFAULT_TARGETS)

      @object_tracker = ActiveRecordObjectTracker.new(targets)
    end

    def observe(&block)
      @object_tracker.start
      block.call
      @object_tracker.stop
      @object_tracker.log_results(@logger)

      self
    end

    private

    def create_logger
      logger = Logger.new('log/te_aro.log')
      logger.formatter = proc do |_severity, _datetime, _progname, msg|
        "#{msg}\n"
      end
      logger
    end
  end
end

module Kernel
  def aro(&block)
    quiet_logger = Logger.new($stdout)
    quiet_logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end

    TeAro::Observer.new(logger: quiet_logger).observe { block.call }
  end
end

# frozen_string_literal: true

require 'active_record'
require 'fileutils'
require 'logger'

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

    # Run the provided block while observing ActiveRecord objects.
    # Guarantees that the tracker is stopped and results are logged even when
    # the block raises. The original exception (if any) will propagate.
    def observe(&block)
      @object_tracker.start
      begin
        yield
      ensure
        # Ensure we always attempt to stop the tracker and log results.
        # Rescue errors during stop/logging so we don't hide the original exception.
        begin
          @object_tracker.stop
        rescue StandardError
          # intentionally suppressed to avoid masking original errors
        end

        begin
          @object_tracker.log_results(@logger)
        rescue StandardError
          # intentionally suppressed
        end
      end

      self
    end

    private

    def create_logger
      log_path = 'log/te_aro.log'
      dir = File.dirname(log_path)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

      logger = Logger.new(log_path)
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

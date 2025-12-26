# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'te_aro'
require 'active_record'
require 'support/setup_database'

# Standalone ActiveRecord config for specs
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'test.db')

ENABLE_LOG = true

LOGGER = Logger.new($stdout)
LOGGER.formatter = proc do |_severity, _datetime, _progname, msg|
  "\t#{msg}\n"
end

def maybe_log(service)
  service.log_results(LOGGER) if ENABLE_LOG
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'te_aro'
require 'active_record'
require 'support/setup_database'

# Standalone ActiveRecord config for specs
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'test.db')

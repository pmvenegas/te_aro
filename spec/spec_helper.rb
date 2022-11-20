$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# Standalone ActiveRecord config for specs
require 'active_record'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'test.db')

require 'te_aro'

require 'setup_database'

require 'models'

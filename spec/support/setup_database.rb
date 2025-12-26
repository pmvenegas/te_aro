# frozen_string_literal: true

require 'sqlite3'

db = SQLite3::Database.new 'test.db'

db.execute <<-SQL
  DROP TABLE IF EXISTS users;
SQL
db.execute <<-SQL
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(30) NOT NULL,
    age INTEGER,
    created_at DATETIME,
    updated_at DATETIME
  );
SQL
db.execute <<-SQL
  DROP TABLE IF EXISTS posts;
SQL
db.execute <<-SQL
  CREATE TABLE posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content VARCHAR(255) NOT NULL,
    user_id INTEGER,
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY(user_id) REFERENCES users(id)
  );
SQL
db.execute <<-SQL
  INSERT INTO users values(1, 'dummy', 31, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
SQL

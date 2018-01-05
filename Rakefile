require 'bundler'
Bundler.require(:default, :dev)

require_relative './app/config/defaults'

desc 'Create mongodb indexes'
task :create_indexes do
  first_try = true
  begin
    Mongoid::Tasks::Database::create_indexes
  rescue => e
    if first_try
      Mongoid::Tasks::Database::remove_indexes
      retry
    else
      raise e
    end
  end
end

desc 'Remove mongodb indexes'
task :remove_indexes do
  Mongoid::Tasks::Database::remove_indexes
end

task :console do
  pry
end

require 'rubygems'
require 'bundler/setup'

require 'erb'
require 'yaml'
require 'cequel'
require 'colorize'
require 'faker'

class User
  include Cequel::Record

  key :id, :timeuuid, auto: true
  column :name, :text, index: true
  column :surname, :text, index: true
  column :age, :int
  map :images, :text, :text
  column :is_admin, :boolean
  timestamps
end

puts 'Connecting to cluster ...'.colorize(:green)

config_path = 'config/cequel.yml'
config_yaml = ERB.new(File.read(config_path)).result
configuration = YAML.load(config_yaml).deep_symbolize_keys
connection = Cequel.connect(configuration)
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
connection.logger = logger
Cequel::Record.connection = connection

puts 'Creating keyspace ...'.colorize(:green)
begin
  Cequel::Record.connection.schema.create!
rescue Cassandra::Errors::AlreadyExistsError
  puts 'Keyspace already exists'.colorize(:red)
end

puts 'Synchronizing User mode ...'.colorize(:green)
User.synchronize_schema

puts 'Removing all users'.colorize(:yellow)
User.delete_all

1.upto(10_000) do |i|
  User.create(
    name:     Faker::Name.first_name,
    surname:  Faker::Name.last_name,
    age:      Faker::Number.between(1, 100),
    images:   {
      i1: Faker::Internet.url,
      i2: Faker::Internet.url,
      i3: Faker::Internet.url
    },
    is_admin: [true, false].sample
  )
end

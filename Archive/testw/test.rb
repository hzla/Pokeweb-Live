require 'dotenv'
require 'httparty'
Dotenv.load
require 'pry'

Dir["models/*.rb"].each {|file| require_relative file}



response = Trade.query

binding.pry
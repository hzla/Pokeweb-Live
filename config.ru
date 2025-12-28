require File.expand_path('routes', File.dirname(__FILE__))

set :session_secret, ENV['KEY']
enable :sessions
use Rack::Session::Pool, :domain => 'http://45.33.47.157/', :expire_after => 60 * 60 * 24 * 3650000

if ENV["DEVMODE"] == "TRUE"
	use Rack::Session::Pool, :domain => 'localhost', :expire_after => 60 * 60 * 24 * 3650000
end
Dotenv.load

p ARGV


run MyApp
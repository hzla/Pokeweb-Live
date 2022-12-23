require File.expand_path('routes', File.dirname(__FILE__))

set :session_secret, ENV['KEY']
enable :sessions
use Rack::Session::Pool, :domain => 'fishbowlweb.cloud', :expire_after => 60 * 60 * 24 * 3650000
Dotenv.load



run MyApp
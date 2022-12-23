require File.expand_path('routes', File.dirname(__FILE__))


enable :sessions
use Rack::Session::Pool, :domain => 'fishbowlweb.cloud', :expire_after => 60 * 60 * 24 * 3650000


run MyApp
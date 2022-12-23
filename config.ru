require File.expand_path('routes', File.dirname(__FILE__))


enable :sessions
Dotenv.load

run MyApp
require "sinatra"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

configure :development do
  require "sinatra/reloader"
end

get "/" do
  erb :home
end

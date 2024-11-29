require "sinatra"
require "tilt/erubis"

require_relative "lib/database_accessor"
require_relative "lib/user"
require_relative "lib/vault"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

configure :development do
  require "sinatra/reloader"
  also_reload "database_accessor.rb"
  also_reload "user.rb"
  also_reload "vault.rb"
end

before do
  DatabaseAccessor.connect(logger)
end

after do
  DatabaseAccessor.disconnect
end

get "/" do
  erb :home
end

# Render form to sign up as a new user
get "/users/sign-up" do
  erb :sign_up
end

# Add a new user to the database
post "/users" do
  username = params[:username].downcase
  password = params[:password]
  password_confirmation = params[:password_confirmation]

  begin
    user = User.create(
      username: username,
      password: password,
      password_confirmation: password_confirmation
    )
  rescue SignupError => error
  end

  if error
    status 422
    session[:message] = error
    erb :sign_up
  else
    Vault.add(user.id, "My Vault")
    session[:user] = user.session_hash
  end
end

# Render form to sign in as an existing user
get "/users/sign-in" do
  erb :sign_in
end

# Sign in the existing user to their account
post "/users/sign-in" do
  username = params[:username].downcase
  password = params[:password]

  begin
    user = User.login(username, password)
  rescue LoginError => error
  end

  if error
    status 422
    session[:message] = error
    erb :sign_in
  else
    session[:user] = user.session_hash
  end
end

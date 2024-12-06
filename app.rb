require "sinatra"
require "tilt/erubis"

require_relative "lib/database_accessor"
require_relative "lib/user"
require_relative "lib/vault"

def save_user_info_in_session(user)
  session[:user_id] = user.id
  session[:username] = user.username
end

def logged_in?(username)
  return false unless session[:user_id] && session[:username]
  session[:username] == username
end

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

  user = User.create(
    username: username,
    password: password,
    password_confirmation: password_confirmation
  )

  if user.error?
    status 422
    session[:message] = user.error_messages
    erb :sign_up
  else
    Vault.add(user.id, "My Vault")
    save_user_info_in_session(user)
    redirect "/#{user.username}"
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

  user = User.login(username, password)

  if user.error?
    status 422
    session[:message] = user.error_messages
    erb :sign_in
  else
    save_user_info_in_session(user)
    redirect "/#{user.username}"
  end
end

# Display user homepage
get "/:username" do
  @username = params[:username]
  redirect "/users/sign-in" unless logged_in?(@username)

  erb :dashboard
end

require "sinatra"
require "tilt/erubis"
require "bcrypt"

require_relative "database_accessor"

module Validatable
  # Return an error if username is not unique or username only has space characters. Return nil otherwise.
  def self.error_for_new_username(username, database)
    if database.find_user(username)
      "Username is already taken."
    elsif username =~ /[^a-zA-Z0-9]/
      "Username must only contain alphanumeric characters."
    end
  end

  # Return an error if passwords do not match. Return nil otherwise.
  def self.error_for_new_password(password, repeat_password)
    "Passwords do not match." unless password == repeat_password
  end

  # Return an error if there is no matching username. Return nil otherwise.
  def self.error_for_missing_user(username, database)
    "User not found." unless database.find_user(username)
  end

  # Return an error if the given password doesn't match the stored password.
  # Return nil otherwise.
  def self.error_for_invalid_password(username, given_password, database)
    user = database.find_user(username)
    hashed_password = user["password_hash"]
    password_match = (BCrypt::Password.new(hashed_password) == given_password)
    "Invalid password." unless password_match
  end
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

configure :development do
  require "sinatra/reloader"
  also_reload "database_accessor.rb"
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
  repeat_password = params[:repeat_password]

  username_error = Validatable.error_for_new_username(username, @storage)
  password_error = Validatable.error_for_new_password(password, repeat_password)

  if username_error || password_error
    status 422
    session[:message] = [username_error, password_error].join(' ')
    erb :sign_up
  else
    password_hash = BCrypt::Password.create(password)
    @storage.add_user(username, password_hash)

    user = @storage.find_user(username)
    user_id = user["id"]
    @storage.add_vault(user_id, "My Vault")

    session[:user] = username
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
  error = Validatable.error_for_missing_user(username, @storage) ||
          Validatable.error_for_invalid_password(username, password, @storage)

  if error
    status 422
    session[:message] = error
    erb :sign_in
  else
    session[:user] = username
  end
end

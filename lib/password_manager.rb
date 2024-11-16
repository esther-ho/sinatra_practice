require "sinatra"
require "tilt/erubis"
require "bcrypt"

require_relative 'database_persistence'

module Validatable
  # Return an error if username is not unique or username only has space characters. Return nil otherwise.
  def self.error_for_username(username, database)
    if database.find_user(username)
      "Username is already taken."
    elsif username =~ /[^a-zA-Z0-9]/
      "Username must only contain alphanumeric characters."
    end
  end

  # Return an error if passwords do not match. Return nil otherwise.
  def self.error_for_passwords(password, repeat_password)
    "Passwords do not match." unless password == repeat_password
  end
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

configure :development do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
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

  username_error = Validatable.error_for_username(username, @storage)
  password_error = Validatable.error_for_passwords(password, repeat_password)

  if username_error || password_error
    status 422
    session[:message] = [username_error, password_error].join(' ')
    erb :sign_up
  else
    password_hash = BCrypt::Password.create(password)
    @storage.add_user(username, password_hash)
    session[:user] = username
  end
end

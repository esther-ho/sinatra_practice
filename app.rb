require "sinatra"
require "tilt/erubis"

require_relative "lib/database_accessor"
require_relative "lib/user"
require_relative "lib/credentials"

SECONDS_PER_MIN = 60
MINUTES_PER_HOUR = 60
HOURS_PER_DAY = 24

helpers do
  def display_date(date_time)
    date_time.strftime("%e %b %Y")
  end

  def display_time(date_time)
    date_time.strftime("%l:%M %P")
  end

  def in_paragraphs(text)
    text.split("\r\n").map do |paragraph|
      "<p>#{paragraph}</p>"
    end.join
  end
end

def save_user_info_in_session(user)
  session[:user_id] = user.id
  session[:username] = user.username
end

def logged_in?
  session[:user_id] && session[:username]
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

configure :development do
  require "sinatra/reloader"
  also_reload "database_accessor.rb"
  also_reload "user.rb"
  also_reload "credentials.rb"
end

set(:require_auth) do |authenticated|
  condition do
    if authenticated && !logged_in?
      redirect "/users/signin"
    end
  end
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
get "/users/signup" do
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
    save_user_info_in_session(user)
    redirect "/passwords"
  end
end

# Render form to sign in as an existing user
get "/users/signin" do
  erb :sign_in
end

# Sign in the existing user to their account
post "/users/signin" do
  username = params[:username].downcase
  password = params[:password]

  user = User.login(username, password)

  if user.error?
    status 422
    session[:message] = user.error_messages
    erb :sign_in
  else
    save_user_info_in_session(user)
    redirect "/passwords"
  end
end

# Display all credentials stored by the user
get "/passwords", require_auth: true do
  @credentials_list = Credentials.find_all_by_user_id(session[:user_id])
  erb :credentials_list
end

# Render form to store a new set of credentials
get "/passwords/add", require_auth: true do
  erb :new_credentials
end

# Add a new set of credentials to the database
post "/passwords", require_auth: true do
  credentials = Credentials.create(
    user_id: session[:user_id],
    name: params[:entry_name],
    username: params[:entry_username],
    password: params[:entry_password],
    notes: params[:entry_notes]
  )

  if credentials.error?
    status 422
    session[:message] = credentials.error_messages
    erb :new_credentials
  else
    redirect "/passwords"
  end
end

# encoding: utf-8
require 'rubygems'
require 'bundler'
require "logger"
ENV["BUNDLE_GEMFILE"] = File.expand_path("../Gemfile", __FILE__)
Bundler.require

require "rack/oauth2/server"
require "rack/oauth2/server/admin"

require "rack/oauth2/sinatra"

$logger = Logger.new("test.log")
$logger.level = Logger::DEBUG
Rack::OAuth2::Server::Admin.configure do |config|
  config.set :logger, $logger
  config.set :logging, true
  config.set :raise_errors, true
  config.set :dump_errors, true
  config.oauth.expires_in = 86400 # a day
  config.oauth.logger = $logger
end

class MyApp < Sinatra::Base
  use Rack::Logger
  set :sessions, true
  set :show_exceptions, true

  register Rack::OAuth2::Sinatra

  oauth.database = Mongo::Connection.new["my_db"]
  oauth.authenticator = lambda do |username, password|
      "Batman" if username == "qichunren" && password == "123456"
  end

  oauth.host = "cqrorx.com"
  oauth.collection_prefix = "oauth2_prefix"

  before "/oauth/*" do
      halt oauth.deny! if oauth.scope.include?("time-travel") # Only Superman can do that
  end

    get "/oauth/authorize" do
      "client: #{oauth.client.display_name}\nscope: #{oauth.scope.join(", ")}\nauthorization: #{oauth.authorization}"
    end

    post "/oauth/grant" do
      oauth.grant! "Batman"
    end

    post "/oauth/deny" do
      oauth.deny!
    end


    # 5.  Accessing a Protected Resource

    before { @user = oauth.identity if oauth.authenticated? }

    get "/public" do
      if oauth.authenticated?
        "HAI from #{oauth.identity}"
      else
        "HAI"
      end
    end

    oauth_required "/private", "/change"

    get "/private" do
      "Shhhh"
    end

    post "/change" do
      "Woot!"
    end

    oauth_required "/calc", :scope=>"math"

    get "/calc" do
    end

    get "/user" do
      @user
    end

    get "/list_tokens" do
      oauth.list_access_tokens("Batman").map(&:token).join(" ")
    end

    run! if app_file == $0

end

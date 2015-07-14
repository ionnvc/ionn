require 'rubygems'
require 'recurly'
require 'sinatra'
require "sinatra/config_file"

config_file 'config.yml'

Recurly.subdomain      = settings.subdomain
Recurly.api_key        = settings.api_key
Recurly.js.private_key = settings.private_key

# To set a default currency for your API requests:
Recurly.default_currency = settings.default_currency

set :public_folder, File.join(File.dirname(__FILE__), '../public/')

configure do
  set :views, File.join(File.dirname(__FILE__), '../public/subscription/')
end

get '/subscription/basic' do
  @subdomain = Recurly.subdomain
  @default_currency = Recurly.default_currency
  @plan_code = 'gitlab-basic-enterprise-yearly-10'
  @signature = Recurly.js.sign :subscription => { :plan_code => @plan_code }
  erb :subscription_form
end

get '/subscription/standard' do
  @subdomain = Recurly.subdomain
  @default_currency = Recurly.default_currency
  @plan_code = 'gitlab-standard-yearly-100'
  @signature = Recurly.js.sign :subscription => { :plan_code => @plan_code }
  erb :subscription_form
end

get '/subscription/plus' do
  @subdomain = Recurly.subdomain
  @default_currency = Recurly.default_currency
  @plan_code = 'gitlab-plus-yearly-100'
  @signature = Recurly.js.sign :subscription => { :plan_code => @plan_code }
  erb :subscription_form
end

post '/subscription/success' do
  erb :success
end

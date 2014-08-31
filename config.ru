require 'sinatra'
require 'rack/csrf'
require 'erb'

require './main'

use Rack::Session::Cookie, :secret => 'change_me'
use Rack::Csrf

run Sinatra::Application
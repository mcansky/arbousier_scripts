# create a basic app with rspec, factory girl, haml, some good gems and basic layout
## first the gems
gem "factory_girl_rails", ">= 1.0.0", :group => :test
gem "haml-rails", ">= 0.3.4"
gem "rspec-rails", ">= 2.2.1", :group => [:development, :test]
gem "jquery-rails"
gem "thin"
gem "pg", :group => [:production]

# generators setup
generators = <<-GENERATORS
  g.test_framework :rspec, :fixture => true, :views => false
  g.fixture_replacement :factory_girl, :dir => "spec/factories"
GENERATORS

application generators

get "https://github.com/nathansmith/960-Grid-System/blob/master/code/css/960.css", "public/stylesheets/960.css"
get "https://github.com/nathansmith/960-Grid-System/blob/master/code/css/reset.css", "public/stylesheets/reset.css"
get "https://github.com/nathansmith/960-Grid-System/blob/master/code/css/text.css", "public/stylesheets/text.css"
<link href='http://fonts.googleapis.com/css?family=OFL+Sorts+Mill+Goudy+TT' rel='stylesheet' type='text/css'>
<link href='http://fonts.googleapis.com/css?family=Molengo' rel='stylesheet' type='text/css'>

log "Generating layout"

layout = <<-LAYOUT
!!!
%html
%head
%title #{app_name.humanize}
%link{:href => "http://fonts.googleapis.com/css?family=OFL+Sorts+Mill+Goudy+TT", :rel => "stylesheet", :type => "text/css"}
%link{:href => "http://fonts.googleapis.com/css?family=Molengo", :rel => "stylesheet", :type => "text/css"}
= stylesheet_link_tag "reset.css"
= stylesheet_link_tag "text.css"
= stylesheet_link_tag "960.css"
= stylesheet_link_tag "style"
= javascript_include_tag :defaults
= csrf_meta_tag
%body
%div.container_16{:id => "main"}
  = yield
LAYOUT

remove_file "app/views/layouts/application.html.erb"
create_file "app/views/layouts/application.html.haml", layout

create_file "log/.gitkeep"
create_file "tmp/.gitkeep"

log "Initializing git repository"
git :init
git :add => "."

if yes?("Would you like to install Devise?")
  gem("devise")
  generate("devise:install")
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate("devise", model_name)
end

log "Running rvm"
run "cd #{app_name}"
run "rvm use --create --rvmrc default@#{app_name}"

log "Installing bundler"
run "gem install bundler"

log "Running bundle install"
run "bundle install --path bundler --without production"

log "Running rspec:install"
generate("rspec:install")

log "Running jquery:install"
generate("jquery:install")

docs = <<-DOCS

Run the following commands to complete the setup of #{app_name.humanize}:

% cd #{app_name}
% rvm use --create --rvmrc default@#{app_name}
% gem install bundler
% bundle install
% script/rails generate rspec:install
% script/rails generate jquery:install

DOCS

log DOCS
# rails app template available at https://github.com/mcansky/arbousier_scripts/blob/master/rails_templates/basic.rb
# based on https://github.com/leshill/rails3-app/blob/master/app.rb
#
# create a basic app with rspec, factory girl, haml, some good gems and basic layout

## first the gems
# test stuff
gem "factory_girl_rails", ">= 1.0.0", :group => :test
gem "rspec-rails", ">= 2.2.1", :group => [:development, :test]
# shiny markup stuff
gem "haml-rails", ">= 0.3.4"
# wooot vars in css
gem 'hassle', :git => 'git://github.com/koppen/hassle.git'
# replacement for prototype.js
gem "jquery-rails"
# http server
gem "thin"
# mostly for heroku
gem "pg", :group => [:production]
# doc goodness
gem "yard"

#create rspec.rb in the config/initializers directory to use rspec as the default test framework
#initializer 'rspec.rb', <<-EOF
#  Rails.application.config.generators.test_framework :rspec, :fixture => true, :views => false
#  Rails.application.config.fixture_replacement :factory_girl, :dir => "spec/factories"
#EOF

# getting 960.gs css files
get "https://github.com/nathansmith/960-Grid-System/raw/master/code/css/960.css", "public/stylesheets/960.css"
get "https://github.com/nathansmith/960-Grid-System/raw/master/code/css/reset.css", "public/stylesheets/reset.css"
get "https://github.com/nathansmith/960-Grid-System/raw/master/code/css/text.css", "public/stylesheets/text.css"
# get the base sass file
get "https://github.com/mcansky/arbousier_scripts/raw/master/sass/style.sass", "public/stylesheets/sass/style.sass"
# get rake tasks
get "https://github.com/mcansky/arbousier_scripts/raw/master/rake_tasks/undies.rb", "lib/tasks/undies.rake"

# taking care of the layout
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

remove_file "public/index.html"
remove_file "app/views/layouts/application.html.erb"
create_file "app/views/layouts/application.html.haml", layout

# adding yardoc opts file
yardopts = <<-YARDOPTS
'lib/**/*.rb' 'app/**/*.rb' README CHANGELOG LICENSE
YARDOPTS
create_file ".yardopts", yardopts

# git stuff
create_file "log/.gitkeep"
create_file "tmp/.gitkeep"
log "Initializing git repository"
git :init
git :add => "."

# rvm rc creation
log "Running rvm"
run "rvm use --create --rvmrc ruby-1.9.2-p0@#{app_name}"

log "Installing bundler"
run "gem install bundler"

if yes?("Would you like to install Devise?")
  gem("devise")
  log "Running bundle install"
  run "bundle install --path bundler --without production"
  generate("devise:install")
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate("devise", model_name)
  log <<-DOCS

  Congratulations #{app_name.humanize} is generated with :
    * factory girl
    * rspec
    * haml
    * jquery
    * 960.gs
    * thin
    * devise

  Now simply go in your app
  % cd #{app_name}
  DOCS
else
  if yes?("Do you want to run bundle install now ?")
    log "Running bundle install"
    run "bundle install --path bundler --without production"

    log "Running rspec:install"
    generate("rspec:install")

    log "Running jquery:install"
    generate("jquery:install")
    log <<-DOCS

    Congratulations #{app_name.humanize} is generated with :
      * factory girl
      * rspec
      * haml
      * jquery
      * 960.gs
      * thin

    Now simply go in your app
    % cd #{app_name}
    DOCS
  else
    log <<-DOCS

    Congratulations #{app_name.humanize} is generated but you need to run :
    % cd #{app_name}
    % rails g rspec:install
    % rails g jquery:install
    DOCS
  end
end

run "rm ../basic.rb"
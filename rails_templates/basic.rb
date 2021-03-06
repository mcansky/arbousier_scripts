# rails app template available at https://github.com/mcansky/arbousier_scripts/blob/master/rails_templates/basic.rb
# based on https://github.com/leshill/rails3-app/blob/master/app.rb
#
# create a basic app with rspec, factory girl, haml, some good gems and basic layout

## first the gems
# shiny markup stuff
gem "haml-rails", ">= 0.3.4"
# wooot vars in css
gem 'hassle', :git => 'git://github.com/koppen/hassle.git'
# replacement for prototype.js
gem "jquery-rails"
# http server
gem "unicorn"
# mostly for heroku
gem "pg", :group => [:production]
# good stuff
gem "rails_config"
# doc goodness
gem "yard"
# test goodness too
gem 'spork', '~> 0.9.0.rc', :group => :test
gem "watchr", :group => :test
gem "shoulda", "2.11.3", :group => :test
gem "factory_girl_rails", ">= 1.0.0", :group => :test
gem "rspec-rails", ">= 2.2.1", :group => [:development, :test]
gem "factory_girl", "1.3.3", :group => [:test]
devise = false
if yes?("Would you like to install Devise?")
  gem("devise")
  devise = true
  # auth stuff
  gem "cancan"
end


#create rspec.rb in the config/initializers directory to use rspec as the default test framework
#initializer 'rspec.rb', <<-EOF
#  Rails.application.config.generators.test_framework :rspec, :fixture => true, :views => false
#  Rails.application.config.fixture_replacement :factory_girl, :dir => "spec/factories"
#EOF

# getting 960.gs css files
nsmith_960_gs = "https://github.com/nathansmith/960-Grid-System/raw/master/code/css"
get "#{nsmith_960_gs}/960.css", "public/stylesheets/960.css"
get "#{nsmith_960_gs}/reset.css", "public/stylesheets/reset.css"
get "#{nsmith_960_gs}/text.css", "public/stylesheets/text.css"
# get the base sass file
github_home = "https://github.com/mcansky/arbousier_scripts/raw/master"
get "#{github_home}/sass/style.sass", "public/stylesheets/sass/style.sass"
# get rake tasks
get "#{github_home}/rake_tasks/undies.rb", "lib/tasks/undies.rake"

# get the watchr config (undies contains the watchr and spork tasks)
get "#{github_home}/watchr/watchr.rb", "config/watchr.rb"

# taking care of the layout
log "Generating layout"
layout = <<-LAYOUT
!!!
%html
%head
%title #{app_name.humanize}
%link{:href => "http://fonts.googleapis.com/css?family=OFL+Sorts+Mill+Goudy+TT", :rel => "stylesheet", :type => "text/css"}
%link{:href => "http://fonts.googleapis.com/css?family=Molengo", :rel => "stylesheet", :type => "text/css"}
%link{:href => "http://fonts.googleapis.com/css?family=Cuprum", :rel => "stylesheet", :type => "text/css"}
= stylesheet_link_tag "reset.css"
= stylesheet_link_tag "text.css"
= stylesheet_link_tag "960.css"
= stylesheet_link_tag "style"
= javascript_include_tag "jquery.js", "rails.js", "application.js"
= csrf_meta_tag
%body
%div#banner
  %div.container_16{:id => "banner_grid"}
    %div.grid_16
      %h1 #{app_name.humanize}
%div.container_16{:id => "main"}
  %div.grid_16
    %p.notice= notice
    %p.alert= alert
  %div.clear
  = yield
%div.clear
%div#footer
  %div.container_16{:id => "footer_grid"}
    %div.grid_16.footer
      #{app_name.humanize}
      = link_to "Arbousier.info", "http://www.arbousier.info"
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

if yes?("Do you want to run bundle install now ?")
  log "Running bundle install"
  run "bundle install --path bundler --without production"
  
  if devise
    generate("devise:install")
    model_name = ask("What would you like the user model to be called? [user]")
    model_name = "user" if model_name.blank?
    generate("devise", model_name)
  end

  log "Running rails_config:install"
  generate("rails_config:install")

  log "Running rspec:install"
  generate("rspec:install")

  log "Running jquery:install"
  generate("jquery:install")

  log "Bootstrapping Spork"
  run("bundle exec spork --bootstrap")
  remove_file ".rspec"
  dot_rspec = <<-DRSPEC
  --color --drb
  DRSPEC
  create_file ".rspec", dot_rspec

  # get the spec helper
  get "#{github_home}/watchr/spec_helper.rb", "spec/spec_helper.rb"

  log <<-DOCS

  Congratulations #{app_name.humanize} is generated with :
    * factory girl
    * rspec
    * haml
    * jquery
    * 960.gs
    * thin
    * watchr & spork

  Now simply go in your app
  % cd #{app_name}
  DOCS
else
  remove_file ".rspec"
  dot_rspec = <<-DRSPEC
  --color --drb
  DRSPEC
  create_file ".rspec", dot_rspec

  log <<-DOCS

  Congratulations #{app_name.humanize} is generated but you need to run :
  % cd #{app_name}
  % rails g devise:install
  % rails g devise your_model
  % rails g rails_config:install
  % rails g rspec:install
  % rails g jquery:install
  % bundle exec spork --bootstrap
  % mate spec/spec_helper.rb
  You need to remove or comment the line using Devise helper
  DOCS
end

run("rm ../basic.rb")

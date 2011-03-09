ENV["WATCHR"] = "1"
system 'clear'

def growl(message)
  growlnotify = `which growlnotify`.chomp
  title = "Watchr Test Results"
  passed = message.include?('0 failures')
  image = passed ? "~/.watchr_images/passed_3.png" : "~/.watchr_images/failed_3.png"
  severity = passed ? "-1" : "1"
  options = "-w -n Watchr --image '#{File.expand_path(image)}'"
  options << " -m '#{message}' '#{title}' -p #{severity}"
  system %(#{growlnotify} #{options} &)
end

def run(cmd)
  puts(cmd)
  `#{cmd}`
end

def run_test_file(file)
  system('clear')
  result = run(%Q(ruby -I"lib:test" -rubygems #{file}))
  growl result.split("\n").last rescue nil
  puts result
end

def run_all_tests
  system('clear')
  result = run "rake spec"
  growl result.split("\n").last rescue nil
  puts result
end

def run_all_features
  system('clear')
  run "rake spec"
end

def related_test_files(path)
  Dir['test/**/*.rb'].select { |file| file =~ /#{File.basename(path).split(".").first}_test.rb/ }
end

def run_suite
  run_all_tests
  run_all_features
end

def run_spec(file)
  unless File.exist?(file)
    growl "#{file} does not exist"
    return
  end

  result = run (%Q(bundle exec rspec #{file}))
  growl result.split("\n").last rescue nil
  puts result
end

watch("spec/.*/*_spec\.rb") { |match| run_spec match[0] }
watch("app/(.*/.*)\.rb") { |match| run_spec %{spec/#{match[1]}_spec.rb} }
#watch('test/test_helper\.rb') { run_all_tests }
#watch('test/.*_test\.rb') { |m| run_test_file(m[0]) }
#watch('.*\.rb') { |m| related_test_files(m[0]).map {|tf| run_test_file(tf) } }
#watch('features/.*/.*\.feature') { run_all_features }

# Ctrl-\
Signal.trap 'QUIT' do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

@interrupted = false

# Ctrl-C
Signal.trap 'INT' do
  if @interrupted then
    @wants_to_quit = true
    abort("\n")
  else
    puts "Interrupt a second time to quit"
    @interrupted = true
    Kernel.sleep 1.5
    # raise Interrupt, nil # let the run loop catch it
    run_suite
  end
end

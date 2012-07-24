require 'guard'
require 'guard/guard'

module ::Guard
  class LiveBehaviors < ::Guard::Guard
    def run_on_change(paths)
      puts "running"
      paths.each do |path|
        begin
          behavior = File.basename(path, ".rb")

          cmd = "reload_behavior(:#{behavior});\nexit\n"
          open("|pry-remote",'w') do |pipe|
            pipe.puts cmd
          end
        rescue Exception => ex
          puts "could not reload #{behavior} error: #{ex.message}"
        end
      end
      true
    end
  end
end

guard('live-behaviors') do
  watch(%r{^src/behaviors/.+\.rb$})
end


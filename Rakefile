require 'yaml'
require 'erb'
require 'pathname'

NGINX_ROOT = Pathname.new(__FILE__).dirname.realpath

$LOAD_PATH << NGINX_ROOT.to_s
require 'lib/nginx'

task :default => :force_reload

desc "Generate nginx configuration file"
task :config do
  Nginx.configure
  puts "Generated configuration file."
end

desc "Configure and start nginx"
task :start do
  Nginx.start
end

desc "Shut down nginx"
task :stop do
  Nginx.stop
end

desc "Reconfigure and reload nginx (default)"
task :reload do
  Nginx.reload(false)
end

task :force_reload do
  Nginx.reload(true)
end

desc "Shut down, reconfigure, and restart nginx"
task :restart => [:stop, :start]

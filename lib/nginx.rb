require 'lib/configurator'

CONFIG_FILE = NGINX_ROOT + 'conf/config.yml'
CONFIG_DIST = NGINX_ROOT + 'conf/config.yml.dist'
NGINX_ERB   = NGINX_ROOT + 'conf/nginx.conf.erb'
NGINX_CONF  = NGINX_ROOT + 'conf/nginx.conf'

NGINX_PID = NGINX_ROOT + 'run/nginx.pid'

$stdout.sync = true

class Nginx; class << self
  def start
    if running?
      puts 'Already running.'
    else
      configure
      print 'Starting nginx: '

      run_nginx

      sleep(0.2)
      until running?
        print '.'
        sleep(0.3)
      end
      puts "ready (#{pid})."
    end
  end

  def stop
    if running?
      print "Stopping nginx (#{pid}): "
      signal('TERM')
      sleep(0.2)
      while running?
        print '.'
        sleep(0.3)
      end
      puts 'done.'
    else
      puts 'Not running.'
    end
  end

  def reload(force)
    if running?
      configure
      puts "Sending reload signal to nginx (#{pid})."
      signal('HUP')
    elsif force
      start
    else
      puts 'Not running.'
    end
  end

  def configure
    unless File.exist?(CONFIG_FILE)
      FileUtils.copy(CONFIG_DIST, CONFIG_FILE)
      puts "Configuration file #{CONFIG_FILE} not found."
      puts "A new file has been generated.  Please edit it and try again."
      exit(1)
    end
  
    config = Configurator.new(CONFIG_FILE).render(NGINX_ERB)
    NGINX_CONF.open('w') { |fh| fh.puts config }
    
    pid = run_nginx('-t')
    Process.wait(pid)
    
    unless $?.success?
      puts "Configuration is invalid."
      puts "Please check #{NGINX_ERB} for errors."
      exit(1)
    end
  end

  private

  def signal(sig)
    Process.kill(sig, pid)
  end

  def pid
    runnning? if @pid.nil?
    @pid
  end

  def running?
    file_pid = begin
      NGINX_PID.read.to_i
    rescue Errno::ENOENT
      return # no pidfile
    end
  
    process_list(file_pid) do |pid, command|
      if pid == file_pid && command.start_with?('nginx: master process ')
        @pid = pid
        return true
      end
    end

    return false
  end

  def run_nginx(*args)
    fork do
      [$stdin, $stdout, $stderr].each {|fh| fh.reopen('/dev/null')}
      exec('nginx', '-c', NGINX_CONF.to_s, *args)
      raise 'exec failed'
    end
  end

  def run_command(*command)
    IO.popen('-') do |fh|
      if fh.nil? # child
        exec(*command.map(&:to_s))
        Kernel.exit!(1)
      else # server
        yield(fh)
      end
    end
  end

  def process_list(pid = nil)
    extra = pid ? ['-p', pid] : []
    run_command('ps', 'x', '-o', 'pid,command', *extra) do |fh|
      fh.each_line do |line|
        pid = line.slice!(0, 5).strip.to_i
        command = line.chomp.strip
        yield [pid, command] unless pid == 0 && command == 'COMMAND'
      end
    end
  end
  
end; end
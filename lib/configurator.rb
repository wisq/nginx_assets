class Configurator
  class Instance
    attr_reader :name, :listen_on, :proxy_to, :assets_path

    def initialize(key, params)
      @name        = key
      @listen_on   = params[:listen_on]
      @proxy_to    = params[:proxy_to]
      @assets_path = Pathname.new(params[:assets_path]).expand_path.realpath
    end
    
    def proxy?
      !@proxy_to.nil?
    end
  end

  def initialize(file)
    @instances = YAML.load_file(file).map { |key, params| Instance.new(key, params) }
  end
  
  def render(file)
    ERB.new(File.read(file), 0).result(binding)
  end
end


module EtherpadLite
  # Returns an EtherpadLite::Instance object.
  # 
  # ether1 = EtherpadLite.connect('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
  # 
  # ether2 = EtherpadLite.connect(:local, File.new('/file/path/to/APIKEY.txt'))
  def self.connect(host_or_alias, api_key_or_file)
    Instance.new(host_or_alias, api_key_or_file)
  end

  # EtherpadLite::Instance provides a high-level interface to an Etherpad Lite system.
  class Instance
    include Padded
    # Aliases to common Etherpad Lite hosts
    HOST_ALIASES = {:local => 'http://localhost:9001',
                    :localhost => 'http://localhost:9001'}

    # The API URI
    API_ROOT = 'api'

    # Stores the EtherpadLite::Client object used to power this Instance
    attr_reader :client

    # Instantiate a new Etherpad Lite Instance. The url should include the protocol (i.e. http or https).
    # 
    # ether1 = EtherpadLite.connect('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
    # 
    # ether2 = EtherpadLite.connect(:local, File.new('/file/path/to/APIKEY.txt'))
    def initialize(host_or_alias, api_key_or_file)
      # Parse the host
      host = if host_or_alias.is_a? Symbol
        raise ArgumentError, %Q|Unknown host alias "#{host_or_alias}"| unless HOST_ALIASES.has_key? host_or_alias
        HOST_ALIASES[host_or_alias]
      else
        host_or_alias
      end

      # Parse the api key
      if api_key_or_file.is_a? File
        api_key = api_key_or_file.read
        api_key_or_file.close
      else
        api_key = api_key_or_file
      end

      @client = Client.new(api_key, host + "/#{API_ROOT}")
    end

    # Returns, creating if necessary, a Group mapped to your foreign system's group
    def group(mapper)
      create_group(:mapper => mapper)
    end

    # Returns a Group with the given id (it is presumed to already exist).
    def get_group(id)
      Group.new self, id
    end

    # Creates a new Group. Optionally, you may pass the :mapper option your third party system's group id.
    # This will allow you to find your Group again later using the same identifier as your foreign system.
    # 
    # Options:
    # 
    #  mapper => your foreign group id
    def create_group(options={})
      Group.create self, options
    end

    # Returns, creating if necessary, a Author mapped to your foreign system's author
    # 
    # Options:
    # 
    #  name => the Author's name
    def author(mapper, options={})
      options[:mapper] = mapper
      create_author options
    end

    # Returns an Author with the given id (it is presumed to already exist).
    def get_author(id)
      Author.new self, id
    end

    # Creates a new Author. Optionally, you may pass the :mapper option your third party system's author id.
    # This will allow you to find the Author again later using the same identifier as your foreign system.
    # 
    # Options:
    # 
    #  mapper => your foreign author id
    # 
    #  name => the Author's name
    def create_author(options={})
      Author.create self, options
    end

    # Returns a Session (presumed to already exist).
    def get_session(session_id)
      Session.new self, session_id
    end

    # Returns itself
    def instance; self; end
  end
end

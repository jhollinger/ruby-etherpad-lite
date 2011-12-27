module EtherpadLite
  # Returns an EtherpadLite::Instance object.
  # 
  # ether1 = EtherpadLite.connect('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
  # 
  # ether2 = EtherpadLite.connect(:local, File.new('/path/to/APIKEY.txt'))
  # 
  # ether3 = EtherpadLite::Client.new(9001, File.new('/path/to/APIKEY.txt'))
  def self.connect(host_or_alias, api_key_or_file)
    Instance.new(host_or_alias, api_key_or_file)
  end

  # EtherpadLite::Instance provides a high-level interface to an Etherpad Lite system.
  class Instance
    include Padded
    # Stores the EtherpadLite::Client object used to power this Instance
    attr_reader :client

    # Instantiate a new Etherpad Lite Instance. The url should include the protocol (i.e. http or https).
    # 
    # ether1 = EtherpadLite.connect('https://etherpad.yoursite.com[https://etherpad.yoursite.com]', 'your api key')
    # 
    # ether2 = EtherpadLite.connect(:local, File.new('/path/to/APIKEY.txt'))
    # 
    # ether3 = EtherpadLite::Client.new(9001, File.new('/path/to/APIKEY.txt'))
    def initialize(host_or_alias, api_key_or_file)
      @client = Client.new(host_or_alias, api_key_or_file)
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

module EtherpadLite
  # Returns an EtherpadLite::Instance object.
  # 
  #  ether = EtherpadLite.client('https://etherpad.yoursite.com', 'your api key', '1.1')
  # 
  #  ether = EtherpadLite.client(9001, 'your api key', '1.1') # Alias to http://localhost:9001
  def self.connect(url_or_port, api_key_or_file, api_version=nil)
    Instance.new(url_or_port, api_key_or_file, api_version)
  end

  # A high-level interface to EtherpadLite::Client.
  class Instance
    include Padded
    # Stores the EtherpadLite::Client object used to power this Instance
    attr_reader :client

    # Instantiate a new Etherpad Lite Instance. You may pass a full url or just a port number. The api key may be a string
    # or a File object.
    def initialize(url_or_port, api_key_or_file, api_version=nil)
      @client = Client.new(url_or_port, api_key_or_file, api_version)
    end

    # Returns an array of all pad IDs
    def pad_ids
      @client.listAllPads[:padIDs]
    end

    # Returns an array of all Pad objects
    def pads
      pad_ids.map { |id| Pad.new self, id }
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
    # mapper => your foreign group id
    def create_group(options={})
      Group.create self, options
    end

    # Returns an array of all group IDs
    def group_ids
      @client.listAllGroups[:groupIDs]
    end

    # Returns an array of all Group objects
    def groups
      group_ids.map { |id| Group.new self, id }
    end

    # Returns, creating if necessary, a Author mapped to your foreign system's author
    # 
    # Options:
    # 
    # name => the Author's name
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
    # mapper => your foreign author id
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

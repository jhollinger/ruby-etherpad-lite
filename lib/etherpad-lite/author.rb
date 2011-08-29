module EtherpadLite
  # An Author of Pad content
  class Author
    METHOD_CREATE = 'createAuthor'
    METHOD_MAP = 'createAuthorIfNotExistsFor'
    METHOD_SESSIONS = 'listSessionsOfAuthor'

    attr_reader :id, :instance, :name, :mapper

    # Creates a new Author. Optionally, you may pass the :mapper option your third party system's author id.
    # This will allow you to find the Author again later using the same identifier as your foreign system.
    # If you pass the mapper option, the method behaves like "create author for <mapper> if it doesn't already exist".
    # 
    # Options:
    # 
    #  mapper => uid of Author from another system
    # 
    #  name => Author's name
    def self.create(instance, options={})
      id = options[:mapper] \
        ? instance.call(METHOD_MAP, :groupMapper => options[:mapper])[:authorID] \
        : instance.call(METHOD_CREATE)[:authorID]
      new instance, id, options
    end

    # Instantiates an Author object (presumed it already exists)
    # 
    # Options:
    # 
    #  mapper => the foreign author id it's mapped to
    # 
    #  name => the Author's name
    def initialize(instance, id, options={})
      @instance = instance
      @id = id
      @mapper = options[:mapper]
      @name = options[:name]
    end

    # Create a new session for group that will last length_in_minutes.
    def create_session(group, length_in_min)
      Session.create(@instance, group.id, @id, length_in_min)
    end

    # Returns all session ids from this Author
    def session_ids
      s = @instance.call(METHOD_SESSIONS, :authorID => @id) || {}
      s.keys
    end

    # Returns all sessions from this Author
    def sessions
      s = @instance.call(METHOD_SESSIONS, :authorID => @id) || []
      s.map { |id,info| Session.new(@instance, id, info) }
    end
  end
end

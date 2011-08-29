module EtherpadLite
  # An Etherpad Lite Session between a Group and an Author
  class Session
    METHOD_CREATE = 'createSession'
    METHOD_DELETE = 'deleteSession'
    METHOD_INFO = 'getSessionInfo'

    attr_reader :id, :instance

    # Creates a new Session between a Group and an Author. The session will expire after length_in_min.
    def self.create(instance, group_id, author_id, length_in_min)
      valid_until = Time.now.to_i + length_in_min * 60
      id = instance.call(METHOD_CREATE, :groupID => group_id, :authorID => author_id, :validUntil => valid_until)[:sessionID]
      new instance, id
    end

    # Instantiates a Session object (presumed to already exist)
    def initialize(instance, id, info=nil)
      @instance = instance
      @id = id
      @info = info
    end

    # Returns the Session's group id
    def group_id
      get_info[:groupID]
    end

    # Returns the Session's group
    def group
      @group ||= Group.new @instance, group_id
    end

    # Returns the Session's author id
    def author_id
      get_info[:authorID]
    end

    # Returns the Session's author
    def author
      @author ||= Author.new @instance, author_id
    end

    # Returns the Session's expiration date is a Unix timestamp in seconds
    def valid_until
      get_info[:validUntil]
    end

    def valid?
      valid_until < Time.now.to_i
    end

    def expired?
      not valid?
    end

    # Deletes the Session
    def delete
      @instance.call(METHOD_DELETE, :sessionID => @id)
    end

    private

    # Request and cache session info from the server
    def get_info
      @info ||= @instance.call(METHOD_INFO, :sessionID => @id)
    end
  end
end

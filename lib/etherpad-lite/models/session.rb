module EtherpadLite
  # An Etherpad Lite Session between a Group and an Author. See those classes for examples of how to create a session.
  # 
  # Sessions are useful for embedding an Etherpad Lite Pad into a external application. For public pads, sessions 
  # are not necessary. However Group pads require a Session to access to the pad via the Web UI.
  # 
  # Generally, you will create the session server side, then pass its id to the embedded pad using a cookie. See the README
  # for an example in a Rails app.
  # 
  class Session
    # The EtherpadLite::Instance object
    attr_reader :instance
    # The session id
    attr_reader :id

    # Creates a new Session between a Group and an Author. The session will expire after length_in_min.
    def self.create(instance, group_id, author_id, length_in_min)
      valid_until = Time.now.to_i + length_in_min * 60
      result = instance.client.createSession(groupID: group_id, authorID: author_id, validUntil: valid_until)
      new instance, result[:sessionID]
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

    # Returns true if the session is not expired
    def valid?
      valid_until > Time.now.to_i
    end

    # Returns true if the session is expired
    def expired?
      not valid?
    end

    # Deletes the Session
    def delete
      @instance.client.deleteSession(sessionID: @id)
    end

    private

    # Request and cache session info from the server
    def get_info
      @info ||= @instance.client.getSessionInfo(sessionID: @id)
    end
  end
end

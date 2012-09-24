module EtherpadLite
  # An Author of Pad content
  # 
  # Authors are used to create a Session in a Group. Authors may be created with
  # a name and a mapper. A mapper is usually an identifier stored in your third-party system,
  # like a foreign key or username.
  #
  # Author Examples:
  # 
  #  @ether = EtherpadLite.connect(9001, 'api key')
  # 
  #  # Create a new author with both a name and a mapper
  #  author1 = @ether.create_author(:name => 'Theodor Seuss Geisel', :mapper => 'author_1')
  # 
  #  # Load (and create, if necessary) a mapped author with a name
  #  author2 = @ether.author('author_2', :name => 'Richard Bachman')
  #
  #  # Load (and create, if necessary) a author by mapper
  #  author3 = @ether.author('author_3')
  # 
  #  # Load author1 by id
  #  author4 = @ether.get_author(author1.id)
  # 
  # Session examples:
  # 
  #  # Create two hour-long session for author 1 in two different groups
  #  group1 = @ether.group('my awesome group')
  #  group2 = @ether.group('my other awesome group')
  # 
  #  session1 = author1.create_session(group1, 60)
  #  session2 = author1.create_session(group2, 60)
  # 
  # Attribute examples:
  # 
  #  author1.name #> "Theodor Seuss Geisel"
  # 
  #  author1.mapper #> "author_1"
  # 
  #  author2.sessions #> [#<EtherpadLite::Session>, #<EtherpadLite::Session>]
  # 
  #  author2.session_ids.include? session1.id #> true
  # 
  class Author
    # The EtherpadLite::Instance object
    attr_reader :instance
    # The author's id
    attr_reader :id
    # The author's foreign mapper (if any)
    attr_reader :mapper

    # Creates a new Author. Optionally, you may pass the :mapper option your third party system's author id.
    # This will allow you to find the Author again later using the same identifier as your foreign system.
    # If you pass the mapper option, the method behaves like "create author for <mapper> if it doesn't already exist".
    # 
    # Options:
    # 
    # mapper => uid of Author from another system
    # 
    # name => Author's name
    def self.create(instance, options={})
      result = options[:mapper] \
        ? instance.client.createAuthorIfNotExistsFor(authorMapper: options[:mapper], name: options[:name]) \
        : instance.client.createAuthor(options)
      new instance, result[:authorID], options
    end

    # Instantiates an Author object (presumed it already exists)
    # 
    # Options:
    # 
    # mapper => the foreign author id it's mapped to
    # 
    # name => the Author's name
    def initialize(instance, id, options={})
      @instance = instance
      @id = id
      @mapper = options[:mapper]
    end

    # Returns the author's name
    def name
      @name ||= @instance.client.getAuthorName(authorID: @id)
    end

    # Returns an array of pad ids that this author has edited
    def pad_ids
      @instance.client.listPadsOfAuthor(authorID: @id)[:padIDs] || []
    end

    # Returns an array of Pads that this author has edited
    def pads
      pad_ids.map { |id| Pad.new(@instance, id) }
    end

    # Create a new session for group that will last length_in_minutes.
    def create_session(group, length_in_min)
      Session.create(@instance, group.id, @id, length_in_min)
    end

    # Returns all session ids from this Author
    def session_ids
      s = @instance.client.listSessionsOfAuthor(authorID: @id) || {}
      s.keys
    end

    # Returns all sessions from this Author
    def sessions
      s = @instance.client.listSessionsOfAuthor(authorID: @id) || {}
      s.map { |id,info| Session.new(@instance, id, info) }
    end
  end
end

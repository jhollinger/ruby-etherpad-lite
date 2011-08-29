module EtherpadLite
  # An Author of Pad content
  class Author
    METHOD_CREATE = 'createAuthor'
    METHOD_MAP = 'createAuthorIfNotExistsFor'

    attr_reader :id, :instance, :name, :mapper

    # Creates a new Author. Optionally, you may pass the :mapper option your third party system's author id.
    # This will allow you to find the Author again later using the same identifier as your foreign system.
    # If you pass the mapper option, the method behaves like "create author for <mapper> if it doesn't already exist".
    # 
    # 
    # Options:
    #  mapper => uid of Author from another system
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
    #  mapper => the foreign author id it's mapped to
    #  name => the Author's name
    def initialize(instance, id, options={})
      @instance = instance
      @id = id
      @mapper = options[:mapper]
      @name = options[:name]
    end
  end
end

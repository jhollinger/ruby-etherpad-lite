module EtherpadLite
  # An Etherpad Lite Pad
  class Pad
    METHOD_CREATE = 'createPad'
    METHOD_CREATE_IN_GROUP = 'createGroupPad'
    METHOD_READ = 'getText'
    METHOD_WRITE = 'setText'
    METHOD_DELETE = 'deletePad'
    METHOD_NUM_REVISIONS = 'getRevisionsCount'
    METHOD_READ_ONLY_ID = 'getReadOnlyID'
    METHOD_GET_PUBLIC = 'getPublicStatus'
    METHOD_SET_PUBLIC = 'setPublicStatus'
    METHOD_PASSWORD_PROTECTED = 'isPasswordProtected'
    METHOD_SET_PASSWORD = 'setPassword'

    attr_reader :id, :instance, :rev

    # Creates and returns a new Pad.
    # 
    # Options:
    # 
    #  text => 'initial Pad text'
    # 
    #  groupID => group id of Group new Pad should belong to
    def self.create(instance, id, options={})
      if options[:groupID]
        method = METHOD_CREATE_IN_GROUP
        options[:padName] = degroupify_pad_id(id)
        group = Group.new instance, options[:groupID]
      else
        method = METHOD_CREATE
        options[:padID] = id
        group = nil
      end
      instance.call(method, options)
      new instance, id, :group => group
    end

    # Remove the group id portion of a Group Pad's id
    def self.degroupify_pad_id(pad_id)
      pad_id.to_s.sub(Group::GROUP_ID_REGEX, '').sub(/^\$/, '')
    end

    # Instantiate a Pad. It is presumed to already exist (via Pad.create).
    # 
    # Options:
    # 
    #  group
    # 
    #  rev
    def initialize(instance, id, options={})
      @instance = instance
      @id = id.to_s
      @group = options[:group]
      @rev = options[:rev]
    end

    # Returns the name of the Pad. For a normal pad, this is the same as it's id. But for a Group Pad,
    # this strips away the group id part of the pad id.
    def name
      @name ||= self.class.degroupify_pad_id(@id)
    end

    # Returns the group_id of this Pad, if any.
    def group_id
      unless @group_id
        match = Group::GROUP_ID_REGEX.match(@id)
        @group_id = match ? match[0] : nil
      end
      @group_id
    end

    # Returns this Pad's group, if any
    def group
      return nil unless group_id
      @group ||= Group.new(@instance, group_id)
    end

    # Returns the Pad's text. Unless you specified a :rev when instantiating the Pad, or specify one here, this will return the latest revision.
    # 
    # Options:
    # 
    #  rev => revision_number
    def text(options={})
      options[:padID] = @id
      options[:rev] = @rev unless @rev.nil? or options.has_key? :rev
      @instance.call(METHOD_READ, options)[:text]
    end

    # Writes txt to the Pad. There is no 'save' method; it is written immediately.
    def text=(txt)
      @instance.call(METHOD_WRITE, :padID => @id, :text => txt)
    end

    # Returns a Range of all this Pad's revision numbers
    def revision_numbers
      max = @instance.call(METHOD_NUM_REVISIONS, :padID => @id)[:revisions]
      (0..max).to_a
    end

    # Returns an array of Pad objects, each with an increasing revision of the text.
    def revisions
      revision_numbers.map { |n| Pad.new(@instance, @id, :rev => n) }
    end

    # Returns the Pad's read-only id. This is cached.
    def read_only_id
      @read_only_id ||= @instance.call(METHOD_READ_ONLY_ID, :padID => @id)[:readOnlyID]
    end

    # Returns true if this is a public Pad (opposite of private).
    # This only applies to Pads belonging to a Group.
    def public?
      @instance.call(METHOD_GET_PUBLIC, :padID => @id)[:publicStatus]
    end

    # Set the pad's public status to true or false (opposite of private=)
    # This only applies to Pads belonging to a Group.
    def public=(status)
      @instance.call(METHOD_SET_PUBLIC, :padID => @id, :publicStatus => status)
    end

    # Returns true if this is a private Pad (opposite of public)
    # This only applies to Pads belonging to a Group.
    def private?
      not public?
    end

    # Set the pad's private status to true or false (opposite of public=)
    # This only applies to Pads belonging to a Group.
    def private=(status)
      public = !status
    end

    # Returns true if this Pad has a password, false if not.
    # This only applies to Pads belonging to a Group.
    def password?
      @instance.call(METHOD_PASSWORD_PROTECTED, :padID => @id)[:isPasswordProtected]
    end

    # Sets the Pad's password.
    # This only applies to Pads belonging to a Group.
    def password=(new_password)
      @instance.call(METHOD_SET_PASSWORD, :padID => @id, :password => new_password)
    end

    # Deletes the Pad
    def delete
      @instance.call(METHOD_DELETE, :padID => @id)
    end
  end
end

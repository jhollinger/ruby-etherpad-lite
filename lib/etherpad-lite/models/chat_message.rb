module EtherpadLite
  # An Etherpad Lite Chat message
  class ChatMessage
    # The EtherpadLite::Instance object
    attr_reader :instance
    # The pad id
    attr_reader :pad_id
    # The message text
    attr_reader :text
    # User/Author id
    attr_reader :user_id
    # Unix timestamp
    attr_reader :timestamp
    # User/Author name
    attr_reader :user_name

    # Instantiate a ChatMessage
    def initialize(instance, attrs)
      @instance = instance
      @pad_id = attrs[:padID]
      @text = attrs[:text]
      @user_id = attrs[:userId]
      @timestamp = attrs[:time] / 1000 if attrs[:time]
      @user_name = attrs[:userName]
    end

    # Returns this message's Pad
    def pad
      if pad_id
        @pad ||= Pad.new(instance, pad_id)
      else
        nil
      end
    end

    # Returns the Author that sent this message
    def author
      if user_id
        @author ||= Author.new(instance, user_id)
      else
        nil
      end
    end

    alias_method :user, :author

    # Time object
    def time
      if timestamp
        @time ||= Time.at(timestamp)
      else
        nil
      end
    end

    # Returns the message text
    def to_s
      text.to_s
    end
  end
end

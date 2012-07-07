module EtherpadLite
  MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION = 0, 1, 0, nil # :nodoc:
  # The client version
  VERSION = [MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION].compact.join '.'
end

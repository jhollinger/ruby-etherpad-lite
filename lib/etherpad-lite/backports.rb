require 'uri'

# Add Ruby 1.9's URI.encode_www_form to Ruby 1.8
# thanks to http://apidock.com/ruby/Net/HTTPHeader/set_form_data#1105-Backport-from-1-9
unless URI.respond_to? :encode_www_form
  module URI
    def self.encode_www_form(enum)
      enum.map do |k,v|
        if v.nil?
          k
        elsif v.respond_to? :to_ary
          v.to_ary.map do |w|
            str = k.to_s.dup
            unless w.nil?
              str << '=' << w
            end
          end.join('&')
        else
          str = k.to_s.dup
          str << '=' << v
        end
      end.join('&')
    end
  end
end

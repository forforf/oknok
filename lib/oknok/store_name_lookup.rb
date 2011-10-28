require 'open-uri'
require 'json'


module HashUtil
  def find_deep(*keys)
    find_deep_iter(self, keys)
  end

  def find_deep_iter(h, keys)
    return h if keys.empty?
    if h.respond_to? :keys
      find_deep_iter(h[keys.shift], keys)
    else #h isn't hash-like
      keys.empty? ? h : nil
    end
  end
end

module StoreNameLookup
  def self.config_reader(config_data)
    engine = config_data['host_lookup_engine']
    mod_str = engine || :Default
    begin
      mod_name = self.const_get(mod_str.to_sym)
    #A more informative error message
    rescue NameError => e
      if e.message =~ /uninitialized constant StoreNameLookup::.*/
        raise NameError, 
          "Lookup Engine module ( #{mod_str}) not found, does it exist?" 
      else
        raise e
      end
    end
     
    mod_exec = mod_name.config_reader(config_data)
  end 
end

# Lookup Modules

# Default Lookup just returns the host
# In other words, no lookup is performed, host is used as is
module StoreNameLookup::Default
  def self.config_reader(config_data)
    host = config_data["host"]
  end
end


# Lookup engine in config data is the url of a web service
# That returns JSON that includes the IP address of the
# desired host.  
# See the post on accessing EC2 instances with Putty
# on http://forforf.github.com/code_thoughts/ for an
# example service.
# Note that the config data identifies the specific module
module StoreNameLookup::WebService
  def self.config_reader(config_data)
    lookup_host = config_data["host"]
    self.find_host(lookup_host)
  end

  def self.find_host(name, *args)
    finder_url = name #LookupBase + name
    host_data_json =  self.get_data(finder_url)
    host = self.parse(host_data_json, "ip")
  end

  def self.get_data(url)
    begin
      open(url){|f| f.read}
    rescue OpenURI::HTTPError, e
      puts "Issue with #{url.inspect}"
      raise e
    end
  end

  def self.parse(raw_json_data, *keys)
    raw_data = JSON.parse raw_json_data
    raw_data.extend HashUtil
    host = raw_data.find_deep(*keys)
  end
end


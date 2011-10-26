require 'uri'
require 'couchrest'
require 'mysql'
require 'dbi'
require 'json'
require 'fileutils'
require 'aws_sdb'  #published as gem forforf-aws-sdb
require 'aws/s3'  #TODO: Create config for this model too

require_relative 'sens_data' #config file reader
require_relative 'store_access' #checks store accessibility
require_relative 'store_name_lookup' #nameserver like function

#Returns the persistent data stores based on config file
  
module Oknok

  class StoreBase
    include StoreAccess

    #TODO: Refactor @@store_types
    #  calling StoreName.store_type = 'store_name'
    #  updates the @@store_types and checks for duplicate
    #  'store_name's.  This would allow catching a duplicate
    #  At assignemnet time rather than run time
    class << self; attr_accessor :store_type; end
    self.store_type = nil
   
    @@config_file_location = nil 
    @@store_types = []
    
    def self.store_types
      @@store_types
    end
      
    def self.find_store_by_type(type)
      stores =  @@store_types.select{|candidate| candidate.store_type == type}
      #TODO: Need test case for duplicate types
      store = case stores.size
        when stores.size > 1
          raise IndexError,
            "More than one Store Class found for type: #{type}" 
        when 1
          store = stores.first
        when 0
          NullStore.store_type = type
          NullStore #no matching store found
      end
      return store
    end
    
    def self.inherited(child)
      @@store_types << child
    end

    def self.set_config_file_location(f)
      raise IOError, 
          "Unable to locate file: #{f.inspect}, does it exist?" \
         unless File.exist?(f)
      @@config_file_location = f
    end

    def self.get_config_file_location
      @@config_file_location
    end

    def self.read_config_data
      raise IOError,
        "Unable to find config file: #{@@config_file_location},\n was it moved?" \
        unless File.exist?(@@config_file_location)
      config_data =  Oknok::SensData.load(@@config_file_location)
    end

    def self.get_avail_stores
      config_data = read_config_data
      raise NameError,
        "Config file does not have list of available stores" \
        unless config_data.keys.include? 'avail_stores'
      avail_stores = config_data['avail_stores']
    end

    def self.make(store_name, oknok_name=nil)
      avail_stores = self.get_avail_stores
      raise NameError,
        "Store: #{store_name.inspect} was not found in the configuration file" \
        unless avail_stores.keys.include? store_name
      store_data = avail_stores[store_name]
      store_class = self.find_store_by_type(store_data['type'])
      store = store_class.new(store_name, oknok_name, store_data)
    end

    attr_accessor :store_name, :oknok_name, :host

    def initialize(store_name, oknok_name, store_data)
      @store_name = store_name
      @oknok_name = oknok_name
      @host = StoreNameLookup.config_reader(store_data)
    end

  end

  class NullStore < StoreBase
    #store_type set when finding type
  end

  class CouchDbStore < StoreBase
    self.store_type = 'couchdb'
  end

  class MysqlStore < StoreBase
    self.store_type = 'mysql'
  end

  class FileStore < StoreBase
    self.store_type = 'file'
    def initialize(store_name, oknok_name, file_data)
      super(store_name, oknok_name, file_data)
      p file_data
      p @host
      file_store_path = File.join(@host, store_name)
      begin
        native_resp = FileUtils.mkdir_p(file_store_path)
        #store_caps.add_permissions([:exists, :reach]) if native_resp == [ file_store_path]
      rescue Errno::EACCES
        #no permissions
      end
      p file_store_path
    end
  end
end
#p Tinkit::StoreBase.set_config_file_location(Tinkit::DatastoreConfig)


#file_store = Tinkit::StoreBase.make('tmp_files', :bar)
#p file_store

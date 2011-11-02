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

    #

    class << self; attr_accessor :all_classes, :store_type; end
    self.store_type = nil
    self.all_classes = []
    
    def status_stub
    end
    
    def connection_status(stat, *args)
      stat ||= :undefined
      @status_obj = case stat
        when :undefined
          Undefined.new
        when :not_found
          NotFound.new
        when :unavailable
          Unavailable.new
        when :access_denied
          AccessDenied.new
        else
          raise "Unable to determine connection status"
      end
    end
   
    #@@config_file_location = nil 
    
    #@@all_classes = []
    #@@store_instances = []
    
    #def self.store_types
    #  @@store_types
    #end

    #def self.get_my_instances
      #objs = []
      #ObjectSpace.each_object(self){|o| objs << o}
      #objs
    #  @@store_instances
    #end
    #TODO: Should reachability class methods be here or module?
    #def self.find_by_reachability(reachability)
    #  objs = self.get_my_instances
    #  ret_val = objs.select{|o| o.status == reachability}
    #end

    #def self.all_reachability
    #  objs = self.get_my_instances
    #  objs.inject({}) do |h, o|
    #     h[o.status] ? h[o.status] << o : h[o.status] = [o]
    #     h[o.status].uniq!
    #     h 
    #  end
    #end 
      
    #def self.find_store_by_type(type)
    #  stores =  @@store_types.select{|candidate| candidate.store_type == type}
    #  #TODO: Need test case for duplicate types
    #  store = case stores.size
    #    when stores.size > 1
    #      raise IndexError,
    #        "More than one Store Class found for type: #{type}" 
    #    when 1
    #      store = stores.first
    #    when 0
    #      NullStore.store_type = type
    #      NullStore #no matching store found
    #  end
    #  return store
    #end
    
    #keep 
    def self.inherited(child)
      self.all_classes << child unless self.all_classes.include? child
    end

    #def self.set_config_file_location(f)
    #  raise IOError, 
    #      "Unable to locate file: #{f.inspect}, does it exist?" \
    #     unless File.exist?(f)
    #  @@config_file_location = f
    #end

    #def self.get_config_file_location
    #  @@config_file_location
    #end

    #def self.read_config_data
    #  raise IOError,
    #    "Unable to find config file: #{@@config_file_location},\n was it moved?" \
    #    unless File.exist?(@@config_file_location)
    #  config_data =  Oknok::SensData.load(@@config_file_location)
    #end

    #def self.get_avail_stores
    #  config_data = read_config_data
    #  raise NameError,
    #    "Config file does not have list of available stores" \
    #    unless config_data.keys.include? 'avail_stores'
    #  avail_stores = config_data['avail_stores']
    #end

    #def self.make(store_name, oknok_name=nil)
    #  avail_stores = self.get_avail_stores
    #  raise NameError,
    #    "Store: #{store_name.inspect} was not found in the configuration file" \
    #    unless avail_stores.keys.include? store_name
    #  store_data = avail_stores[store_name]
    #  store_class = self.find_store_by_type(store_data['type'])
    #  store = store_class.new(store_name, oknok_name, store_data)
    #end

    attr_accessor :store_name, :oknok_name, :host
    attr_reader :store_data

    def initialize(store_name, store_data)
      #default status
      connection_status(:undefined)
      @store_name = store_name
      #@oknok_name = oknok_name
      @store_data = store_data
      @host = StoreNameLookup.config_reader(store_data)
      @user = store_data['user']
      #@@store_instances << self
      #self.undefined_reachability
    end

    def eql? other
      @store_data == other.store_data
    end
      
    def hash
      @store_data.hash
    end
  end

  class NullStore < StoreBase
    #store_type set when finding type
    def initiliaze
      @status = status_stub
    end
  end

  class CouchDbStore < StoreBase
    self.store_type = 'couchdb'
    def initialize(store_name, couch_data)
      super(store_name, couch_data)
      #host = StoreNameLookup.config_reader(couch_data)
      db_path = "/" + store_name 
      url = URI::HTTP.build :userinfo => @user, :host => @host, :path => db_path, :port => 5984
      begin
        @status = status_stub
        #@status = Reachable::NoAccess
        store = CouchRest.database! url.to_s
        resp_ex = JSON.parse(`curl -sX GET #{url.to_s}`)
        @status = status_stub
        @status = status_stub
      rescue
        #TODO: Refactor so that each step can be tested
        puts "WARNING: CouchDBStore #{store_name} not fully accessed"
      end  
    end

    #TODO: Move up? somewhere else?    
    #Mark Thomas: http://stackoverflow.com/questions/3561669/ruby-ping-for-1-9-1
    def up?(site)
      Net::HTTP.new(site).head('/').kind_of? Net::HTTPOK
    end

  end

  class MysqlStore < StoreBase
    self.store_type = 'mysql'

    attr_reader :mysql_connection

    def initialize(store_name, mysql_data)
      super(store_name, mysql_data)
      #init db is just for initial connection purposes
      #TODO: find an alternate db library that doesn't require pre-existing db
      init_db = mysql_data["init_db"] || store_name
      #host = StoreNameLookup.config_reader(mysql_data)
      dbi_host = "DBI:Mysql:#{init_db}:#{host}"
      user, pw = @user.split ":"
      begin
        store = DBI.connect dbi_host, user, pw
        row = store.select_one("SELECT VERSION()")
        @status = status_stub
        store.do "DROP TABLE IF EXISTS dummy"
        store.do "CREATE TABLE dummy (
                    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                    test_data CHAR(20) NOT NULL,
                    PRIMARY KEY (id))"
        rows = store.do "INSERT INTO dummy(test_data)
                           VALUES
                             ('Test1'), ('Test2')"
        @status = status_stub
        store.do "DROP TABLE IF EXISTS dummy"
     rescue DBI::DatabaseError => e
       raise e
       @status = status_stub
     ensure
       store.disconnect if store
     end
     @mysql_connection = [dbi_host, user, pw]
    end
  end

  class FileStore < StoreBase
    self.store_type = 'file'
    def initialize(store_name, file_data)
      super(store_name, file_data)
      @status = status_stub
      file_store_path = File.join(@host, store_name)
      begin
        native_resp = FileUtils.mkdir_p(file_store_path)
        @status = status_stub
      rescue Errno::EACCES
        @status = status_stub
      end
    end
  end

  class SdbS3Store < StoreBase
    self.store_type = 'sdb_s3'
  end

end
#p Tinkit::StoreBase.set_config_file_location(Tinkit::DatastoreConfig)


#file_store = Tinkit::StoreBase.make('tmp_files', :bar)
#p file_store

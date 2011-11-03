require 'uri'
require 'couchrest'
require 'mysql'
require 'dbi'
require 'json'
require 'fileutils'
require 'aws_sdb'  #published as gem forforf-aws-sdb
require 'aws/s3'  #TODO: Create config for this model too

require_relative 'store_access' #checks store accessibility
require_relative 'store_name_lookup' #nameserver like function

#Provides persistent stores classes
  
module Oknok

  class StoreBase
    include StoreAccess
    class << self; attr_accessor :all_classes, :store_type; end
    self.store_type = nil
    self.all_classes = []
        
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
        when :access
          Access.new
        else
          raise "Unable to determine connection status based on: #{stat.inspect}"
      end
    end

    def self.inherited(child)
      self.all_classes << child unless self.all_classes.include? child
    end

    attr_accessor :store_name, :oknok_name, :host
    attr_reader :store_data

    def initialize(store_name, store_data)
      #default status
      connection_status(:undefined)
      @store_name = store_name
      @store_data = store_data
      @host = StoreNameLookup.config_reader(store_data)
      @user = store_data['user']
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
      @status_obj = connection_status(:undefined)
    end
  end

  class CouchDbStore < StoreBase
    self.store_type = 'couchdb'
    def initialize(store_name, couch_data)
      super(store_name, couch_data)
      init_status = nil
      db_path = "/" + store_name 
      url = URI::HTTP.build :userinfo => @user, :host => @host, :path => db_path, :port => 5984
      begin
        store = CouchRest.database! url.to_s
      rescue => e
        raise LoadError, 
          "Failed to initialize #{self.class} \n Full Error Message:\n #{e.message}\n#{e.backtrace}"
      end
      begin
        resp_ex = JSON.parse(`curl -sX GET #{url.to_s}`)
        #conditions to complicated for case statement
        #TODO: I don't like the long if statement with returns, but can't think of a cleaner way at the moment
        if resp_ex.respond_to?(:keys) && resp_ex["db_name"] == store_name
          init_status = :access
          @status_obj = connection_status(init_status)
          dummy_data = {:dummy => "Dummy"}.to_json
          #check if store can be written to (and read)
          resp_rw = JSON.parse(`curl -sX POST #{url.to_s} -H 'Content-Type:application/json' -d \'#{dummy_data}\'`)
          #set rw permissions on acces objectif resp_rw["id"]       
        else
          if resp_ex.to_s =~ /Host not found/
            init_status = :not_found
             @status_obj = connection_status(init_status)
          elsif resp_ex.respond_to?(:keys) && resp_ex["error"] == "unauthorized"
            init_status = :access_denied
             @status_obj = connection_status(init_status)
          else
            init_status = :unavailable
             @status_obj = connection_status(init_status)
          end
        end
      rescue => e
        puts "RESCUED #{e.message}"
        init_status = :unavailable
         @status_obj = connection_status(init_status)
      ensure
        raise "Logic Error, @status_obj should exist and be set" unless @status_obj
      end
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
      dbi_host = "DBI:Mysql:#{init_db}:#{host}"
      user, pw = @user.split ":"
      begin
        store = DBI.connect dbi_host, user, pw
        row = store.select_one("SELECT VERSION()")
        @status_obj = connection_status(:access)
        store.do "DROP TABLE IF EXISTS dummy"
        store.do "CREATE TABLE dummy (
                    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                    test_data CHAR(20) NOT NULL,
                    PRIMARY KEY (id))"
        rows = store.do "INSERT INTO dummy(test_data)
                           VALUES
                             ('Test1'), ('Test2')"
        store.do "DROP TABLE IF EXISTS dummy"
     rescue DBI::DatabaseError => e
       @status_obj = connection_status(:not_found)
     ensure
       raise "Status Object not defined" unless @status_obj
       store.disconnect if store
     end
     @mysql_connection = [dbi_host, user, pw]
    end
  end

  class FileStore < StoreBase
    self.store_type = 'file'
    def initialize(store_name, file_data)
      init_status = nil
      super(store_name, file_data)
      file_store_path = File.join(@host, store_name)
      begin
        native_resp = FileUtils.mkdir_p(file_store_path)
        @status_obj = connection_status(:access)
      rescue Errno::EACCES
        @status_obj = connection_status(:access_denied)
      end
    end
  end

  class SdbS3Store < StoreBase
    self.store_type = 'sdb_s3'
    def initialize(store_name, sdb_s3_data)
      super(store_name, sdb_s3_data)
      userinfo = sdb_s3_data["user"]
      if userinfo
        aws_keys = userinfo.split ":"
        access_key = aws_keys.first
        sa_key = aws_keys.last
        if access_key && sa_key
          svc_options = {:access_key_id => access_key, :secret_access_key => sa_key}
          sdb_store = AwsSdb::Service.new(svc_options)
          begin
            sdb_store.create_domain(store_name)
            connection_status(:access)
          rescue AwsSdb::ConnectionError => e
            puts "Rescued ConnectionError: #{e.message}"
            if e.message =~ /403/
              @status_obj = connection_status(:access_denied)
            else
              @status_obj = connection_status(:unavailable)
            end
          rescue => e
            puts "Rescued #{e.message}"
            @status_obj = connection_status(:unavailable)
          end
        else
          @status_obj = connection_status(:undefined)
        end
      else
        @status_obj = connection_status(:undefined)
      end
    end
  end

end

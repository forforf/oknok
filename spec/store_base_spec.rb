require_relative "../lib/oknok/store_base"
#require 'fileutils'
#require 'psych'

module OknokConfigData
  @@ak = ENV['AWS_ACCESS_KEY_ID']
  @@sak = ENV['AWS_ACCESS_KEY_SECRET']
  Config = {
    'avail_stores' => {
      'couchstore' => {
        'type' => 'couchdb',
        'host' => 'couchsurfer.iriscouch.com', #=> easy to set up your own
        'user' => nil
      },
      'local_filesystem' => {
        'type' => 'file',
        'host' => '/tmp/spec/',
        'user' => nil
      },
      'local_filesystem_dup' => {
        'type' => 'file',
        'host' => '/tmp/spec/',
        'user' => nil
      },
      'remote_mysql' => {
        'type' => 'mysql',
        'host_lookup_engine' => 'WebService',
        'host' => 'http://couchsurfer.iriscouch.com/ec2lookup/open_db',
        'init_db' => 'oknok',
        'user' => 'open:open'
      },
      'test_sdb' => {
        'type' => 'sdb',
        'host' => nil,   #No Host needed
        'user' => "#{@@ak}:#{@@sak}" #or create your own lookp service
      }
    }
  }

end

describe Oknok::StoreBase, "basic initialization tasks" do
  include Oknok
  
  before :each do
    config_data = OknokConfigData::Config["avail_stores"]
    @config_data = config_data
    @type_to_class_map = {
      'couchdb' => CouchDbStore,
      'file' => FileStore,
      'mysql' => MysqlStore,
      'sdb' => SdbStore,
      :unknown => NullStore
    }
    #Map store handle to initialization data
    #sto_handle => {:klass => StoreClass, :args => [sto_handle, sto_config_data] )
    #For example
    #@store_init_data = {..., 'file' => { :klass => FileStore, :args ['file', @config_data['file'] }, ...}
    @store_init_data = @config_data.inject({}) do |memo, (k,v)|
      memo[k] = {
        :klass => @type_to_class_map[ v['type'] ],
        :args => [k, @config_data[k]]
      }
      memo
    end
    
    
    #@couch_args    = ["couchstore", config_data["couchstore"]]
    #@file_args     = ["local_filesystem",config_data["local_filesystem"]]
    #@file_dup_args = ["local_filesystem_dup", config_data["local_filesystem_dup"]]
    #@mysql_args    = ["remote_mysql", config_data["remote_mysql"]]
    #@sdb_args   = ["test_sdb", config_data["test_sdb"]]
    #@null_args     = ["any_store_name", {}]
      
    @class_data_map = {
      CouchDbStore => @couch_args,
      FileStore => @file_args,
      MysqlStore => @mysql_args,
      SdbStore => @sdb_args,
      NullStore => @null_args
    }
  end

  it "initializes from config data without blowing up" do
    sto_objs = []
    @store_init_data.each do |sto_handle, sto_init_data|
      sto_objs << sto_init_data[:klass].new(*sto_init_data[:args])
    end
    sto_objs
  end
 
  describe "after successful initialization" do
  
    before :each do
      @store_obj_data_by_handle = @store_init_data.inject({}) do |memo, (sh,sd)|
        memo[sh] = {
          :store_obj => sd[:klass].new(*sd[:args]),
          :config_data => sd[:args].last
        }
        memo
      end
      @store_objs = @store_obj_data_by_handle.inject([]) do |memo, (k,v)|
        memo << v[:store_obj]
        memo
      end
    end
  
    it "has a store type" do
      @store_obj_data_by_handle.each do |sto_handle, sto_data|
        sto_obj = sto_data[:store_obj]
        sto_type = sto_data[:config_data]['type']
        sto_obj.class.store_type.should == sto_type
      end
    end
   
    it "has a store name" do
      @store_obj_data_by_handle.each do |sto_handle, sto_data|
        sto_obj = sto_data[:store_obj]
        sto_obj.store_name.should == sto_handle
      end
    end
    
    #it "has an oknok name" do
    #  @store_objs.each_with_index do |sto, idx|
    #    sto.oknok_name.should == @oknok_name
    #  end
    #end

    it "has host data" do
      @store_obj_data_by_handle.each do |sto_handle, sto_data|
        sto_obj = sto_data[:store_obj]
        sto_obj.host.should == StoreNameLookup.config_reader(sto_data[:config_data])
      end
    end

    it "has StoreAccess methods included" do
      @store_objs.each do |sto|
        sto.kind_of?(StoreAccess).should == true
      end
    end


    it "has StoreAccess extended (class methods)" do
      @store_objs.each do |sto|
        sto.class.include?(StoreAccess).should == true
      end
    end

    #moved to store_tracker
    #it "collects instances" do
    #  num_stores_in_config = @config_data.size
    #  num_objs_made = @store_objs.size
    #  num_objs_made.should == num_stores_in_config
    #  collected_instances = StoreBase.get_my_instances
    #  collected_instances.size.should == num_objs_made
    #end
  #end
  
    describe "store_access shared examples" do
      it "has access status" do
      end
    end
  end
end

  ##include StoreAccess shared tests
require_relative 'store_access_shared'

describe "shared examples with mock object" do
  include Oknok

  class MockStoreClass < Oknok::StoreBase
    
    def initialize(storename, host, user, conn_status)
      fake_data = {'host' => host, 'user' => user}
      @connection_status = connection_status(conn_status, nil)
    end
  end  
  
  #before :each do
  #  @mock_obj = MockStoreClass.new("mock", "nowhere", nil)
  #end
  
  it "should default too undefined connection status" do
    mock_obj = MockStoreClass.new("mock", "nowhere", nil, nil)
    mock_obj.status_obj.class.should == StoreAccess::Undefined
  end
  
  it "can be set to undefined" do
    mock_obj = MockStoreClass.new("mock", "nowhere", nil, :undefined)
    mock_obj.status_obj.class.should == StoreAccess::Undefined
  end
 
  it "can be set to not found" do
    mock_obj = MockStoreClass.new("mock", "nowhere", nil, :not_found)
    mock_obj.status_obj.class.should == StoreAccess::NotFound
  end
  
  it "can be set to unavailable" do
    mock_obj = MockStoreClass.new("mock", "nowhere", nil, :unavailable)
    mock_obj.status_obj.class.should == StoreAccess::Unavailable
  end
  
  it "can be set to access denied" do
    mock_obj = MockStoreClass.new("mock", "nowhere", nil, :access_denied)
    mock_obj.status_obj.class.should == StoreAccess::AccessDenied
  end
end

describe "StoreAccess with real data store object" do
  include Oknok
  before :each do
    config_data = OknokConfigData::Config['avail_stores']
    @file_args     = ["local_filesystem",config_data["local_filesystem"]]
    @file_obj = FileStore.new(*@file_args)
    @couch_args    = ["couchstore", config_data["couchstore"]]
    @couch_obj = CouchDbStore.new(*@couch_args)
    @mysql_args    = ["remote_mysql", config_data["remote_mysql"]]
    @mysql_obj = MysqlStore.new(*@mysql_args)
    @sdb_args   = ["test_sdb", config_data["test_sdb"]]
    @sdb_obj = SdbStore.new(*@sdb_args)
    @null_args     = ["any_store_name", {}]
    @null_obj = NullStore.new(*@null_args)
  end
  
  it_should_behave_like Oknok::StoreAccess do
    let(:obj) {@file_obj}
  end
  
  it_should_behave_like Oknok::StoreAccess do
    let(:obj) {@couch_obj}
  end
  
  it "can access couch obj" do
    @couch_obj.status_obj.class.should == StoreAccess::Access
    @couch_obj.store_handle.class.should  == CouchRest::Database
  end  
  
  it "can access file obj" do
    @file_obj.status_obj.class.should == StoreAccess::Access
    @file_obj.store_handle.should_not == nil
  end
  
  it "can access mysql obj" do
    @mysql_obj.status_obj.class.should == StoreAccess::Access
    @mysql_obj.store_handle.class.should == DBI::DatabaseHandle
  end
  
  it "can access sdb obj" do
    @sdb_obj.status_obj.class.should == StoreAccess::Access
    @sdb_obj.store_handle.class.should == AwsSdb::Service
  end
  
  it "sets NullStore Access to undefined" do
    @null_obj.status_obj.class.should == StoreAccess::Undefined
    @null_obj.store_handle.should == nil
  end
  
end

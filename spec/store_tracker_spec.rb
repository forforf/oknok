require_relative "../lib/oknok/store_tracker.rb"

#Module providing accessibility of the store (exists, readable, writable, etc)
#require_relative 'store_status'
module YourConfigData
  #Default location of config file (must be manually set)
  Datafile = File.join( File.dirname(__FILE__),
    "../sample_store_config")
end

describe Oknok::StoreTracker, "initialization"  do
  include Oknok

  before :each do
    @config_file = YourConfigData::Datafile
  end

  it "raises error if config file is set to non-existant file" do
    expect{ StoreTracker.new('/bar/foo/baz') }.to raise_error IOError
  end

  it "can initialize without blowing up" do
     @config_file
     tracker = StoreTracker.new(@config_file)
     tracker.should_not == nil
     tracker.config_data.should == SensData.load(@config_file)
  end
end

describe Oknok::StoreTracker, "operation" do
  include Oknok

  before :each do
    @config_file = YourConfigData::Datafile
    @tracker = StoreTracker.new(@config_file)
    @store_data = SensData.load(@config_file)['avail_stores']
  end

  it "has the available stores from config file" do
    @tracker.avail_stores.should == @store_data
  end

  it "has the store classes (derived from StoreBase)" do
    @tracker.store_classes.each do |sto_class|
      sto_class.ancestors.should include StoreBase
      sto_class.should_not == StoreBase
    end
  end

  it "can find store class from type in config file" do
    types = []
    @store_data.each do |sto_name, sto_fields|
      types << sto_fields['type']
    end
    types.each do |sto_type|
      class_from_type = @tracker.find_store_class_by_type(sto_type)
      class_from_type.ancestors.should include StoreBase
      class_from_type.should_not == StoreBase
      class_from_type.store_type.should == sto_type
    end
  end

  it "has collection of activated store instances" do
    @tracker.store_collection.size.should == @store_data.size
    @tracker.store_collection.each do |sto_obj|
      sto_obj.class.ancestors.should include StoreBase
      sto_obj.class.should_not == StoreBase
    end
  end
  
  it "can return a handle for a CouchDb store type" do
    couchdb_stores = @tracker.get_store_types("couchdb")
    couchdb_store = couchdb_stores.first
    couchdb_store.class.should == Oknok::CouchDbStore
    couchdb_store.class.store_type.should == "couchdb"
    couchdb_store.status_obj.class.should == Oknok::StoreAccess::Access
    couchdb_store.store_handle.class.should == CouchRest::Database
    config_data = SensData.load(@config_file)
    couchdb_store.store_handle.to_s.should =~ /iris/
  end

  it "can return a handle for a file store" do
    couchdb_stores = @tracker.get_store_types("file")
    couchdb_stores.size.should == 2
    couchdb_stores.each do |sto|
      handle = sto.store_handle
      File.exists?(handle).should == true
    end
  end

  it "can return a handle for a store named 'iris' store type" do
    couchdb_store = @tracker.get_store_name("iris")
    couchdb_store.class.should == Oknok::CouchDbStore
    couchdb_store.class.store_type.should == "couchdb"
    couchdb_store.status_obj.class.should == Oknok::StoreAccess::Access
    couchdb_store.store_handle.class.should == CouchRest::Database
    config_data = SensData.load(@config_file)
    couchdb_store.store_handle.to_s.should =~ /iris/
  end

  it "can return a handle for a file stores named 'local_filesystem1' and 'local_filesystem2" do
    file_store_names = ['local_filesystem1', 'local_filesystem2']
    file_store_names.each do |sto_name|
      file_store = @tracker.get_store_name(sto_name)
      file_handle = file_store.store_handle
      File.exists?(file_handle).should == true
    end
  end
  
end


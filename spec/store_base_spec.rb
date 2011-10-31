require_relative "../lib/oknok/store_base"
#require 'fileutils'
#require 'psych'

module OknokConfigData
  Config = {
    'avail_stores' => {
      'iris' => {
         'type' => 'couchdb',
         'host' => 'couchsurfer.iriscouch.com', #=> easy to set up your own
         'user' => nil
      },
    'other_couch' => {
       'type' => 'couchdb',
       'host_lookup_engine' => 'WebService',
       'host' => 'http://couchsurfer.iriscouch.com/ec2lookup/open_db',
       'user' => ' open:open'
     },
     'local_filesystem1' => {
        'type' => 'file',
        'host' => '/tmp/spec1/',
        'user' => nil
     },
     'local_filesystem2' => {
        'type' => 'file',
        'host' => '/tmp/spec2/',
        'user' => nil
     },
     'remote_mysql' => {
        'type' => 'mysql',
        'host_lookup_engine' => 'WebService',
        'host' => 'http://couchsurfer.iriscouch.com/ec2lookup/open_db',
        'init_db' => 'oknok',
        'user' => ' open:open'
      },
      'dev_sdb_s3' => {
        'type' => 'sdb_s3',
        'host' => nil,   #No Host needed
        'user' => ' <access key here>:<secret key here>' #or create your own lookp service
      }
    }
  }

end

describe Oknok::StoreBase, "common initialization tasks" do
  include Oknok

  
  before :each do
    #config_data = OknokConfigData::Config
    @all_store_data = config_data["avail_stores"]
    #@store_names = @all_store_data.keys
    @store_objs = []
    @all_store_data.each do |sto_name, sto_config|
      @store_objs << StoreBase.new(sto_name)
    end
  end

  it "has a store name" do
    @store_objs.each_with_index do |sto, idx|
      sto.store_name.should == @store_names[idx]
    end
  end

  it "has an oknok name" do
    @store_objs.each_with_index do |sto, idx|
      sto.oknok_name.should == @oknok_name
    end
  end

  it "has host data" do
    @store_objs.each do |sto|
      sto_data = @all_store_data[sto.store_name]
      sto.host.should == StoreNameLookup.config_reader(sto_data)
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

  it "collects instances" do
    num_stores_in_config = @store_names.size
    num_objs_made = @store_objs.size
    num_objs_made.should == num_stores_in_config
    collected_instances = StoreBase.get_my_instances
    collected_instances.size.should == num_objs_made
  end
end


##include StoreAccess shared tests
#require_relative 'store_access_shared_spec'

#describe "included module behavior" do
#  include Oknok
  
#  shared_examples_for "StoreAccess" do
#    #StoreBase.set_config_file_location(YourConfigData::DatastoreConfig)
#    #p Oknok::StoreBase.read_config_data
#    let(:objs) = [1,2,3,4]
#    it "dummy" do
#      p "dummy"
#    end
#  end
  #test module behavior
  #oknok_name = "test_name"
  #config_data = Oknok::StoreBase.read_config_data
  #all_store_data = config_data["avail_stores"]
  #store_names = all_store_data.keys
  #store_objs = store_names.map{|name| StoreBase.make(name, oknok_name)}
#end



describe Oknok::StoreBase, "Factory" do
  include Oknok

  before :each do
    @oknok_name = "test_name"
    config_data = StoreBase.read_config_data
    @all_store_data = config_data["avail_stores"]
    @store_names = @all_store_data.keys
    @store_objs = @store_names.map{|name| StoreBase.make(name, @oknok_name)}
    @reach_map = {}
    @store_objs.each do |sto|
    end
  end


  it "intializes with a reachability status " do
    @store_objs.each do |sto|
      StoreAccess::Reachable::Levels.should include sto.status
    end
  end

  #Mock this out for testing
  it "should have a collection by reachability status" do
    reach = StoreBase.all_reachability
    reach.each do |reach, stores|
      puts "#{reach} => #{stores.map{|sto| sto.store_name}}.inspect"
    end
  end

end


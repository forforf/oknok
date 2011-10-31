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

end


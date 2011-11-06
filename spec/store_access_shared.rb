require_relative '../lib/oknok/store_access'

class StoreAccessTest
 include Oknok::StoreAccess
end


shared_examples_for Oknok::StoreAccess  do
  include Oknok::StoreAccess


  it "should have an obj to work with" do |obj|
    obj.should_not == nil
    obj.kind_of?(Oknok::StoreAccess).should == true
  end
  
  it "can set status object" do |obj|
    #may need to filter at some point to just get class definitions
    access_consts_syms  = Oknok::StoreAccess.constants(false)
    access_consts = access_consts_syms.map{|ac_sym| Oknok::StoreAccess.const_get(ac_sym)}
    status_subclasses = access_consts.select{|ac| ac.respond_to?(:"status_subclass?") ? ac.status_subclass? : nil}
    status_subclasses.size.should > 0
    status_subclasses.each do |klass|
      obj.set_status(klass)
      obj.status_obj.class.should == klass
    end
  end
  
  #mock_obj should be derived from MockStoreClass
  it "provides Undefined Access object when there is no connection defined" do |mock_obj|
    if mock_obj.respond_to?(:connection_status)
      case mock_obj.connection_status
        when nil
          mock_obj.status_obj.class.should == Undefined
      end
    end
  end
  
end


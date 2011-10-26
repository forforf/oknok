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

  it "can set and get permissions numerically" do |obj|
    0.upto 7 do |perm_val|
      obj.set_permissions(perm_val)
      obj.permissions.should == perm_val
    end
  end

  it "can reset permissions" do |obj|
    Permissions::None.should == 0
    0.upto 7 do |perm_val|
      obj.set_permissions(perm_val)
      obj.reset_permissions
      obj.permissions.should == Permissions::None
    end
  end

   it "can add and get permissions descriptively" do |obj|
     read   = Permissions::Read
     write  = Permissions::Write
     delete = Permissions::Delete
     obj.reset_permissions
     obj.add_permissions(:read)
     obj.get_permissions.should == [:read]
     obj.permissions.should == read
     obj.add_permissions(:read)
     obj.permissions.should == read
     obj.get_permissions.should == [:read]
     obj.add_permissions(:write)
     obj.get_permissions.should include :read
     obj.get_permissions.should include :write
     obj.permissions.should == read + write
     obj.add_permissions(:delete)
     obj.get_permissions.should include :read
     obj.get_permissions.should include :write
     obj.get_permissions.should include :delete
     obj.permissions.should == read + write + delete
   end

   it "can handle an easy mistake to make" do |obj|
     read   = Permissions::Read
     write  = Permissions::Write
     delete = Permissions::Delete
     obj.reset_permissions
     #set_permissions takes numeric arg, see add_permissions
     obj.set_permissions([:write, :delete, :read])  
     obj.permissions.should == read + write + delete
   end

   it "has reachablility data" do
     fail {"Not Implemented"}
   end
end


describe Oknok::StoreAccess do
  before :each do
    @obj = StoreAccessTest.new
  end
  
  it_should_behave_like Oknok::StoreAccess, @obj
end

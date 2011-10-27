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

   it "has Reachable constants defined" do 
     Reachable::NoAccess.should == 0
     Reachable::Net.should == 1
     Reachable::App.should == 2
     Reachable::Data.should == 3
   end
 
   it "can set and reset status" do |obj|
     no_access = Reachable::NoAccess
     net = Reachable::Net
     app = Reachable::App
     data = Reachable::Data
     obj.set_status(no_access)
     obj.status.should == no_access
     obj.set_status(net)
     obj.status.should == net
     obj.set_status(app)
     obj.status.should == app
     obj.set_status(data)
     obj.status.should == data
     obj.reset_status
     obj.status.should == no_access
   end

   it "can set network connected status" do |obj|
     obj.net_connected
     obj.status.should == Reachable::Net
   end

   it "can set application connected status" do |obj|
     obj.app_connected
     obj.status.should == Reachable::App
     #lower connection shouldn't overwrite higher connection
     #use set_status if that's needed
     obj.net_connected
     obj.status.should == Reachable::App
   end

   it "can set data connected status" do |obj|
     obj.data_connected
     obj.status.should == Reachable::Data
     obj.net_connected
     obj.status.should == Reachable::Data
     obj.app_connected
     obj.status.should == Reachable::Data
   end

   it "can return descriptive connection level" do |obj|
     obj.set_status(nil)
     obj.connection_level.should == :undefined
     obj.set_status(Reachable::Net)
     obj.connection_level.should == :net
     obj.set_status(Reachable::App)
     obj.connection_level.should == :app
     obj.set_status(Reachable::Data)
     obj.connection_level.should == :data
   end

end


describe Oknok::StoreAccess do
  before :each do
    @obj = StoreAccessTest.new
  end
  
  it_should_behave_like Oknok::StoreAccess, @obj
end

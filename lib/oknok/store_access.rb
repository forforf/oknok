module Oknok
  module StoreAccess

    # Access Hierarchy
    #  net(work)       - Network Reachable
    #  app(lication)   - Datastore Application Reachable
    #  data            - User has access to datastore
    module Reachable
      NoAccess = 0
      Net      = 1
      App      = 2
      Data     = 3
    end

    module Permissions
      None     = 0
      Read     = 1
      Write    = 2
      Delete   = 4
    end

    def reset_permissions
      @read, @write, @delete = 0,0,0
    end

    def set_permissions(new_perm_val)
      return add_permissions(new_perm_val) if new_perm_val.respond_to? :include?
      none = Permissions::None
      read = Permissions::Read
      write = Permissions::Write
      delete = Permissions::Delete
      (new_perm_val/1 %2) == 1 ? @read = read : @read = none
      (new_perm_val/2 %2) == 1 ? @write = write : @write = none
      (new_perm_val/4 %2) == 1 ? @delete = delete : @delete = none
      permissions
    end

    def permissions
      @read + @write + @delete || 0
    end

    def add_permissions(perm_list)
      perm_list = *perm_list
      @read = Permissions::Read if  perm_list.include? :read
      @write = Permissions::Write if perm_list.include? :write
      @delete = Permissions::Delete if perm_list.include? :delete
      get_permissions
    end

    def get_permissions
      perm_val = permissions
      raise "Invalid Permission data" if perm_val > 15
      result = []
      result << :delete if (perm_val/4) % 2 == 1
      result << :write  if (perm_val/2) % 2 == 1
      result << :read   if perm_val    % 2 == 1
      result << :none   if   perm_val == 0
      result
    end

     
    # Elements(future?)- User permission by data store elements 
    # datastore        - Equivalent to data access
    # database/table   - Manipulate collections object in data store
    # node             - Manipulate record data in data store
    # attachment       - Manipulate file attachments in data store

    #end

    #some metaprogramming so that when
    #this module is included, the class methods
    #are also applied to the host class
    def self.included( host_class )
      
      #puts "###### HOST CLASS: #{host_class.inspect} ########"
      host_class.send(:attr_reader, :read, :write, :delete)
      host_class.extend( Reachable, Permissions )
    end

    #Regular Methods
  end
end

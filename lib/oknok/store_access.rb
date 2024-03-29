module Oknok
  module StoreAccess
    class Status
      @@subclasses = []
      
      def self.inherited(subclass)
        @@subclasses << subclass
      end
      
      #checks if class inherited from Status
      #but doesn't include Status
      def self.status_subclass?
        true if @@subclasses.include? self
      end
    end
    class NoAccess < Status
    end
    class Undefined < NoAccess
    end
    class NotFound < NoAccess
    end
    class Unavailable < NoAccess
    end
    class AccessDenied < NoAccess
    end
    class Access < Status
    end
    
    def set_status(status_class)
      @status_obj = status_class.new
    end
    
    #some metaprogramming so that when
    #this module is included, the class methods
    #are also applied to the host class
    def self.included( host_class )
    #  
    #  #puts "###### HOST CLASS: #{host_class.inspect} ########"
      host_class.send(:attr_reader, :status_obj)
    #  #host_class.extend(  )
    end
  end
end
  
=begin
    # Access Hierarchy
    #  net(work)       - Network Reachable
    #  app(lication)   - Datastore Application Reachable
    #  data            - User has access to datastore
    module Reachable #Class Level
      Undefined  = -1 
      NoAccess   = 0
      Net        = 1
      App        = 2
      Data       = 3
      Levels = [Undefined,NoAccess,Net,App,Data]
    end

    def reset_status
      @status = Reachable::NoAccess
    end
    
    #set status manually  
    def set_status(status)
      @status = status
    end

    #status setting helpers
    #note setting a lower status will not change status
    def net_connected
      net = Reachable::Net
      @status = net unless (@status && @status >= net)
    end

    def app_connected
      app = Reachable::App
      @status = app unless (@status && @status >= app)
    end

    def data_connected
      data = Reachable::Data
      @status = data unless (@status && @status >= data)
    end

    def connection_level
      conn_lvl = case @status
        when Reachable::NoAccess
          :no_access
        when Reachable::Net
          :net
        when Reachable::App
          :app
        when Reachable::Data
          :data
        else Reachable::Undefined
          :undefined
      end
    end

    def full_connectivity?
      data = Reachable::Data
      return true if @status = data
      false
    end

    #TODO: Introspect for undefined_handler?
    #Currently the host object has to declare
    #it can't support reachable methods
    #(e.g.) the NullStore class
    def undefined_reachability
      @status = Reachable::Undefined
    end
    

   #Permission Behavior

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
      host_class.send(:attr_reader, :read, :write, :delete, :status)
      host_class.extend( Reachable, Permissions )
    end

    #Regular Methods
  end
end
=end
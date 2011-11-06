#Oknok Datastore Loader

Oknok uses a configuration file to load a set of persistent data stores.

## The Basics
### An example configuration file that will load a CouchDb instance located at iriscouch.com.

    #file: /path/to/config/file/config_file_name.yaml
    
    avail_stores:                        #top level key
      iris:                              #user defined id for this data store
        type: couchdb                    #defined by oknok
        host: couchsurfer.iriscouch.com  #location of data store
        user: ~                          #specific user data required (i.e., username/password)

#### Load the data stores:
    
    require 'oknok'
    
    stores = Oknok::StoreTracker.new("/path/to/config/file/config_file_name.yaml")
    
#### And to get a "handle" on the native data store access object
    
    store = stores.first   #we only had one store for this example
    store.store_handle     #=> CouchRest::Database object
    
## Unreachable Datastores
### What if there's no answer for oknok (i.e., the store is down or unreachable)?

Each oknok store will have a status associated with it, that will indicate whether the store was successfully connected or not.
 
    #successful connection 
    store.status_obj
    #=> Oknok::StoreAccess::Access object
    
    #unsuccessful connection
    store.store_handle
    #=> nil
    store_status_obj
    #=> Oknok::StoreAccess::NotFound object
    
Connection Status Objects:
    
    Oknok::StoreAccess::Access          -  Store was successfully accessed
    Oknok::StoreAccess::AccessDenied    -  The data store application denied access for some reason
    Oknok::StoreAccess::Unavailable     -  The data store application didn't respond
    Oknok::StoreAccess::NotFound        -  The data store application couldn't find the data store specified
    Oknok::StoreAccess::Undefined       -  Unable to determine the type of data store

    
Important Note: Exceptions relating to connection failures are rescued and mapped to the appropriate connection status. This means you don't need all of your data stores to be available concurrently.

Of course, this is overkill for accessing a single data store, what it's really intended for is
to provide access to multiple data stores regardless of the type of store.
        

## A configuration file with multiple data stores        

    #file: /path/to/config/file/config_file_name.yaml
        
    avail_stores:                        
      iris:                              
        type: couchdb                    
        host: couchsurfer.iriscouch.com
        user: ~        
      local_filesystem1:
        type: file
        host: /tmp/spec1/
        user: ~
      remote_mysql:
        type: mysql
        host_lookup_engine: WebService 
        host: 'http://couchsurfer.iriscouch.com/ec2lookup/open_db'
        init_db: oknok
        user: open:open
                
### Gain access to the data stores

    require 'oknok'
    stores = Oknok::StoreTracker.new("/path/to/config/file/config_file_name.yaml")
    
    iris = stores.get_store_name("iris")
    iris_handle = iris.store_handle  
    #=> CouchRest::Database Object
    
    local_filesys = stores.get_store_name("local_filesystem1")
    local_handle = local_filesys.store_handle
    #=> "/tmp/spec1/"
    
#### Notice something different about the mysql configuration data?
Oknok allows for host names to be computed in addition to being specified. In this particular example the 
host name defined by the parameter `host` is actually a web server that takes the name of the store ('remote_mysql')
and returns the IP address of the actual host with the remote mysql service running. The way you get access to
the store is exactly the same though:    
    
    mysql= stores.get_store_name("remote_mysql")
    mysql_handle = mysql.store_handle
    #=> DBI::DBD::MysqlHandle
    

### Gain access to the data stores by type of store

    #file: /path/to/config/file/config_file_name.yaml
        
    avail_stores:                        
      local_filesystem1:
        type: file
        host: /tmp/spec1/
        user: ~     
      local_filesystem2:
        type: file
        host: /tmp/spec2/
        user: ~        
        
It's ok to have multiple stores of the same type.

    require 'oknok'
    stores = Oknok::StoreTracker.new("/path/to/config/file/config_file_name.yaml")
    
    file_stores = stores.get_store_types("file")
    file_stores.map {|sto| sto.store_handle}
    #=> ["/tmp/spec1", "/tmp/spec2"]
    
    
    
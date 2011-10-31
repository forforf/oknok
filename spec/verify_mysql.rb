#!/usr/bin/ruby
#pw: my normal pw
#require 'rubygems'
require 'mysql'


puts "Verifying mysql gem connectivity"
mysql = Mysql.init()
mysql.connect('10.206.41.22', 'open', 'open')
puts "connected"
results = mysql.query("SELECT now();")
results.each{|row|; puts row;}
mysql.close()
puts "Mysql gem success at : #{results}"
puts
#gem 'mysql'
#gem 'dbi'
require 'dbi'
#dbi requires the driver, which for mysql is gem dbd-mysql

puts "Verifying DBI connectivity"
  
  begin
    #dbh = DBI.connect "DBI:Mysql:tinkit_spec_dummy:ec2-107-20-64-85.compute-1.amazonaws.com", "joha", "joha"
    #dbh = DBI.connect "DBI:Mysql:tinkit_spec_dummy:10.206.41.22", "open", "open"
    dbh = DBI.connect "DBI:Mysql:tinkit_spec_dummy:10.206.41.22", "open", "open"
    puts "DBI connected"
  # get server version string and display it
     row = dbh.select_one("SELECT VERSION()")
     puts "Server version: " + row[0]
   rescue DBI::DatabaseError => e
     puts "An error occurred"
     puts "Error code: #{e.err}"
     puts "Error message: #{e.errstr}"
   ensure
     # disconnect from server
     dbh.disconnect if dbh
   end


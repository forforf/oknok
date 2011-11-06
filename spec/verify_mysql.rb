#This is a small script to aid in verifying connectivity to mysql databases

require 'mysql'
host = "mysql host goes here"
user = "username"
pw = "secret password"

puts "Verifying mysql gem connectivity"
mysql = Mysql.init()
mysql.connect(host, user, pw)
puts "connected"
results = mysql.query("SELECT now();")
results.each{|row|; puts row;}
mysql.close()
puts "Mysql gem success at : #{results}"
puts
require 'dbi'

puts "Verifying DBI connectivity"
  
  begin
    dbh = DBI.connect "DBI:Mysql:tinkit_spec_dummy:10.206.41.22", "open", "open"
    puts "DBI connected"
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


require_relative "../lib/oknok/store_name_lookup"

describe 'StoreNameLookup' do
  
  before :each do
    @default_config_data1 = {'host' => 'foo.com/bar'}
    @default_config_data2 = {'host' => 'foo.com/bar', 'host_lookup_engine' => nil}
    @invalid_lookup_data = {'host' => 'remote.foo.bar/com', 'host_lookup_engine' => 'NotExist'}
    @remote_lookup_data = {'host' => 'remote.foo.bar/com', 'host_lookup_engine' => 'WebService'}
  end

  it 'returns the host if called without a lookup engine' do
    [ @default_config_data1, @default_config_data2 ].each do |config_data|
      host =  StoreNameLookup.config_reader(config_data)
      host.should == config_data['host']   
    end
  end

  it 'provides (a more) informative error message for invalid lookups' do
    expect {StoreNameLookup.config_reader(@invalid_lookup_data)}.to raise_error(NameError, /Lookup Engine module/)
  end

  it 'returns a remote host if called with an lookup engine' do
    #stubbing out the web service call
    StoreNameLookup::WebService.stub(:get_data) do |url|
      url.should == @remote_lookup_data['host']
      {:foo => "bar", "ip" => "10.10.10.10"}.to_json
    end

    host = StoreNameLookup.config_reader(@remote_lookup_data)
    host.should == "10.10.10.10"
  end

end

require_relative "../lib/oknok/sens_data"
require 'fileutils'
require 'psych'


module SensDataHelper
  def self.make_yaml_file(fname, data)
    yaml = Psych.dump data
    File.open(fname, 'w'){|f| f.write(yaml)}
  end
end

describe Oknok::SensData do
  include Oknok
  before :each do
    @tmp_file = "/tmp/sens_data"
    @data = {
      'avail_stores' => {
        'iris' => {
          'type' => 'couchdb',
          'host' => 'foo.iriscouch.com',
          'user' => nil
        }
      }
    }
    SensDataHelper.make_yaml_file @tmp_file, @data

    @tmp_file_invalid = "/tmp/sens_data_invalid"
    inv_data = {'foo' => 'bar'}
    SensDataHelper.make_yaml_file @tmp_file_invalid, inv_data
    @tmp_file_empty = "/tmp/sens_data_empty"
    FileUtils.touch @tmp_file_empty
  end

  after :each do
    FileUtils.rm @tmp_file if File.exist? @tmp_file
    FileUtils.rm @tmp_file_invalid if File.exist? @tmp_file_invalid
    FileUtils.rm @tmp_file_empty if File.exist? @tmp_file_empty
  end
   
  it "should raise error if config file doesnt exist" do
    expect{SensData.load("/road/to/nowhere")}.to raise_error(IOError)
  end

  it "should fail if the config file is invalid" do
    expect{SensData.load(@tmp_file_invalid)}.to raise_error(SensData::ParseError)
  end

  it "should load valid data" do
    SensData.load(@tmp_file).should == @data
  end
end

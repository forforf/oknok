require_relative '../lib/oknok/store_access'

class StoreAccessTest
 include Oknok::StoreAccess
end

require_relative 'store_access_shared'

describe Oknok::StoreAccess do
  before :each do
    @obj = StoreAccessTest.new
  end
 
  it_should_behave_like Oknok::StoreAccess do
    let(:obj) {@obj}
  end
end

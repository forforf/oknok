require_relative "sens_data"
require_relative "store_base"

module Oknok
  class StoreCollection < Array
  end

  class StoreTracker

    attr_reader :config_data, :avail_stores, :store_classes, :store_type, :store_collection

    def initialize(oknok_config_file, base_class = StoreBase)
      @store_classes = base_class.all_classes
      validate oknok_config_file
      @config_data = Oknok::SensData.load(oknok_config_file)
      @avail_stores = parse_avail_stores
      @store_collection = StoreCollection.new
      @avail_stores.each do |sto_name, sto_config|
        sto_type = sto_config['type']
        sto_class = find_store_class_by_type(sto_type)
        sto_obj = sto_class.new(sto_name, sto_config)
        @store_collection << sto_obj
      end
    end

    def find_store_class_by_type(sto_type)
      store_class_list = @store_classes.select{|sto_cls| sto_cls.store_type == sto_type}
      sto_class = case store_class_list.size
        when store_class_list.size > 1
          raise IndexError,
            "More than one Store Class found for type: #{sto_type}"
        when 1
          store_class_list.first
        when 0
          NullStore.store_type = sto_type
          NullStore #no matching store found
      end
      return sto_class
    end

    def parse_avail_stores
      @config_data['avail_stores']
    end
    
    def validate(config_file)
      raise IOError,
        "Config file not found: #{config_file.inspect}" \
        unless File.exist? config_file
    end

  end
end


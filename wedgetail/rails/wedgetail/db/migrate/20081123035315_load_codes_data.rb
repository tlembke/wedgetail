class LoadCodesData < ActiveRecord::Migration
  def self.up
    down
    Dir.glob(File.join(File.dirname(__FILE__), "codes_data/*.yml")) do |fname|
      File.open(fname) do |f| 
        YAML.load_documents(f) do |value| 
          Code.class_by_code(value["code"]).new(value).save!
        end
      end
    end
  end

  def self.down
    Code.delete_all
  end
end

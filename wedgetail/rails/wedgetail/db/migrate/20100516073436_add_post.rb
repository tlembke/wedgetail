class AddPost < ActiveRecord::Migration
      def self.up
         NarrativeType.create(:id=>'17',:narrative_type_name=>'Post')
      end

      def self.down
        NarrativeType.delete(:id=>'17')
      end
  end

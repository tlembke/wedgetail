class Code < ActiveRecord::Base
  serialize :values
  belongs_to :sub_narrative

  def javascript_line
    return "{typ:\"#{typ}\",name:\"#{name}\"}"
  end


  def self.load_codes
    print "deleting codes\n"
    Code.delete_all
    Dir.glob(File.join(File.dirname(__FILE__), "../../db/migrate/codes_data/*.yml")) do |fname|
      File.open(fname) do |f|
        fname = File.basename(fname)
        print "loading #{fname}\n"
        Code.update_all("deleted = (1=1)") 
        YAML.load_documents(f) do |value| 
          exists = false
          Code.find_all_by_code(value['code']) do |code|
            code.deleted = false
            exists = true
            value.each_pair do |k,v|
              code.values[k] = v unless k  == 'name' or k == 'code' or k == 'typ'
            end
            code.save!
          end
          unless exists
            c = value.delete('code')
            n = value.delete('name')
            t = value.delete('typ')
            Code.create(:name=>n,:code=>c,:values=>value,:typ=>t,:deleted=>false)
          end
        end
      end
    end
  end


end



class Diagnosis < Code # OID 4,

  def to_html(text,narr)
    "<b>diagnosed:</b> "+name
  end

end

class PathologyRequest < Code # OID 3.1.
end

class ImagingRequest < Code # OID 3.2.
end

# a specific individual
class Referrer < Code # OID 3.3. 
end


# a referral discipline (so we pop up an addressbook selector)
class Referral < Code
end


class Claim < ActiveRecord::Base
    belongs_to :item_number
    
    def self.last_claim(epc,wedgetail)
      @claim=Claim.find(:first,:conditions)
    end
    
    def self.last_claim(epc,wedgetail)
        if @in=ItemNumber.find_by_number(epc)
          last_claim = Claim.find(:first,:conditions=>["wedgetail='#{wedgetail}' and item_number_id='#{@in.id}'"], :order=>'created_at DESC')
          if last_claim == nil
            last_claim=Claim.new(:wedgetail=>wedgetail,:code=>@in.code,:item_number_id=>@in.id,:date=>"0000-00-00")
          end
          return last_claim
        else
          return nil
        end
    end
    
    def self.last_claim_by_code(code,wedgetail)
        last_claim = Claim.find(:first,:conditions=>["wedgetail='#{wedgetail}' and code='#{code}'"], :order=>'created_at DESC')
        if last_claim == nil
          @in=ItemNumber.find_by_code(code)
          if @in != nil
            last_claim=Claim.new(:wedgetail=>wedgetail,:item_number_id=>@in.id,:code=>code,:date=>"0000-00-00")
          else
            last_claim=Claim.new(:wedgetail=>wedgetail,:item_number_id=>0,:code=>code,:date=>"0000-00-00")
          end
        end
        return last_claim
    end
end

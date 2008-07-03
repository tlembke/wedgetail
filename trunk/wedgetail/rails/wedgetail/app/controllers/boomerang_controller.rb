class BoomerangController < ApplicationController
  def create
      if params[:wedgetail]
        @wedgetail=params[:wedgetail]
      else
        @wedgetail=WedgePassword.make("T")
      end
       @gpmp=Claim.last_claim(721,@wedgetail)
       @tca=Claim.last_claim(723,@wedgetail)
       @gpmp_review=Claim.last_claim(725,@wedgetail)
       @tca_review=Claim.last_claim(727,@wedgetail)
       @hmr=Claim.last_claim(713,@wedgetail)
       @annual_check=Claim.last_claim_by_code("check",@wedgetail)
       @sipp=Claim.last_claim_by_code("sipp",@wedgetail)
       @claims=[@gpmp,@tca,@gpmp_review,@tca_review,@sipp,@annual_check,@hmr]
       coc()
       # need to sort out cycle based on history
       
       # step one - is patient due for a GPMP
  end
  
  def get_claims(wedgetail)
    @gpmp=Claim.last_claim(721,wedgetail)
    @last_claims=[@gpmp]
  end
  
  def add_claim
    @claim= Claim.new(params[:newclaim])
    if @claim.save
        render :update do |page|
          page.replace_html @claim.code+'-date',@claim.date.strftime("%d/%m/%y")
          page.replace_html @claim.code, :partial=>'call_update'
        end
    end
  end
  
  
  def update_form
    @newclaim=Claim.last_claim_by_code(params[:code],params[:wedgetail])
    render :partial=>'update_form',  :layout=>false
  end
  
  def toggle_eligibility
    @patient=Patient.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    newValue=0
    newValue=1 if params[:value]=="1"
    value_text="ineligible"
    value_text="eligible" if newValue==1
    @patient.update_attribute(params[:epc], newValue) 
    render :update do |page|
        page.replace_html 'done',params[:epc]+"-"+value_text
      end
  end
  
  def coc
    #business rules
    # if GPMP-eligible, that becomes month 0
    # otherwise, there's not much point.
    
    #go through month by month starting at the last care plan
    if params[:wedgetail]
      @wedgetail=params[:wedgetail]
    end
    @visits=4
    @visits=params[:visits] if params[:visits]
    @interval=12/@visits.to_i
    @scope=12
    @scope=params[:scope].to_i if params[:scope]
    @month_appt=Array.new
    @month_name=Array.new
    j=0
    gpmp_scheduled=""
    tca_scheduled=""
    gpmp_scheduled=""
    tca_scheduled=""
    sipp_scheduled=""
    check_scheduled=""
    hmr_scheduled=""
    
    @session_id=session[:session_id]
    @start_month=Time.now.month
    
    @start_month=params[:date][:month] if params[:date]
    
    @diff = @start_month.to_i - Time.now.month.to_i
    @this_date=Time.now.to_date
    @this_date=@this_date>>@diff

    @last_claims=get_claims(params[:wedegtail])
    
    while j < @scope
      @month_appt[j]=Array.new
      @month_name[j]= @this_date.strftime("%b %y")
      #@month_appt[j]<< "721"
      #@month_appt[j]<< "723"
      
      # find last day of month
      
      
      
      # move to next month
      j=j+@interval
      @this_date=@this_date>>1
    end
    
    
    #render :partial=>'coc'
    # render :update do |page|
    #   page.replace_html 'coc', :partial=>'coc',  :layout=>false
    #end

  end


def epc_due(code,month,scheduled)
  # use 
  last_claimed=@patient.last_claim_by_code(code)
end
  
def gpmp_due(start,month)
  @gpmp-last=@patient.last_claim(721)
  
end
      
    


end

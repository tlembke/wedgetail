class PatientsController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "patients"
  
  # GET /patients
  # GET /patients.xml
  def index
    authorize :user
    if params[:wedgetail] and params[:wedgetail]!=""
      @patients = User.find(:all,:order => "created_at DESC",:conditions => ["role=5 and wedgetail=?",params[:wedgetail]])
    else
      @patients = @user.find_authorised_patients(params[:family_name],params[:given_names],params[:dob])
    end
    if @patients.length==0 and (params[:family_name] or params[:given_names])
      flash[:notice]='Patient not found'
    else
      if flash[:notice]=='Patient not found'
        flash.delete(:notice)
      end
    end
    respond_to do |format|
      format.html {render :layout=>'layouts/standard'}
      format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      format.xml { render :xml => @patients, :template => 'patients/patients.xml.builder' }
      format.text { render_text_data(@patients,[:wedgetail,:family_name,:given_names,:known_as,:dob,:sex,:address_line,:town,:postcode,:medicare]) }
    end
  end

  # GET /patients/1
  # GET /patients/1.xml

  
  def show
    # no way for map.resources to use other than :id, which we don't want
    params[:wedgetail]=params[:id]
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    
      
      if !@patient or @patient.role!=5
        flash[:notice]='Patient not found'
      elsif !@patient.hatched 
        flash[:notice]='Patient not yet registered'
      else
        authorize_only(:patient) {@patient.wedgetail == @user.wedgetail}
        authorize_only(:temp) { @patient.wedgetail == @user.wedgetail.from(6)}
        authorize_only(:leader){@patient.firewall(@user)}
        authorize_only(:user){@patient.firewall(@user)}
        authorize :admin
        @narratives=Narrative.find(:all, :conditions=>["narrative_type_id IS NOT NULL and wedgetail=?",params[:wedgetail]], :order=>"created_at DESC")
        @audit=Audit.create(:patient=>params[:wedgetail],:user_wedgetail=>@user.wedgetail)
        @special=Array.new
        @count=Array.new
        @displayOrder=[1,2,5,3,4,8,9,6]
        j=1
        for i in @displayOrder
          @special[j]=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=?",params[:wedgetail],i], :order=>"narrative_date DESC,created_at DESC") 
          @count[i]= Narrative.count(:all,:conditions=>["wedgetail='#{params[:wedgetail]}' and narrative_type_id='#{i}'"])
          j=j+1
        end
      end
     
    respond_to do |format|
      format.html{
        if !@patient or @patient.role!=5
          redirect_to :action=>:index
        elsif ! @patient.hatched
          render :action=>:unconfirmed
        end
      }
      format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      format.xml  { render :xml => @patient }
    end
  end
  
  #display narrative


  # GET /patients/new
  # GET /patients/new.xml
  def new

    authorize :user
    @patient = User.new
    respond_to do |format|
      format.html {render :layout=>'layouts/standard'} # new.html.erb
      format.xml  { render :xml => @patient }
    end
  end

  # GET /patients/1/edit
  def edit
    w = params[:wedgetail]
    authorize_only (:patient) {w == @user.wedgetail}
    authorize_only (:temp) {w == @user.wedgetail.from(6)}
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC") 
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
    render :layout=>'layouts/standard'
  end
  


  # POST /patients
  # POST /patients.xml
  def create
      authorize :user
      # have to delete localID attribute as it is not in Users model
      # and will generate an unknow attribute error
      failflag=""
      force=""
      
      # first check to see if 'force' in place
      if params[:patient][:force] and params[:patient][:force]=="true"
        force="true"
        params[:patient].delete("force")
      end
        
      # see if patient with that localID has already been created by this user
      if params[:patient][:localID]
        @localID=params[:patient][:localID]
        params[:patient].delete("localID")
        if @localmap=Localmap.get(@user,@localID)
          #patient with that localID already exists - don't create
          failflag="Error 01: Patient with that localID already created"
          @patient=User.find_by_wedgetail(@localmap.wedgetail)
          @patients=[@patient]
        end
      end
          # see if that patient already has a wedgetail record, unless force is true
      unless force=="true"
          if failflag==""
            conditions="family_name=? and dob=?",params[:patient][:family_name],params[:patient][:dob]
            @patients=User.find(:all,:conditions=>conditions,:order=>'created_at DESC')
            if @patients.length>0
                failflag="Error 02: Patient possibly already created"
            end
          end
      end
      
      if failflag==""
        @patient = User.new(params[:patient])
        if params[:ihi] and params[:ihi]!=""
          @patient.wedgetail=params[:ihi]
        else
          # generate temporary wedgetail number
          wedgetail_number=WedgePassword.make("H")
          @patient.wedgetail=wedgetail_number
        end
        @patient.username = @patient.wedgetail
        @patient.role=5
        @patient.hatched=false
        @patient.hatched=true if request.host.starts_with?("demo")
        @patient.created_by=@user.wedgetail
      end

      respond_to do |format|
        if failflag=="" and @patient.save
          
          if @localID
            @team=@user.wedgetail
            @team=@user.team if @user.team and @user.team !="" and @user.team !='0'
            Localmap.create(:team=>@team,:localID=>@localID,:wedgetail=>@patient.wedgetail)
          end
          
          format.html { 
            flash[:notice] = 'Patient was successfully created.'
            redirect_to patient_url(@patient.wedgetail)
          }
          format.xml  { 
            @message="Patient Created"
            @patients=[@patient]
            render :xml => @patients, :template => 'patients/patients.xml.builder', :status => :created 
          }
          format.text { render_text_ok } 
        else
          if failflag==""
            failflag=@patient.errors.each_full {|msg| p msg}
          end
          format.html { render :action => :new,:layout=>'layouts/standard'}
          format.xml {
            @message=failflag
            logger.error failflag
            # used to send :status => :unprocessable_entity but this returns a 422 error 
            # which causes .NET to throw an exception
            render :xml => @patients, :template => 'patients/patients.xml.builder' #,:status => :unprocessable_entity 
          }
          format.text { render_text_error(failflag) }
        end # if
      end # respond_to
  end # def

  # PUT /patients/1
  # PUT /patients/1.xml
  
  def update
    w = params[:patient][:wedgetail]
    authorize_only (:patient) {w == @user.wedgetail}
    authorize_only (:temp) {w == @user.wedgetail.from(6)}
    @patient=User.find_by_wedgetail(w,:order =>"created_at DESC") 
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
 
    @patient.update_attributes(params[:patient])
    if @patient.save
      flash[:notice] = 'Patient was successfully updated.'
      redirect_to :action => 'show', :id => @patient.wedgetail
    else
      if @patient.dob.blank?
        @patient.dob = @patient.dob_was 
      end
      render :action => 'edit'
    end
  end


#  GET patients/1/results
def results
  # no way for map.resources to use other than :id, which we don't want
  params[:wedgetail]=params[:id]
  @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
  
    
    if !@patient or @patient.role!=5
      flash[:notice]='Patient not found'
    elsif !@patient.hatched 
      flash[:notice]='Patient not yet registered'
    else
      authorize_only(:patient) {@patient.wedgetail == @user.wedgetail}
      authorize_only(:temp) { @patient.wedgetail == @user.wedgetail.from(6)}
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
      @actions=Action.find(:all, :conditions=>["wedgetail=?",params[:wedgetail]], :order=>"created_at DESC")
    end
   
  respond_to do |format|
    format.html{
      if !@patient or @patient.role!=5
        redirect_to :action=>:index
      elsif ! @patient.hatched
        render :action=>:unconfirmed
      else
        render :action=>:results
      end
    }
    format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
    format.xml  { render :xml => @patient }
  end
end

  
  def search 
    @patients = @user.find_authorised_patients(params[:family_name],params[:given_names],params[:dob])  
    respond_to do |format|
      format.html # search.html.erb 
      format.xml { render :xml => @patients, :template => 'patients/patients.xml.builder' }
      format.text { render_text_data(@patients,[:wedgetail,:family_name,:given_names,:known_as,:dob,:sex,:address_line,:town,:postcode,:medicare]) }
    end 
  end

  # show all users who access a patient's information
  def audit
     @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
     authorize_only (:patient) {@patient.wedgetail == @user.wedgetail}
     authorize :user
     @audits = Audit.paginate(:page => params[:page],:per_page => 60, :order => 'created_at DESC', :conditions => ["patient=?", params[:wedgetail]])
  end

        # if a user has registered an interest in a patient, they will receive a copy of all new narratives
   def register
       wedgetail = params[:wedgetail]
       @interest=Interest.create(:patient => wedgetail, :user =>@user.wedgetail)
       text=<<EOF
<a href="#" onclick="new Ajax.Request('/patients/unregister/#{wedgetail}', 
{asynchronous:true, evalScripts:true}); return false;">
<img alt="Internet-news-reader" border="0" id="internet-news-reader" src="/images/icons/tango/large/internet-news-reader.png" valign="middle" />
<script>new Tip("internet-news-reader",
"You have been registered to receive HL7 updates on this patient. Click to unregister",{title:'Thanks for registering'});
</script></a>
EOF
            render :update do |page|
                page.replace_html "register",text
            end
     end
     
def unregister
     wedgetail = params[:wedgetail]
     Interest.delete_all(["patient = '#{wedgetail}' and user='#{@user.wedgetail}'"])
     text=<<EOF
<a href="#" 
onclick="new Ajax.Request('/patients/register/#{wedgetail}', {asynchronous:true, evalScripts:true}); return false;">
<img alt="Internet-news-reader-x" border="0" id="internet-news-reader-x" src="/images/icons/tango/large/internet-news-reader-x.png" valign="middle" />
<script>new Tip("internet-news-reader-x",
"You have been unregistered from receiving updates about this patient. Click to re-register.",{title:'Thanks for unregistering'});
</script></a>
EOF
     render :update do |page|
     page.replace_html "register", text
      end
end 

  # guests have one time read only access to a particular patient
  def guests
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    if params[:commit]=="Save changes"
      @thisguest=User.find_by_username(params[:user][:username])
      @thisguest.update_attributes(:family_name=>params[:user][:family_name],:given_names=>params[:user][:given_names])
    end 
    @guests=User.find(:all,:conditions=>["wedgetail LIKE ? and wedgetail !=?","%"+ params[:wedgetail],params[:wedgetail]])
  end

  # generates the consent for new patients, text found in /public/consent.txt
  def consent
    send_data(gen_pdf(params[:wedgetail]), :filename => "consent.pdf", :type => "application/pdf")
  end

  def gen_pdf(wedgetail)
    patient=User.find_by_wedgetail(wedgetail,:order =>"created_at DESC")
    patient_name=patient.full_name
    patient_text="DOB - "+patient.dob.day.to_s + "/" + patient.dob.month.to_s + "/" + patient.dob.year.to_s + "\n"
    patient_text+= patient.address_line + "\n" + patient.town+"\n"
    patient_text+= "Wedgetail: "+wedgetail
    patient_address=patient.address_line + ", " + patient.town
    patient_dob=patient.dob.day.to_s + "/" + patient.dob.month.to_s + "/" + patient.dob.year.to_s
    consent_text= IO.read(RAILS_ROOT + "/public/consent.txt") 
    consent_text=consent_text.sub("<patient_full_name>",patient_name)
    consent_text=consent_text.sub("<patient_address>",patient_address)
    consent_text=consent_text.sub("<patient_dob>",patient_dob)
    consent_text=consent_text.sub("<wedgetail_number>",wedgetail)

    pdf=FPDF.new
    pdf.AddPage
    pdf.SetFont('Arial','B',16)
    #a0aeb9
    pdf.SetFillColor(160,174,185)
    pdf.Image(RAILS_ROOT + '/public/images/wedgetail_vert_250.jpg', 10, 8, 50)

    pdf.SetX(55)
    pdf.Cell(100,10,'Patient Consent Form',0 ,1,'C');

    pdf.SetY(20)


    pdf.SetFont('Arial','B',16)
    pdf.SetX(75)
    pdf.MultiCell(100,7,patient_name,0,'R');
    pdf.SetX(75)
    pdf.SetFont('Arial','',10)
    pdf.MultiCell(100,5,patient_text,0,'R');
    pdf.Write(5,consent_text)
    pdf.SetX(25)
    pdf.SetY(-60)        
    pdf.MultiCell(100,7,"Sign...................................................\nName: "+patient_name+"\n\nDate.............",0,"L")
    pdf.SetLeftMargin(100)
    pdf.SetY(-60)
    pdf.MultiCell(200,7,"Witness...............................................\nName:..................................................\nPosition................................................\nDate........................................",0,"L")


    pdf.Output 
  end
end

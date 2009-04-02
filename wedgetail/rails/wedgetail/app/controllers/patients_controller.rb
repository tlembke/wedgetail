class PatientsController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "standard"
  
  # GET /patients
  # GET /patients.xml
  def index
    authorize :user
    @patients = @user.find_authorised_patients(params[:family_name],params[:given_names],params[:dob])  
    respond_to do |format|
      format.html {render :layout=>'layouts/standard'}
      format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      format.xml { render :xml => @patients, :template => 'patients/patients.xml.builder' }
    end
  end

  # GET /patients/1
  # GET /patients/1.xml

  
  def show
    # no way for map.resources to use other than :id, which we don't want
    params[:wedgetail]=params[:id]
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    
      
      if @patient.role!=5
        redirect_to :action => :list
      end
      if !@patient
        flash[:notice]='Patient not found'
        redirect_to :action => :list
      elsif not @patient.hatched 
        flash[:notice]='Patient not yet registered'
        render(:action=> :unconfirmed)
      else
        authorize_only(:patient) {@patient.wedgetail == @user.wedgetail}
        authorize_only(:temp) { @patient.wedgetail == @user.wedgetail.from(6)}
        authorize_only(:leader){@patient.firewall(@user)}
        authorize_only(:user){@patient.firewall(@user)}
        authorize :admin
        @narratives=Narrative.find(:all, :conditions=>["wedgetail=?",params[:wedgetail]], :order=>"created_at DESC")
        @audit=Audit.create(:patient=>params[:wedgetail],:user_wedgetail=>@user.wedgetail)
        @special=Array.new
        @count=Array.new
        @displayOrder=[1,2,5,3,4,8,7,9,6]
        j=1
        for i in @displayOrder
          @special[j]=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=?",params[:wedgetail],i], :order=>"narrative_date DESC,created_at DESC") 
          @count[i]= Narrative.count(:all,:conditions=>["wedgetail='#{params[:wedgetail]}' and narrative_type_id='#{i}'"])
          j=j+1
        end
      end
     
    respond_to do |format|
      format.html
      format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      format.xml  { render :xml => @patient }
    end
  end

  # GET /patients/new
  # GET /patients/new.xml
  def new
    @patient = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @patient }
    end
  end

  # GET /patients/1/edit
  def edit
    @patient = Patient.find(params[:id])
  end

  # POST /patients
  # POST /patients.xml
  def create
      authorize :user
      @patient = User.new(params[:patient])
      # generate temporary wedgetail number
      wedgetail_number=WedgePassword.make("H")
      @patient.wedgetail=wedgetail_number
      @patient.username = @patient.wedgetail
      @patient.role=5
      @patient.hatched=false
      @patient.created_by=@user.wedgetail

      respond_to do |format|
        if @patient.save
          flash[:notice] = 'Patient was successfully created.'
          format.html { redirect_to :action => :show, :wedgetail => @patient.wedgetail}
          format.xml  { render :xml => @patient.wedgetail, :status => :created }
        else
          format.html { render :action => :new,:layout=>'layouts/standard'}
          format.xml  { render :xml => @patient.errors, :status => :unprocessable_entity }
        end
      end
  end

  # PUT /patients/1
  # PUT /patients/1.xml
  def update
    @patient = Patient.find(params[:id])

    respond_to do |format|
      if @patient.update_attributes(params[:patient])
        flash[:notice] = 'Patient was successfully updated.'
        format.html { redirect_to(@patient) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @patient.errors, :status => :unprocessable_entity }
      end
    end
  end


  
  def search 
    @patients = @user.find_authorised_patients(params[:family_name],params[:given_names],params[:dob])  
    respond_to do |format|
      format.html # search.html.erb 
      format.xml { render :xml => @patients, :template => 'patients/patients.xml.builder' }
    end 
  end
end

class LocalmapsController < ApplicationController
  before_filter :redirect_to_ssl
  before_filter :authenticate, :except =>[:logincheck]
  
  # GET /localmaps
  # GET /localmaps.xml
  def index
    authorize :user
    if @localmap=Localmap.get(@user,params[:localID])
      @message="Found"
    else
      @message="Not found"
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @localmap,:template => 'localmaps/localmap.xml.builder' }
    end
  end
  


  # GET /localmaps/1
  # GET /localmaps/1.xml
  def show
    @localmap = Localmap.find(params[:id])


    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @localmap }
    end
  end

  # GET /localmaps/new
  # GET /localmaps/new.xml
  def new
    @localmap = Localmap.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @localmap }
    end
  end

  # GET /localmaps/1/edit
  def edit
    @localmap = Localmap.find(params[:id])
  end

  # POST /localmaps
  # POST /localmaps.xml
  def create
    authorize :user
    failflag=""
    #does that user already have a map to that wedgetail
    if @localmap=Localmap.checkWedge(@user,params[:localmap][:wedgetail])
      if @localmap.localID != params[:localmap][:localID]
          failflag="Error 1: That wedgetail number is already mapped to another localID"
      else
          failflag="Error 0: That mapping already exists"
      end
    end
    
    #does that user already have that localID mapped to a different patient
    if failflag=="" and @localmap=Localmap.get(@user,params[:localmap][:localID])
      if @localmap.wedgetail != params[:localmap][:wedgetail]
          failflag="Error 2: That localID is already mapped to another wedgetail number"
      end
    else
      # all seems OK
      @team=@user.wedgetail
      @team=@user.team if @user.team !="" and @user.team !='0' and @user.team !=NULL
      @localmap=Localmap.create(:team=>@team,:localID=>params[:localmap][:localID],:wedgetail=>params[:localmap][:wedgetail])
    end
    
    respond_to do |format|
      format.xml{
        if failflag==""
          if @localmap.save
            @message="Localmap created"
            render :xml => @localmap, :template => 'localmaps/localmap.xml.builder',:status => :created
          else
            render :xml => @localmap.errors, :status => :unprocessable_entity 
          end
        else
          @message=failflag
          render :xml => @localmap, :template => 'localmaps/localmap.xml.builder',:status => :unprocessable_entity
        end
      } 
    end
  end

  # PUT /localmaps/1
  # PUT /localmaps/1.xml
  def update
    @localmap = Localmap.find(params[:id])

    respond_to do |format|
      if @localmap.update_attributes(params[:localmap])
        flash[:notice] = 'Localmap was successfully updated.'
        format.html { redirect_to(@localmap) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @localmap.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /localmaps/1
  # DELETE /localmaps/1.xml
  def destroy
    @localmap = Localmap.find(params[:id])
    @localmap.destroy

    respond_to do |format|
      format.html { redirect_to(localmaps_url) }
      format.xml  { head :ok }
    end
  end
  
  def logincheck
      user = authenticate_with_http_basic do |login, password| 
          User.authenticate(login, password) 
        end 
        if user 
          @message="Authentication correct"
        else 
          @message="Authentication failed"
        end 
        render :xml => @message

  end
end

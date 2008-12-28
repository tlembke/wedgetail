# for creating narratives
class EntryController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "record"


  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create ],
         :redirect_to => { :action => :list }


  def new
    authorize :user
    # if narrative has value, then starting values from previous entry
    if(params[:narrative])
      @narrative = Narrative.find(params[:narrative])
      if(@narrative.wedgetail!=params[:wedgetail])
        # wrong patient for narrative after all. Start from blank
        @narrative=Narrative.new
      end
    else  
      @narrative = Narrative.new
    end
    @narrative.wedgetail=params[:wedgetail]
    @narrative_type=NarrativeType.find(:all, :order => "narrative_type_name")
  end

  def create
    authorize :user
    begin
      @narrative = Narrative.new(params[:narrative])
      @narrative.created_by=@user.wedgetail
    
      upload_ok=true
      if params[:narrative][:uploaded_narrative]!=""
        file = params[:narrative][:uploaded_narrative]
        content_type=file.content_type.chomp
        if content_type!="text/plain"
          flash[:notice] = 'Sorry, only plain text files currently supported'
          upload_ok=false
        end
      end
      if upload_ok and @narrative.save
        @narrative.sendout
        flash[:notice] = 'Narrative was successfully created.'
        redirect_to :controller => 'record', :action => 'show', :wedgetail => @narrative.wedgetail
      else
        redirect_to :action => 'new',:wedgetail=> @narrative.wedgetail
      end
    rescue WedgieError
      flash[:notice] = $!.to_s
      redirect_to :action => 'new',:wedgetail=> params[:narrative][:wedgetail]
    end
  end

  
  def upload
    authorize :user
    mp = nil
    if params.has_key? :upload
      file = params[:upload][:file]
      if file.respond_to? :original_filename
        begin
          file_content = file.read
          content_type=MessageProcessor.detect_type(file_content,file.content_type.chomp,file.original_filename)
          raise WedgieError,'unrecognised file type' if content_type.nil?
          mp = MessageProcessor.new(logger,session[:user_id],file_content,content_type,nil)
          mp.save
        rescue WedgieError
          flash[:notice] = $!.to_s
        else
          flash[:notice] = mp.status
        end
      elsif not params[:upload][:text].blank?
        begin
          mp = MessageProcessor.new(logger,session[:user_id],params[:upload][:text],'text/plain',nil)
          mp.save
        rescue WedgieError
          flash[:notice] = $!.to_s
        else
          flash[:notice] = mp.status
        end
      else
        flash[:notice] = "No file uploaded"
      end
      if mp and mp.status == "new patient created"
        redirect_to :controller=>:record,:action=>:show,:wedgetail=>mp.wedgetail
      end
    end
  end

end

class MessagesController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "standard"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  #verify :method => :post, :only => [ :destroy, :create, :update ],
  #     :redirect_to => { :action => :list }


# GET /patients
# GET /patients.xml
  def index
    respond_to do |format|
      format.xml{
        render :xml => @user.inbox
      }
      format.html
    end
  end
  
  def count
    render :xml => @user.inbox.size
  end
  
  def mark_as_read
      @message=Message.find(params[:id])
      @message.update_attribute(:status,1)
      render :update do |page|
          page.replace_html('message_count',"You have "+pluralize(@user.inbox.size, "unread message"))
          page.visual_effect :toggle_blind, "message_"+@message.id.to_s
          page.replace_html('sb_message_count',@user.inbox.size)
          page.visual_effect :highlight,'sb_message_count'
      end

  end
  
  # toggle message content display
  def toggle
    @message=Message.find(params[:id])
    render :update do |page|
      page.visual_effect :toggle_blind, "message_content_"+@message.id.to_s    
    end
  end
 
  # new message to patient
  def new_message_patient
    @message=Message.find(params[:id])
    render :update do |page|
      page.visual_effect :toggle_blind, "new_message_patient"    
    end
  end 

  def show
    @message = Message.find(params[:id])
    authorize_only (:patient) {@user.wedgetail == @message.recipient_id}
    authorize :user
  end
  
  # show out box
  def out
    if(params[:find]=='unread')
     @messages= Message.paginate :page => params[:page], :per_page=>10, :conditions=>["sender_id=? and status=0",@user.wedgetail]
    else
      @messages= Message.paginate :page => params[:page], :per_page=>10, :conditions=>["sender_id=?",@user.wedgetail]
    end
  end
  
  def archive
    if @user.team
        @messages= Message.paginate :page => params[:page],:per_page=>10, :conditions=>["(recipient_id='#{@user.wedgetail}' or recipient_id='#{@user.team}')"]
    else
        @messages= Message.paginate :page => params[:page],:per_page=>10, :conditions=>["recipient_id='#{@user.wedgetail}'"]
    end
  end
  
  def new
    @message = Message.new
    @recipient=User.find_by_wedgetail(params[:id],:order=>"created_at desc") if params[:id]
    if(params[:re_id])
      @message.re=params[:re_id]
      @re=User.find_by_wedgetail(params[:re_id],:order =>"created_at DESC");
    end
    if(params[:thread])
      @oldMessage=Message.find(params[:thread])
      if @oldMessage.subject.starts_with?(["re:","Re:","re ","Re "])
        @message.subject=@oldMessage.subject
      else
        @message.subject="re: "+@oldMessage.subject
      end
      @message.thread=@oldMessage.thread
    end
    session[:return]=params[:return]
  end

  # POST /messages
  # POST /messages.xml

  def create
    failflag=""
    if params[:message][:re] and params[:message][:re]!=""
      re=User.find_by_wedgetail(params[:message][:re])
      unless re
            failflag="Error 1: No matching patient for "+params[:message][:re]
      end
    
    elsif params[:message][:re_localID]
      @re_localID=params[:message][:re_localID]
      
        #wedgetail of re patient not specified so need to find
        if @localmap=Localmap.get(@user,@re_localID)
          #patient with that localID exists - good.Get wedgetail
          params[:message][:re]=@localmap.wedgetail
        else
          # no localmap so can't create narrative
          failflag="Error 2: No map for specified re_localID "+@localID
        end
    end
    params[:message].delete("re_localID")
 
    if params[:message][:recipient_id] and params[:message][:recipient_id]!=""
      recipient=User.find_by_wedgetail(params[:message][:recipient_id])
      unless recipient
            failflag="Error 3: No matching recipient for wedgetail "+params[:message][:recipient_id]
      end
    
    elsif params[:message][:localID]
      @localID=params[:message][:localID]
      
        #wedgetail of recipient not specified so need to find
        if @localmap=Localmap.get(@user,@localID)
          #recipient with that localID exists - good.Get wedgetail
          params[:message][:recipient_id]=@localmap.wedgetail
        else
          # no localmap so can't create narrative
          failflag="Error 4: No map for specified localID "+@localID
        end
    end
    params[:message].delete("localID")
 

    @message = Message.new(params[:message])
    @message.sender_id=@user.wedgetail
    
    @message.status=0
    if @message.thread=="" or ! @message.thread
      @message.thread=@message.id
    end
    respond_to do |format|
      if failflag=="" and @message.save
        @message.update_attribute('thread',@message.id)
        notice='Message was successfully created.'
      
        if @message.recipient.email.to_s != ""
          begin
            @email=WedgeMailer.deliver_notify(@message.recipient)
            notice+=" Email notification sent."
          rescue
            notice+=" Email notification not successfully sent."
          end
        
        end
      
        format.html { 
          flash[:notice] = notice

          if session[:return]=="patient"
            redirect_to :controller=>"patients",:action => 'show',:id=>@message.recipient_id
          elsif session[:return]=="patient_user"
            redirect_to :controller=>"patients",:action => 'show',:id=>@message.re
          else
            redirect_to :action => 'index'
          end
        }
        format.xml{
          @notice=notice
          render :xml => @notice, :status => :created
        }
      else
        format.html {
          flash[:notice]=failflag unless failflag==""
          render :action => 'new'
        }
        format.xml  {
          if failflag
            @notice=failflag
          else
             @notice=@message.errors
          end
          render :xml => @notice,:status => :unprocessable_entity 
        }
      end  #if message save
    end  # format
  end

  # for test purposes
  def emailtest
      recipient=User.find_by_wedgetail(params[:id])
      @email=WedgeMailer.deliver_notify(recipient)
      @local= local_request?
      @sslyn = @request.ssl?
  end
  
  def update
    @message = Message.find(params[:id])
    @message.status=0
    @message.sender_id=@user.id
    if @message.update_attributes(params[:message])
      flash[:notice] = 'Message was successfully updated.'
      redirect_to :action => 'show', :id => @message
    else
      render :action => 'edit'
    end
  end

  def destroy
    Message.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def new_ajax
    @message = Message.new
    session[:return]=nil
    if(params[:id])
      @oldMessage=Message.find(params[:id])
      @recipient_user=User.find_by_wedgetail(@oldMessage.sender_id)
      if @oldMessage.subject.starts_with?("re:")
        @message.subject=@oldMessage.subject
      else
        @message.subject="re: "+@oldMessage.subject
      end
      @message.thread=@oldMessage.thread
    end
    render :partial=>'new_ajax',  :layout=>false
  end
  

  
end

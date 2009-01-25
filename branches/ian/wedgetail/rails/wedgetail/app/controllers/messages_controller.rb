class MessagesController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "standard"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def mark_as_read
      @message=Message.find(params[:id])
      @message.update_attribute(:status,1)
      render :update do |page|
          page.replace_html('message_count',"You have "+pluralize(@user.inbox.size, "unread message"))
          page.visual_effect :toggle_blind, "message_"+@message.id.to_s
          page.replace_html('sb_message_count',pluralize(@user.inbox.size, "message"))
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
    if(params[:id])
      @recipient_user=User.find_by_wedgetail(params[:id])
    end
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

  def create
    @message = Message.new(params[:message])
    @message.sender_id=@user.wedgetail
    
    @message.status=0
    if @message.thread=="" or ! @message.thread
      @message.thread=@message.id
    end
    if @message.save
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
      
      flash[:notice] = notice
      if session[:return]=="patient"
        redirect_to :controller=>"record",:action => 'show',:wedgetail=>@message.recipient_id
      elsif session[:return]=="patient_user"
        redirect_to :controller=>"record",:action => 'show',:wedgetail=>@message.re
      else
         redirect_to :action => 'index'
      end
    else
      render :action => 'new'
    end
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

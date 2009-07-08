class ResultTicketsController < ApplicationController
  # GET /result_tickets
  # GET /result_tickets.xml
  def index
    @result_tickets = ResultTicket.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @result_tickets }
    end
  end

  # GET /result_tickets/1
  # GET /result_tickets/1.xml
  def show
    @result_ticket = ResultTicket.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @result_ticket }
    end
  end

  # GET /result_tickets/new
  # GET /result_tickets/new.xml
  def new
    @result_ticket = ResultTicket.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @result_ticket }
    end
  end

  # GET /result_tickets/1/edit
  def edit
    @result_ticket = ResultTicket.find(params[:id])
  end

  # POST /result_tickets
  # POST /result_tickets.xml
  def create
   
    @result_ticket = ResultTicket.new(params[:result_ticket])
    old=false
    if @RT=ResultTicket.find(:first,:conditions=>["result_ref=?",@result_ticket.result_ref])
      old=true
      @result_ticket.ticket=@RT.ticket
    end
    if ! @result_ticket.ticket
        finished=1
        while finished!=nil
          @ticket=WedgePassword.random_password(10)
          # see if it is unique - will be not nil
          finished=ResultTicket.find_by_ticket(@ticket)
        end
        @result_ticket.ticket=@ticket
     
    end
   
    respond_to do |format|
      if old or @result_ticket.save
        format.html { redirect_to(@result_ticket) }
        format.xml  { render :xml => @result_ticket, :status => :created, :template => 'result_tickets/result_ticket.xml.builder'}
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @result_ticket.errors, :status => :unprocessable_entity }
        
      end
    end
  end
  
  # POST /result_tickets/check
  # POST /result_tickets/check.xml
  def check
   
    result_ticket_list = params[:result_ticket_list]
    @return_list=[]
    for result_ref in result_ticket_list[:result_ref]
      @return_list << result_ref if ResultTicket.find(:first,:conditions => ["result_ref= ?",result_ref])
    end
    respond_to do |format|

        format.html { render :action => "check" }
        format.xml { render :xml => @return_list, :template => 'result_tickets/results_tickets.xml.builder' }
      
    end
  end

  # PUT /result_tickets/1
  # PUT /result_tickets/1.xml
  def update
    @result_ticket = ResultTicket.find(params[:id])

    respond_to do |format|
      if @result_ticket.update_attributes(params[:result_ticket])
        flash[:notice] = 'ResultTicket was successfully updated.'
        format.html { redirect_to(@result_ticket) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @result_ticket.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /result_tickets/1
  # DELETE /result_tickets/1.xml
  def destroy
    @result_ticket = ResultTicket.find(params[:id])
    @result_ticket.destroy

    respond_to do |format|
      format.html { redirect_to(result_tickets_url) }
      format.xml  { head :ok }
    end
  end
end

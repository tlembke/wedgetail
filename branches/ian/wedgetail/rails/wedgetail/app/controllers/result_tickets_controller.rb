class ResultTicketsController < ApplicationController
  # GET /result_tickets
  # GET /result_tickets.xml


  # GET /result_tickets/1
  # GET /result_tickets/1.xml


  # GET /result_tickets/new
  # GET /result_tickets/new.xml


  # GET /result_tickets/1/edit
  def edit
    @result_ticket = ResultTicket.find(params[:id])
  end

  # POST /result_tickets
  # POST /result_tickets.xml
  def create
   
    @result_ticket = ResultTicket.new(params[:result_ticket])
    old=false
    if @RT=ResultTicket.find(:first,:conditions=>["request_set=?",@result_ticket.request_set])
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
    for request_set in result_ticket_list[:request_set]
      @return_list << request_set if ResultTicket.find(:first,:conditions => ["request_set= ?",request_set])
    end
    respond_to do |format|

        format.html { render :action => "check" }
        format.xml { render :xml => @return_list, :template => 'result_tickets/results_tickets.xml.builder' }
      
    end
  end

  # PUT /result_tickets/1
  # PUT /result_tickets/1.xml


  # DELETE /result_tickets/1
  # DELETE /result_tickets/1.xml

end

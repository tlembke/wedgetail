xml.instruct!
xml.result_ticket{
    xml.result_ref(@result_ticket.request_set)
    xml.ticket(@result_ticket.ticket)
}
xml.instruct!
xml.result_ticket_list{
  for request_set in @return_list
    xml.request_set(request_set)
  end
}
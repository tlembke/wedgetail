xml.instruct!
xml.result_ticket_list{
  for result_ref in @return_list
    xml.result_ref(result_ref)
  end
}
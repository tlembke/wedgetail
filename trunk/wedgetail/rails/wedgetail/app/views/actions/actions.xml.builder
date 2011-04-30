xml.instruct!

xml.actions{
  for @action in @actions
    xml.action do
      xml.action_code(@action[:action_code])
      xml.comment(@action[:comment])
      xml.comment_html(displayComment(@action[:comment]))
      xml.identifier(@action[:identifier])
      xml.last_flag(@action[:last_flag])
      xml.name(@action[:name])
      xml.request_set(@action[:request_set])
      xml.test_date(@action[:test_date])
      xml.wedgetail(@action[:wedgetail])
      xml.created_at(@action[:created_at])
    end
  end
}



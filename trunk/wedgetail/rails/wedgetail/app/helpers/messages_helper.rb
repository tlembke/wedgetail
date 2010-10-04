module MessagesHelper
  def parseMessage_deprecated(message)
    if message.content.include?("{rsvp}") and message.re
      message.content=message.content.sub("{rsvp}",text)
    end
    return message.content
  end
end

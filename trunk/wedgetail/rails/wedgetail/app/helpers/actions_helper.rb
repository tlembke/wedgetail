module ActionsHelper
  def displayComment(comment)
    if comment
      if comment.starts_with?("{\\rtf")
        comment=MessageProcessor.abiwordise("doc.rtf",comment,false)
      end
    end
    return comment 
  end
end

module ActionsHelper
  def displayComment(comment)
    if comment
      if comment.starts_with?("{\\rtf")
        comment=MessageProcessor.abiwordise("doc.rtf",comment,false)
        comment=comment.gsub("background:#000000","background:#FFFFFF")

      end
    end
    return comment 
  end
end

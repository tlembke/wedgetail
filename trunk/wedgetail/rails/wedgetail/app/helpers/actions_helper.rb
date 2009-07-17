module ActionsHelper
  def displayComment(comment)
    if comment
      if comment.starts_with?("{\\rtf")
        comment=MessageProcessor.abiwordise("doc.rtf",comment,false)
        comment["background:#000000"]="background:#FFFFFF"
      end
    end
    return comment 
  end
end

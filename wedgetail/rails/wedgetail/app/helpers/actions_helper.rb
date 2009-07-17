module ActionsHelper
  def displayComment(comment)
    if comment
      if comment.starts_with?("{\\rtf")
        comment=MessageProcessor.abiwordise("doc.rtf",comment,false)
        if comment["background:#000000"]
          comment["background:#000000"] ="background:#FFFFFF"
        end
      end
    end
    return comment 
  end
end

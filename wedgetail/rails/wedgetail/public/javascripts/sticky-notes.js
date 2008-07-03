var nn6;
var x, y;
var dobj;
var zone = Object();
var allNotes;

function initStickyNotes()
{
  nn6=document.getElementById && !document.all;
  isdrag=false;
  zone.left = 10;
  zone.top = 10;
  zone.right = 800;
  zone.bottom = 2500; 
  allNotes = document.createElement("div");
  allNotes.id = "allNotes";
  allNotes.style.left = -10+"px";
  allNotes.style.top = -10+"px";
  allNotes.style.width = 1+"px";
  allNotes.style.height = 1+"px";
  document.body.appendChild(allNotes);
}

function drawNote(header, body, x, y)
{
  var newDiv = document.createElement('div');
  newDiv.className = "draggable";

  newDiv.onselectstart = new Function("return false;");
  newDiv.innerHTML = "<div class=\"dragger\">"+ 
  "<div style=\"position: absolute; left: 0px; top: 0px; width: 180px; height: 20px; padding-top: 2px; padding-left: 10px\">"+header+"</div>"+
  "<div style=\"position: absolute;  left: 180px; top: -1px; width:15px; height:10px; cursor: pointer; font: normal 20px Arial;\" onclick=\"allNotes.removeChild(this.parentNode.parentNode)\" title=\"close\">&#215;</div></div>"+"<div class=\"note\">"+body+"</div>";
  newDiv.style.left = x+"px";
  newDiv.style.top = y+"px";
  document.getElementById("allNotes").appendChild(newDiv);
}


function movemouse(e)
{
  if (isdrag)
  {
    var newLeft = nn6 ? tx + e.clientX - x : tx + event.clientX - x;
    var newTop = nn6 ? ty + e.clientY - y : ty + event.clientY - y;
    if (newLeft>zone.left && newLeft<zone.right && newTop>zone.top && newTop<zone.bottom)
    {
      dobj.style.left = newLeft+"px";
      dobj.style.top  = newTop+"px";
      return false;
    }
  }
}

function selectmouse(e)
{
  var fobj       = nn6 ? e.target : event.srcElement;
  var topelement = nn6 ? "HTML" : "BODY";
  while (fobj.tagName != topelement && fobj.className != "dragger" && (nn6 ? fobj.parentNode.className : fobj.parentElement.className != "draggable"))
  {
    fobj = nn6 ? fobj.parentNode : fobj.parentElement;
  }
  if (fobj.className=="dragger")
  {
    isdrag = true;
    dobj = nn6 ? fobj.parentNode : fobj.parentElement;
    tx = parseInt(dobj.style.left+0,10);
    ty = parseInt(dobj.style.top+0,10);
    x = nn6 ? e.clientX : event.clientX;
    y = nn6 ? e.clientY : event.clientY;
    document.onmousemove=movemouse;
    return false;
  }
}



document.onmousedown=selectmouse;
document.onmouseup=new Function("isdrag=false");


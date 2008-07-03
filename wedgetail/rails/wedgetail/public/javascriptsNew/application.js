/***
 * Excerpted from "Agile Web Development with Rails, 2nd Ed.",
 * published by The Pragmatic Bookshelf.
 * Copyrights apply to this code. It may not be used to create training material, 
 * courses, books, articles, and the like. Contact us if you are in doubt.
 * We make no guarantees that this code is fit for any purpose. 
 * Visit http://www.pragmaticprogrammer.com/titles/rails2 for more book information.
***/
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function set_today(model, atrib)
{
    t3 = document.getElementById(model + '_' + atrib + '_3i');
    var dt = new Date(); 
    t3.selectedIndex = dt.getDate();
	
    t2 = document.getElementById(model + '_' + atrib + '_2i')
    t2.selectedIndex = dt.getMonth() ;
    
    t1 = document.getElementById(model + '_' + atrib + '_1i')

    for (i = 0; i < t1.length; i++)
	       {
	           if (t1.options[i].text == dt.getFullYear())
	           {
	               t1.selectedIndex = i;
	          }
    } 
}



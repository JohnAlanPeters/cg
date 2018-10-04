\ HTTP Server Component - Echo
\ Tom Dixon

\ This just repeats back the request when the url starts with /echo/
\ Usefull for debugging

with httpreq
  : doEcho ( -- flag )  
    url [char] / scan [char] / skip 
    2dup [char] / scan nip - s" ECHO" istr=
    if with dstr 
         reply free cr
         s" <HTML><BODY><PRE>" reply append
         request count reply append
         s" </PRE></BODY></HTML>" reply append
       endwith 200 code ! true
    else false then ;
    
  doURL doEcho http-done
endwith

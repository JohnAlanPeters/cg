\ $ Id: Ed_ImageDc.f,v 1.1 2005/02/01 21:15:56 aws Exp $
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\ 7     Drawing into the Image DC
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: moveto        ( x y -- )    \ Move to the x y position in the editor
                imageDC MoveTo: [ ] ;

: lineto        ( x y -- )
                imageDC LineTo: [ ] ;

: line          ( x1 y1 x2 y2 -- )   \ move the line from xy to x2y2
                2swap moveto lineto ;

: line-color    ( color_object -- )
                ?ColorCheck
                imageDC LineColor: [ ] ;


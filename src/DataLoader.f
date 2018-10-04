\ $Id: DataLoader.f,v 1.1 2011/03/19 23:26:09 rdack Exp $
\ DataLoader.f Created  November 17th, 2002 - 17:47


\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\       The Electric Data
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  Include NPS.F             CR .( NPS     is LOADED )   CR   \ Data
           \ The database of prices and times

.( killed the rest of the data due to lack of space ) cr

  Include COMMON.F          CR .( COMMON  is LOADED )   CR   \ Data
           \ Back tick problem see the file
  Include AMPIER.SEQ        CR .( AMPIER  is LOADED )   CR   \ Data
           \ Prices by the amp
  Include OPEN-1S.SEQ       CR .( OPEN-1S is LOADED )   CR   \ Data
           \ Walls are open-1-side
  Include FISH.SEQ          CR .( FISH    is LOADED )   CR   \ Data
           \ Fish-in-walls
  Include SURFACE.SEQ       CR .( SURFACE is LOADED )   CR   \ Data
           \ Neat-EMT or conduit pipe


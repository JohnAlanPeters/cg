Metal Clad modules                                  09-04-91 AEC
Prices lowered after loosing big house on nob hill  GREEN ST    
Prices lowered a little on the MC wire after talk with Mathew   
AJ says the laber is same as RX but can't use PVC boxes         
The wire costs a lot more                                       
4S-Boxes and rings are required                                 
Have to think about how you route it into the box               
More time to strip it using a special tool                      
Can't jerk it thru the holes                                    
Connectors take more time                                       
Corners are harder                                              
Can't fish it                                                   
Heavier                                                         
                                                                
                                                                
                                                                


\ Loader                                            10-07-89 AL
Elect                                                           
2 load  \ Open-2-MC                                             
3 load  \ Open-1-MC                                             
5 load  \ Fish-MC                                               
\ MC-2x4      Elect OPEN-2-MC  also ;                           
: OPEN-MC     Elect Open-1-MC  also ;                           
\ NEW-MC      Elect Open-1-MC ;                                 
\ MCC               open-1-mc ;                                 
                                                                
\v                                                              
                                                                
cr Beep  .( Redefined romex to MC ) cr                          
: Open-1-side  only forth also Open-1-MC also ;                 
: Open-2-sides only forth also Open-2-MC also ;                 
                                                                


\ Open-2-MC                   08-02-89 AEC          03-04-96 AL
Vocabulary Open-2-MC  \  Metal boxes                            
Open-2-MC      Definitions                                      
: LT                  7.52 w/e  78 c ; \                        
: PL                  7.52 w/e  89 c ; \ 110                    
: SW                  7.52 w/e  89 c ; \                        
: PS                              LT ; \                        
: S3                              LT ; \                        
: S4                  9.52 w/e  89 c ; \                        
: (J)                             PL ; \                        
: Power                           PL ;                          
: Split-wire         2.95 w/e   20 c ; \ Guess                  
: Circuit           17.20 w/e   75 c ;                          
Elect                                                           
                                                                
                                                                


\ Open-1-MC                   08-02-89 AEC          03-03-96 0.0
Vocabulary Open-1-MC                                            
Open-1-MC   Definitions                                         
: LT                  9.96 w/e  88 c ; \                        
: PL                  9.96 w/e  78 c ; \ 110                    
: SW                  7.27 w/e  78 c ; \                        
: PS                              LT ; \                        
: S3                              LT ; \                        
: S4                              LT ; \                        
: (J)                             PL ; \                        
: Power                           PL ;                          
: Split-wire         2.95 w/e   20 c ; \ Guess                  
: Circuit           17.20 w/e   84 c ;                          
: Whip               3.62 w/e   54 c ; \ BelAire                
Elect                                                           
                                                                


| Mod for Metal-MC <<<<<      08-02-89 AEC          12-15-91 AEC
Vocabulary Fish-MC                                              
Fish-MC     Definitions                                         
: LT                  9.96 w/e  95 c ; \                        
: LT-Medium           7.00 w/e  79 c ; \                        
: LT-Easy?            6.00 w/e  57 c ; \  60%                   
: PL                  9.96 w/e  90 c ; \ 110                    
: PL-medium           7.82 w/e  85 c ; \  95                    
: PL-easy?            6.00 w/e  60 c ; \  80                    
: SW                  7.27 w/e  90 c ; \                        
: SW-Medium           7.00 w/e  86 c ; \                        
: SW-Easy?            6.00 w/e  54 c ; \                        
: PS                              LT ;                          
: S3                  9.00 w/e 100 c ; \                        
: (J)                 PL ;                                      
: Power               PL ; Elect                                


\ Loader screen                                       16sep87AEC
Vocabulary (FISH-MC)                                            
(FISH-MC) Definitions                                           
6 7 thru \ then back here                                       
Electric Definitions                                            
: MC-IN-WALL    Elect (FISH-MC)  also  cr  ;                    
: Fish-MC          MC-in-wall ;                                 
: MC-in-walls      MC-in-wall ;                                 
\v                                                              
  WANT FISH-MC  \ calls for Flex                                
  Fish in H-7 then check these                                  
  Double ceiling?  Insulation?                                  
  Spacing more than 6 ft?                                       
  Hight  Ladder required?                                       
                                                                
                                                                


\ FISH-MC                                           12-15-91 AEC
` LT-Hard    996.00 w/c 350 c ; \ Thru joists, no attic         
` LT         996.00 w/c 300 c ; \                               
` LT-Medium  900.00 w/c 200 c ; \                               
` LT-Easy?   900.00 w/c 100 c ;                                 
: PS-Medium  LT-medium        ; \                               
` PS-Easy?   900.00 w/c 100 c ;                                 
: PL-Hard    996.00 w/c 325 c ;                                 
` PL         996.00 w/c 275 c ; \ Rx= 2 hrs by Lani & Fred      
` PL-medium  915.00 w/c 175 c ; \                               
` PL-Easy?   915.00 w/c 100 c ; \                               
: SW         915.00 w/c 275 c ;                                 
: SW-medium  996.00 w/c 175 c ;                                 
: SW-easy?   996.00 w/c 100 c ;                                 
: S3-Medium           lt-medium ;                               
: S3-easy?            lt-easy? ;                                


\ FISH                                              11-27-91 AL
: (J)               LT ;   : (J)-easy  pl-easy? ;               
: S3                LT ;                                        
\ PH                800.00 w/c 100 c ;                          
\ PH-easy?          800.00 w/c  70 c ;                          
: S4                800.00 w/c 350 c ;                          
: Circuit          1400.00 w/c 150 c ;                          
                                                                
                                                                
                                                                
                                                                
                                                                
                                                                
                                                                
                                                                
                                                                


15 MC SW-box Fish            
                15 MC 14/2                     
                 2 MC-CON 1/2                  
                 1 SW-box VB                   
                 1 Device pr                   
                 1 Plate pr                    
                 1 blockage plate-easy         
                 2 blockage fire-block         
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


15 MC SW-box Fish med        
                10 MC 14/2                     
                 2 MC-CON 1/2                  
                 1 SW-box VB                   
                 1 Device pr                   
                 1 Plate pr                    
                 1 blockage plate-easy         
                 1 blockage fire-block         
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


15 MC SW-box new             
                15 MC 14/2                     
                 2 MC-con speed                
                 1 SW-box VB                   
                 1 Device pr                   
                 1 Plate pr                    
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


20 MC SW-box                 
                 1 SW-box vb                   
                20 MC 14/2                     
                 2 MC-CON 1/2                  
                 1 Device pr                   
                 1 Plate pr                    
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


15 MC 4S & ring  ****        
                15 MC 14/2                     
                 2 MC-CON speed                
                 1 4S     VB                   
                 1 4s-1g 1/2                   
                 1 Device pr                   
                 1 Plate pr                    
                                               
Get mc                                         
get 4s-1g                                      
get 4s-box                                     
                                               
                                               
                                               
                                               
                                               


20 MC 4S & ring              
                20 MC 14/2                     
                 2 MC-CON 1/2                  
                 1 SW-box VB                   
                 1 4s-1g 1/2                   
                 1 Device pr                   
                 1 Plate pr                    
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


25 MC 4S & ring              
                25 MC 14/2                     
                 2 MC-CON 1/2                  
                 1 SW-box VB                   
                 1 4s-1g 1/2                   
                 1 Device pr                   
                 1 Plate pr                    
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


MC Whip                      
                6 mc 12/2                      
                2 mc-con 1/2                   
                2 secure tye-wrap              
                2 strap 1/2                    
                1 secure anchor                
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


MC  w/o trim                 
                15 MC 14/2                     
                2 MC-con 1/2                   
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               


Trim only                    
                 1 Device pr                   
                 1 Plate pr                    
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               
                                               



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  PROPRIETARY AND CONFIDENTIAL
;;  SimTiki Simulation
;;  Spring 2017
;;  By Tamra Oyama, Jie Zhou, and Curtis Frifeldt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Add Extensions
extensions [array table]

;; DEFINE BREEDS
breed [staffs staff]
breed [patients patient]
breed [supplies supply]
breed [visitors visitor]
breed [nursingStations nursingStation]
breed [checkPoints checkPoint]



;;location of people will be base on the patch color
staffs-own [location health agent-num]
patients-own [location health agent-num]
nursingStations-own [location health agent-num]
supplies-own [location health agent-num]
visitors-own [location health agent-num]

;; global variables
globals [
  num-staffs
  num-patients
  num-visitors
  num-nursingStations
  num-supplies
  num-checkPoints
  num-interactions
  flag
  infected-counter
  tick-start
  distance-sum
  location-of-contact
  loop-counter
  run-counter
  current_num_infected


  ;;SIR Globals
  num-infections
  ProbabilityOfSpread
  agent-name
  pn ;; patient number
  vn ;; visitor number
  sn ;; staff number
]

to setup
  clear-all
  setup-file ;;set up file that record current simulation data
  setup-layout ;; setup simTiki Rooms
  setup-people ;; populate simTiki Rooms
  setup-SIRModel ;; initialize SIR mode
  set current_num_infected 1
  set infected-counter array:from-list n-values 10 [0]
  set flag array:from-list n-values 99 [0]
  set tick-start array:from-list n-values 99 [0]
  set distance-sum array:from-list n-values 99 [0]
  set location-of-contact array:from-list n-values 99 [0]
  set agent-name array:from-list n-values 10 [0]
  reset-ticks
end

to re-setup
  clear-most
  setup-file ;;set up file that record current simulation data
  setup-layout ;; setup simTiki Rooms
  setup-people ;; populate simTiki Rooms
  setup-SIRModel ;; initialize SIR model
  set infected-counter array:from-list n-values 10 [0]
  set flag array:from-list n-values 99 [0]
  set tick-start array:from-list n-values 99 [0]
  set distance-sum array:from-list n-values 99 [0]
  set location-of-contact array:from-list n-values 99 [0]
  set agent-name array:from-list n-values 10 [0]
  reset-ticks
end

;; clear-all except global
to clear-most
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output
end

to setup-file
  file-open (word "contactTracking" (word run-counter) ".sql")  ;;open new blank file

  ;; print the beginning of MySQL file
  ;; this prints in the text file
  ;;file-print "CREATE DATABASE `tracix`;"
  ;;file-print "USE `tracix`;"
  ;;file-print "DROP TABLE IF EXISTS `tracking`;"
  ;;file-print "CREATE TABLE `tracking` ("
  ;;file-print "`subject` VARCHAR(255) NOT NULL,"
  ;;file-print "`compare` VARCHAR(255) NOT NULL,"
  ;;file-print "`location` VARCHAR(255) NOT NULL,"
  ;;file-print "`distance-average` INT(20) NOT NULL,"
  ;;file-print "`tick-start` INT(20) NOT NULL,"
  ;;file-print "`tick-end` INT(20) NOT NULL,"
  ;;file-print "`duration` INT(20) NOT NULL )"
  ;;file-print "ENGINE = MyISAM;"
  file-print "insert into `tracking`"
  file-print "(`subject`, `compare`, `location`, `distance-average`, `tick-start`, `tick-end`, `duration`)"
  file-Print "values"

  ;; this prints in command center
  ;;print "CREATE DATABASE `tracix`;"
  print "USE `tracix`;"
  print "DROP TABLE IF EXISTS `tracking`;"
  print "CREATE TABLE `tracking` ("
  print "`subject` VARCHAR(255) NOT NULL,"
  print "`compare` VARCHAR(255) NOT NULL,"
  print "`location` VARCHAR(255) NOT NULL,"
  print "`distance-average` INT(20) NOT NULL,"
  print "`tick-start` INT(20) NOT NULL,"
  print "`tick-end` INT(20) NOT NULL,"
  print "`duration` INT(20) NOT NULL )"
  print "ENGINE = MyISAM;"
  print "insert into `tracking`"
  print "(`subject`, `compare`, `location`, `distance-average`, `tick-start`, `tick-end`, `duration`)"
  Print "values"
end


;;;;;;;;;;;;;;;;;;;;;;;
;;;;;CREATE WORLD;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;
to addColor [rightBound leftBound topBound bottomBound roomColor]
  if (pxcor < rightBound) and (pxcor >= leftBound) and (pycor < topBound) and (pycor >= bottomBound) [
    set pcolor roomColor
  ]
end

to setup-layout
  set num-checkPoints 30
  set num-patients 4
  set num-nursingStations 1
  set num-supplies 1
  set num-visitors 1
  set num-staffs 3
  set-default-shape checkPoints "square"
  set-default-shape patients "person"
  set-default-shape nursingStations "circle"
  set-default-shape supplies "box"
  set-default-shape visitors "person student"
  set-default-shape staffs "person doctor"

  ;;sim room 1

    ;;sim room 1
  ;;;;LEVEL 1;;;;;;;;;;;;
  ask patches [addColor -3 -28 23 5 green]
  ;;;;LEVEL 2;;;;;;;;;;;;
  ask patches [addColor -9 -28 5 2 green]

  ;; sim room 2
  ;;;;LEVEL 1;;;;;;;;;;
  ask patches [addColor 28 5 23 5 violet]
  ;;;;LEVEL 2;;;;;;;;;;
  ask patches [addColor 28 11 5 2 violet]
  ;;;;LEVEL 3;;;;;;;;;
  ask patches [addColor 28 11 2 -4 violet]
  ;;;;LEVEL 4;;;;;;;;
  ask patches [addColor 28 7 -4 -14 violet]

  ;; hallway
  ask patches [addColor 11 -28 2 -4 grey]

  ;;isolation room
  ask patches [addColor 3 -1 5 2 brown]

  ;; connections between hallway and rooms
  ask patches [addColor -3 -9 5 2 grey]
  ask patches [addColor 11 5 5 2 grey]
    ;;;;;;;;;;;;;checkpoints #0-27;;;;;;;;;;;;;;

    create-checkPoints num-checkPoints [
      set size 1 ;; size should be 0 when the simulation is finished
      set color red ;; red so we can see it during simulation

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;See attached excel sheet label SimTiki_Checkpoint_Key;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ;;checkpoints for entering and exiting between hallway and rooms (These are way points)


      ask checkPoint 0 [set color yellow setxy -7 5] ;; entrance of sim room 1
      ask checkPoint 1 [set color yellow setxy 8 5] ;; entrance of sim room 2
      ask checkPoint 2 [set color yellow setxy -7 -1] ;; hallway out of sim room 1
      ask checkPoint 3 [set color yellow setxy 8 -1] ;;  hallway out of sim room 2 top doorway
      ask checkPoint 4 [set color yellow setxy .5 3] ;; entrance of isolation room
      ask checkPoint 5 [set color yellow setxy .5 -1] ;; hallway out of isolation room
      ask checkPoint 6 [set color yellow setxy 18 5] ;; center of sim room 2, transition point
      ask checkPoint 7 [set color yellow setxy 8 -5] ;; entrace to sim room 2 bottom doorway

      ;;checkpoints for position of staffs in sim room 1
      ask checkPoint 8 [setxy -26 20] ;; position of staff 1
      ask checkPoint 9 [setxy -19 13] ;; position of staff 2
      ask checkPoint 10 [setxy -11 6] ;; position of staff 2

      ;;checkpoints for position of patient visitations in sim room 2
      ask checkPoint 11 [setxy 5 21] ;; position 1 to visit patient 1
      ask checkPoint 12 [setxy 27 21] ;; position 1 to visit patient 2
      ask checkPoint 13 [setxy 26 22] ;; position 2 to visit patient 2
      ask checkPoint 14 [setxy 26 -14] ;; position 1 to visit patient 3
      ask checkPoint 15 [setxy 27 -13] ;;position 2 to visit patient 3
      ask checkPoint 16 [setxy 7 -13] ;;position 1 to visit patient 3

      ;;checkpoints for position of staff and equipment visitations in sim room 2
      ask checkPoint 17 [setxy 26 3] ;; position 1 to visit supply
      ask checkPoint 18 [setxy 27 2] ;; position 2 to visit supply
      ask checkPoint 19 [setxy 27 4] ;; position 3 to visit supply
      ask checkPoint 20 [setxy 11 -3] ;; position 1 to visit nursing station
      ask checkPoint 21 [setxy 12 -2] ;; position 2 to visit nursing station
      ask checkPoint 22 [setxy 11 -1] ;; position 3 to visit nursing station
      ask checkPoint 23 [setxy 10 8] ;; position 1 to visit nursing station
      ask checkPoint 24 [setxy 8 10] ;; position 2 to visit nursing station
      ask checkPoint 25 [setxy 6 8] ;; position 3 to visit nursing station

      ;;checkpoint for visitor position in hall and room
      ask checkPoint 26 [setxy 8 8] ;; visitor position in sim room 2
      ask checkPoint 27 [setxy 10 -2] ;; visitor position in hallway
      ask checkPoint 28 [set color yellow setxy 11 5] ;; way point between supply and nursing station
      ask checkPoint 29 [set color yellow setxy 11 -5] ;; way point between Patient 4 and nursing station
    ]


end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;POPULATE WORLD;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-people
    set num-interactions 0 ;; initialize number of interactions

    ;; create patients #30-33
    create-patients num-patients [
      set color white ;;color of patients
      ask patient 30 [setxy 5 22 set agent-num 1] ;; setup patient 1
      ask patient 31 [setxy 27 22 set agent-num 2] ;; setup patient 2
      ask patient 32 [setxy 27 -14 set agent-num 3] ;; setup patient 3
      ask patient 33 [setxy 7 -14 set agent-num 4] ;; setup patient 4
      set location pcolor ;; location variable that will be used for tracking
      set health "susceptible" ;; initialize health state
      set pn 4 ;; patient number to increment when an infected patient is replaced
    ]

    ;; create nursingStation #34
    create-nursingStations num-nursingStations [
      set color lime
      ask nursingStation 34 [setxy 11 -2 set agent-num ""] ;;nursingStation never get replaced so agent-sum is NULL
      set location pcolor
      set health "susceptible" ;; initialize health state
    ]

    ;; create supply #35
    create-supplies num-supplies[
      set color yellow
      ask supply 35 [setxy 27 3 set agent-num ""] ;;supply never get replaced so agent-sum is NULL
      set location pcolor
      set health "susceptible" ;; initialize health state
    ]
    ;; create staffs #36-38
    create-staffs num-staffs[
      set color blue
      ask staff 36 [setxy -26 20 set agent-num 1] ;; staff 1
      ask staff 37 [setxy -19 13 set agent-num 2] ;; staff 2
      ask staff 38 [setxy -11 6 set agent-num 3] ;; staff 3
      set location pcolor
      set health "susceptible" ;; initialize health state
      set sn 3 ;; staff number to increment when an infected staff is replaced
    ]

    ;; create visitor #39
    create-visitors num-visitors[
      set color green
      ask visitor 39 [setxy 10 -2 set agent-num 1] ;; visitor 1
      set location pcolor
      set health "susceptible" ;; initialize health state
      set vn 1 ;; visitor number to increment when an infected visitor is replaced
    ]
end

to setup-SIRModel
  ask turtle infection-source [set health "infectious"] ;; initialize the infection source
                                                        ;; NOTE: infection-source takes number input and
                                                        ;; cannot be higher than the highest turtle number
  set num-infections 1 ;; initialize number of infections
end


to go
tick
ask checkPoints[set size 0] ;; makes checkpoints invisible
;; loop counter
if (ticks = 7184) [
  set loop-counter loop-counter + 1
  reset-ticks ;; reset tick so the script can be executed again
  ]
;; end of simulation
if (run-counter = number-of-runs)[
  file-close
  file-open "MonteCarloResult" ;; second file for total number of infected
  file-type "Run Number: " file-type run-counter
  file-type " Number of Total Infection: " file-print num-infections
  file-close-all
  stop]
;; close file savely at the end of simulation so no loss data
;; run counter
if (loop-counter = number-of-loops or current_num_infected = 0)[
  file-close
  file-open "MonteCarloResult" ;; second file for total number of infected
  file-type "Run Number: " file-type run-counter
  file-type " Number of Total Infection: " file-print num-infections
  file-close-all
  set run-counter run-counter + 1
  set loop-counter 0
  if (run-counter = number-of-runs)[
    file-close-all
    stop]
  re-setup
  ]


mission1 ;; mission 1 for staff 1 (turtle #36)
mission2 ;; mission 2 for staff 2 (turtle #37)
mission3 ;; mission 3 for staff 3 (turtle #38)
mission4 ;; mission 4 for visitor (turtle #39)
contactTracking
end


;;;;; move function used in missions
to move [initial displacement checkpointNum]
  if (ticks >= initial) and (ticks < (initial + displacement)) [
    face checkpoint checkpointNum
    fd 1
  ]
end

;;;;;;;;;;;;;;
;;;;Script;;;;
;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;Staff_1 Mission;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to mission1
  ;; staff room to patient 1
  ;; starts when second = 0
  ask staff 36 [move 0 24 0] ;; staff to checkpoint 0
  ask staff 36 [move 24 6 2] ;; staff to checkpoint 2
  ask staff 36 [move 30 15 3] ;; staff to checkpoint 3
  ask staff 36 [move 45 22 11] ;; staff to checkpoint 11

  ;; Patient 1 to Consult
  ;; starts when second = 76
  ask staff 36 [move 304 14 23] ;; staff to checkpoint 23

  ;; Consult to Patient 2
  ;; starts when second = 109
  ask staff 36 [move 436 21 12] ;; staff to checkpoint 12

  ;; Patient 2 to Facility
  ;; starts when second = 185
  ask staff 36 [move 740 18 17] ;; staff to checkpoint 17

  ;; Facility to Patient 1
  ;; starts when second = 271
  ask staff 36 [move 1084 28 11] ;; staff to checkpoint 11

  ;; Patient 1 to Isolation
  ;; starts when second = 347
  ask staff 36 [move 1388 22 3] ;; staff to checkpoint 3
  ask staff 36 [move 1410 7 5] ;; staff to checkpoint 5
  ask staff 36 [move 1417 4 4] ;; staff to checkpoint 4

  ;; Isolation to Staff Room
  ;; starts when second = 742
  ask staff 36 [move 2968 4 5] ;; staff to checkpoint 5
  ask staff 36 [move 2972 8 2] ;; staff to checkpoint 2
  ask staff 36 [move 2980 6 0] ;; staff to checkpoint 0
  ask staff 36 [move 2986 24 8] ;; staff to checkpoint 8

  ;; Staff Room to Facility
  ;; starts when second = 841
  ask staff 36 [move 3364 24 0] ;; staff to checkpoint 0
  ask staff 36 [move 3388 6 2] ;; staff to checkpoint 2
  ask staff 36 [move 3394 15 3] ;; staff to checkpoint 3
  ask staff 36 [move 3409 6 1] ;; staff to checkpoint 1
  ask staff 36 [move 3415 10 6] ;; staff to checkpoint 6
  ask staff 36 [move 3425 8 17] ;; staff to checkpoint 17

  ;; Facility to Patient 1
  ;; starts when second = 926
  ask staff 36 [move 3704 27 11] ;; staff to checkpoint 11

  ;; Patient 1 to Computer
  ;; starts when second = 1003
  ask staff 36 [move 4012 17 28] ;; staff to checkpoint 28
  ask staff 36 [move 4029 8 20] ;; staff to checkpoint 20

  ;; Computer to Patient 2
  ;; starts when second = 1034
  ask staff 36 [move 4136 29 12] ;; staff to checkpoint 12

  ;; Patient 2 to Consult
  ;; starts when second = 1110
  ask staff 36 [move 4440 21 23] ;; staff to checkpoint 23

  ;; Consult to Patient 1
  ;; starts when second = 1143
  ask staff 36 [move 4572 14 11] ;; staff to checkpoint 11

  ;; Patient 1 to Staff Room
  ;; starts when second = 1220
  ask staff 36 [move 4880 22 3] ;; staff to checkpoint 3
  ask staff 36 [move 4902 15 2] ;; staff to checkpoint 2
  ask staff 36 [move 4917 6 0] ;; staff to checkpoint 0
  ask staff 36 [move 4923 24 8] ;; staff to checkpoint 8

  ;; Staff Room to Computer
  ;; starts when second = 1319
  ask staff 36 [move 5276 24 0] ;; staff to checkpoint 0
  ask staff 36 [move 5300 6 2] ;; staff to checkpoint 2
  ask staff 36 [move 5306 15 3] ;; staff to checkpoint 3
  ask staff 36 [move 5321 4 7] ;; staff to checkpoint 7
  ask staff 36 [move 5325 3 29] ;; staff to checkpoint 29
  ask staff 36 [move 5328 2 20] ;; staff to checkpoint 20

  ;; Computer to Patient 2
  ;; starts when second = 1350
  ask staff 36 [move 5400 29 12] ;; staff to checkpoint 12

  ;; Patient 2 to Consult
  ;; starts when second = 1426
  ask staff 36 [move 5704 22 23] ;; staff to checkpoint 23

  ;; Consult to Patient 1
  ;; starts when second = 1459
  ask staff 36 [move 5836 14 11] ;; staff to checkpoint 11

  ;; Patient 1 to Patient 2
  ;; starts when second = 1535
  ask staff 36 [move 6140 22 12] ;; staff to checkpoint 12

  ;; Patient 2 to Facility
  ;; starts when second = 1612
  ask staff 36 [move 6448 18 17] ;; staff to checkpoint 17

  ;; Facility to Staff Room
  ;; starts when second = 1697
  ask staff 36 [move 6788 8 6] ;; staff to checkpoint 6
  ask staff 36 [move 6796 10 1] ;; staff to checkpoint 1
  ask staff 36 [move 6806 6 3] ;; staff to checkpoint 3
  ask staff 36 [move 6812 15 2] ;; staff to checkpoint 2
  ask staff 36 [move 6827 6 0] ;; staff to checkpoint 0
  ask staff 36 [move 6833 24 8] ;; staff to checkpoint 8

  ask staff 36 [
    set location pcolor ;; update location of staff
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;Staff_2 Mission;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to mission2
  ;; Staff Room to Computer
  ;; starts when second = 0
  ask staff 37 [move 0 15 0] ;; staff to checkpoint 0
  ask staff 37 [move 15 6 2] ;; staff to checkpoint 2
  ask staff 37 [move 21 15 3] ;; staff to checkpoint 3
  ask staff 37 [move 36 4 7] ;; staff to checkpoint 7
  ask staff 37 [move 40 3 29] ;; staff to checkpoint 29
  ask staff 37 [move 43 3 21] ;; staff to checkpoint 21

  ;; Computer to Patient 3
  ;; starts when second = 32
  ask staff 37 [move 128 18 14] ;; staff to checkpoint 14

  ;; Patient 3 to Consult
  ;; starts when second = 108
  ask staff 37 [move 432 24 28] ;; staff to checkpoint 28
  ask staff 37 [move 456 6 24] ;; staff to checkpoint 24

  ;; Consult to Patient 2
  ;; starts when second = 141
  ask staff 37 [move 564 21 13] ;; staff to checkpoint 13

  ;; Patient 2 to Patient 3
  ;; starts when second = 217
  ask staff 37 [move 868 35 14] ;; staff to checkpoint 14

  ;; Patient 3 to Facility
  ;; starts when second = 293
  ask staff 37 [move 1172 15 18] ;; staff to checkpoint 18

  ;; Facility to Staff
  ;; starts when second = 379
  ask staff 37 [move 1516 17 29] ;; staff to checkpoint 29
  ask staff 37 [move 1533 4 7] ;; staff to checkpoint 7
  ask staff 37 [move 1537 4 3] ;; staff to checkpoint 3
  ask staff 37 [move 1541 15 2] ;; staff to checkpoint 2
  ask staff 37 [move 1556 5 0] ;; staff to checkpoint 0
  ask staff 37 [move 1561 15 9] ;; staff to checkpoint 9

  ;; Staff to P2
  ;; starts when second = 478
  ask staff 37 [move 1912 15 0] ;; staff to checkpoint 0
  ask staff 37 [move 1927 6 2] ;; staff to checkpoint 2
  ask staff 37 [move 1933 15 3] ;; staff to checkpoint 3
  ask staff 37 [move 1948 6 1] ;; staff to checkpoint 1
  ask staff 37 [move 1954 10 6] ;; staff to checkpoint 6
  ask staff 37 [move 1964 18 13] ;; staff to checkpoint 13

  ;; P2 to Consult
  ;; starts when second = 554
  ask staff 37 [move 2216 21 24] ;; staff to checkpoint 24

  ;; Consult to P3
  ;; starts when second = 587
  ask staff 37 [move 2348 30 14] ;; staff to checkpoint 14

  ;; P3 to Facility
  ;; starts when second = 663
  ask staff 37 [move 2652 16 18] ;; staff to checkpoint 18

  ;; Facility to P2
  ;; starts when second = 749
  ask staff 37 [move 2996 20 13] ;; staff to checkpoint 13

  ;; P2 to Isolation
  ;; starts when second = 825
  ask staff 37 [move 3300 23 28] ;; staff to checkpoint 28
  ask staff 37 [move 3323 3 1] ;; staff to checkpoint 1
  ask staff 37 [move 3326 6 3] ;; staff to checkpoint 3
  ask staff 37 [move 3332 7 5] ;; staff to checkpoint 5
  ask staff 37 [move 3339 4 4] ;; staff to checkpoint 4

  ;; Isolation to Staff
  ;; starts when second = 1220
  ask staff 37 [move 4880 4 5] ;; staff to checkpoint 5
  ask staff 37 [move 4884 8 2] ;; staff to checkpoint 2
  ask staff 37 [move 4892 6 0] ;; staff to checkpoint 0
  ask staff 37 [move 4898 14 9] ;; staff to checkpoint 9

  ;; Staff to Facility
  ;; starts when second = 1319
  ask staff 37 [move 5276 14 0] ;; staff to checkpoint 0
  ask staff 37 [move 5290 6 2] ;; staff to checkpoint 2
  ask staff 37 [move 5296 15 3] ;; staff to checkpoint 3
  ask staff 37 [move 5311 6 1] ;; staff to checkpoint 1
  ask staff 37 [move 5317 3 28] ;; staff to checkpoint 28
  ask staff 37 [move 5320 16 18] ;; staff to checkpoint 18

  ;; Facility to P2
  ;; starts when second = 1404
  ask staff 37 [move 5616 20 13] ;; staff to checkpoint 13

  ;; P2 to Computer
  ;; starts when second = 1481
  ask staff 37 [move 5924 28 21] ;; staff to checkpoint 21

  ;; Computer to P3
  ;; starts when second = 1512
  ask staff 37 [move 6048 18 14] ;; staff to checkpoint 14

  ;; P3 to Consult
  ;; starts when second = 1588
  ask staff 37 [move 6352 24 28] ;; staff to checkpoint 28
  ask staff 37 [move 6376 6 24] ;; staff to checkpoint 24

  ;; Consult to P2
  ;; starts when second = 1621
  ask staff 37 [move 6484 21 13] ;; staff to checkpoint 13

  ;; P2 to Staff
  ;; starts when second = 1697
  ask staff 37 [move 6788 22 28] ;; staff to checkpoint 28
  ask staff 37 [move 6810 3 1] ;; staff to checkpoint 1
  ask staff 37 [move 6813 6 3] ;; staff to checkpoint 3
  ask staff 37 [move 6819 15 2] ;; staff to checkpoint 2
  ask staff 37 [move 6834 6 0] ;; staff to checkpoint 0
  ask staff 37 [move 6840 14 9] ;; staff to checkpoint 9

  ask staff 37 [
    set location pcolor ;; update location of staff
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;Staff_3 Mission;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to mission3
  ;; staff move to supply (facility)
  ;; starts when second = 0
  ask staff 38 [move 0 4 0] ;; staff to checkpoint 0
  ask staff 38 [move 4 6 2] ;; staff to checkpoint 2
  ask staff 38 [move 10 15 3] ;; staff to checkpoint 3
  ask staff 38 [move 25 6 1] ;; staff to checkpoint 1
  ask staff 38 [move 31 10 6] ;; staff to checkpoint 6
  ask staff 38 [move 41 9 19] ;; staff to checkpoint 19

  ;; staff move to patient 3
  ;; starts when second = 86
  ask staff 38 [move 344 17 15] ;; staff to checkpoint 15

  ;; staff move to nursing station
  ;; starts when second = 162
  ask staff 38 [move 648 2 22] ;; staff to checkpoint 22

  ;; staff move to patient 4
  ;; starts when second = 194
  ask staff 38 [move 776 5 29] ;; staff to checkpoint 29
  ask staff 38 [move 781 8 16] ;; staff to checkpoint 16

  ;; staff move to consultant
  ;; starts when second = 270
  ask staff 38 [move 1080 9 29] ;; staff to checkpoint 29
  ask staff 38 [move 1089 10 28] ;; staff to checkpoint 28
  ask staff 38 [move 1099 6 25] ;; staff to checkpoint 25

  ;; staff move to patient 3
  ;; starts when second = 303
  ask staff 38 [move 1105 6 28] ;; staff to checkpoint 28
  ask staff 38 [move 1111 24 15] ;; staff to checkpoint 15

  ;; staff move to staff room
  ;; starts when second = 379
  ask staff 38 [move 1516 20 7] ;; staff to checkpoint 7
  ask staff 38 [move 1536 4 3] ;; staff to checkpoint 3
  ask staff 38 [move 1540 15 2] ;; staff to checkpoint 2
  ask staff 38 [move 1555 6 0] ;; staff to checkpoint 0
  ask staff 38 [move 1561 4 10] ;; staff to checkpoint 10

  ;; staff move to nursing station
  ;; start when second = 478
  ask staff 38 [move 1912 4 0] ;; staff to checkpoint 0
  ask staff 38 [move 1916 6 2] ;; staff to checkpoint 2
  ask staff 38 [move 1922 15 3] ;; staff to checkpoint 3
  ask staff 38 [move 1937 6 1] ;; staff to checkpoint 1
  ask staff 38 [move 1943 3 28] ;; staff to checkpoint 28
  ask staff 38 [move 1946 6 22] ;; staff to checkpoint 22

  ;; staff move to patient 4
  ;; start when second = 509
  ask staff 38 [move 2036 4 29] ;; staff to checkpoint 29
  ask staff 38 [move 2040 9 16] ;; staff to checkpoint 16

  ;; staff move to patient 3
  ;; starts when second = 586
  ask staff 38 [move 2344 20 15] ;; staff to checkpoint 15

  ;; staff move to consultant
  ;; starts when second = 662
  ask staff 38 [move 2648 24 28] ;; staff to checkpoint 28
  ask staff 38 [move 2672 6 25] ;; staff to checkpoint 25

  ;; staff move to patient 4
  ;; starts when second = 695
  ask staff 38 [move 2780 6 28] ;; staff to checkpoint 28
  ask staff 38 [move 2786 10 29] ;; staff to checkpoint 29
  ask staff 38 [move 2796 9 16] ;; staff to checkpoint 16

  ;; staff move to supply
  ;; starts when second = 771
  ask staff 38 [move 3084 26 19] ;; staff to checkpoint 19

  ;; staff move to staff room
  ;; starts when second = 857
  ask staff 38 [move 3428 16 28] ;; staff to checkpoint 28
  ask staff 38 [move 3444 4 1] ;; staff to checkpoint 1
  ask staff 38 [move 3448 6 3] ;; staff to checkpoint 3
  ask staff 38 [move 3454 15 2] ;; staff to checkpoint 2
  ask staff 38 [move 3469 6 0] ;; staff to checkpoint 0
  ask staff 38 [move 3475 4 10] ;; staff to checkpoint 10

  ;; staff move to patient 3
  ;; starts when second = 956
  ask staff 38 [move 3824 4 0] ;; staff to checkpoint 0
  ask staff 38 [move 3828 6 2] ;; staff to checkpoint 2
  ask staff 38 [move 3834 15 3] ;; staff to checkpoint 3
  ask staff 38 [move 3849 4 7] ;; staff to checkpoint 7
  ask staff 38 [move 3853 20 15] ;; staff to checkpoint 15

  ;; staff move to consultant
  ;; starts when second = 1032
  ask staff 38 [move 4128 24 28] ;; staff to checkpoint 28
  ask staff 38 [move 4152 5 25] ;; staff to checkpoint 25

  ;; staff move to patient 4
  ;; starts when second = 1062
  ask staff 38 [move 4248 6 28] ;; staff to checkpoint 28
  ask staff 38 [move 4254 10 29] ;; staff to checkpoint 29
  ask staff 38 [move 4264 9 16] ;; staff to checkpoint 16

  ;; staff move to supply
  ;; starts when second = 1141
  ask staff 38 [move 4564 26 19] ;; staff to checkpoint 19

  ;; staff move to patient 3
  ;; starts when second = 1227
  ask staff 38 [move 4908 17 15] ;; staff to checkpoint 15

  ;; staff move to isolation room
  ;; starts when second = 1303
  ask staff 38 [move 5212 21 7] ;; staff to checkpoint 7
  ask staff 38 [move 5233 11 4] ;; staff to checkpoint 4

  ;; staff move to staff room
  ;; starts when second = 1697
  ask staff 38 [move 6788 4 5] ;; staff to checkpoint 5
  ask staff 38 [move 6792 7 2] ;; staff to checkpoint 2
  ask staff 38 [move 6799 6 0] ;; staff to checkpoint 0
  ask staff 38 [move 6805 4 10] ;; staff to checkpoint 10

  ask staff 38 [
    set location pcolor ;; update location of staff
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;Visitor Mission;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to mission4
  ;; visitor move to consultant in sim room 2
  ;; starts when second = 76
  ask visitor 39 [move 304 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 141
  ask visitor 39 [move 564 10 27]

  ;; visitor move to consultant in sim room 2
  ;; starts when second = 270
  ask visitor 39 [move 1080 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 303
  ask visitor 39 [move 1212 10 27]

  ;; visitor move to consultant in sim room 2
  ;; starts when second = 554
  ask visitor 39 [move 2216 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 587
  ask visitor 39 [move 2348 10 27]

  ;; visitor move to consultant in sim room 2
  ;; starts when second = 662
  ask visitor 39 [move 2648 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 695
  ask visitor 39 [move 2780 10 27]

  ;; visitor move to consultant in sim room 2
  ;; starts when second = 1032
  ask visitor 39 [move 4128 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 1065
  ask visitor 39 [move 4260 10 27]

  ;; visitor move to consultant in sim room 2
  ;; starts when second = 1110
  ask visitor 39 [move 4440 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 1143
  ask visitor 39 [move 4572 10 27]

  ;; visitor move to consultant in sim room 2
  ;; starts when second = 1426
  ask visitor 39 [move 5704 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 1459
  ask visitor 39 [move 5836 10 27]

  ;; visitor move to consultant in sim room 2
  ;; starts when second = 1588
  ask visitor 39 [move 6352 10 26]

  ;; visitor move out to hallway
  ;; starts when second = 1621
  ask visitor 39 [move 6484 10 27]

  ask visitor 39 [
    set location pcolor ;; update location of staff
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tracking is done using a nested while loop that compares all combination pair of population ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to contactTracking
  let i 29 ;; i should be the number assigned for the last checkPoint
  let ic 0 ;; element position of infected-counter array
  let j 0
  let h count turtles - num-checkPoints ;; h is the number of people
  let l 0 ;; element position of
  let f 0 ;; element position of flag array
  let ts 0 ;; element position of tick-start array
  let ds 0 ;; element position of distance-sum array
  let an 0 ;; element position of agent-name array
  let cic 0 ;; current infected counter
  let duration 0 ;; total contact time offset by 1 to account for the initial tick
  let distance-avg 0 ;; average the suming of all distances by total time
  let real-ticks (loop-counter) * 7814 + ticks ;;because tick need to be reset for the script, a real tick is used to keep track

  ;;;; infectious agent will be removed after given time and replace with a susceptible agent
  while [ic < h][
    set i i + 1
    if [health] of turtle i = "infectious" [set cic cic + 1] ;; current infected counter
    if [health] of turtle i = "infectious" [array:set infected-counter ic array:item infected-counter ic + 1]
    if array:item infected-counter ic = infected-to-remove-time [
      ask turtle i [
        set health "susceptible"
        if i >= 30 and i < 34 [ ;; patient
          set pn pn + 1
          set agent-num pn
        ]
        if i >= 36 and i < 38 [ ;; staff
          set sn sn + 1
          set agent-num sn
        ]
        if i = 39 [ ;; visitor
          set vn vn + 1
          set agent-num vn
        ]

      array:set infected-counter ic 0 ;;reset counter since infected has been removed
    ]
    ]
    set ic ic + 1
  ]

  ;;;; moniter the current number of infected, if there are no agents infected, the simulation is stopped
  set current_num_infected cic

  ;;;; turtle names given
  while [an < h][
    if an < 4[
      array:set agent-name an "patient"
    ]
    if an = 4[
      array:set agent-name an "nursingStation"
    ]
    if an = 5 [
      array:set agent-name an "supply"
    ]
    if an < 9 and an > 5 [
      array:set agent-name an "staff"
    ]
    if an = 9[
      array:set agent-name an "vistor"
    ]
    set an an + 1
  ]

  ;;;; contact is being made with a nested while loop
  while [j < h] [
    set i 29 ;; reset variable i
    set j j + 1
    set f f + 1 ;; increment element position
    while [i + j < h + 29] [
      set i i + 1
      let k i + j ;; turtle number compare to turtle i
      set l l + 1
      set an an + 1
      set f f + 1 ;; increment flag element
      set ts ts + 1 ;; increment tick-start element
      set ds ds + 1 ;; increment distance-sum element

      ;;;;;;;;;;if an object or person is infectious the color will change to red;;;;;;;
      if [health] of turtle i = "infectious" [ask turtle i [set color red]]
      if [health] of turtle k = "infectious" [ask turtle k [set color red]]
      if [health] of turtle i = "susceptible" [ask turtle i [set color white]]
      if [health] of turtle k = "susceptible" [ask turtle k [set color white]]

      if [location] of turtle i = [location] of turtle k or array:item flag f = 1[
        if [location] of turtle i = [location] of turtle k and array:item flag f = 0 [ ;; save the location of contact for later output
          if [location] of turtle i = 5 [array:set location-of-contact l "hallway"]
          if [location] of turtle i = 55 [array:set location-of-contact l "staff room"]
          if [location] of turtle i = 115 [array:set location-of-contact l "patient room"]
          ;; if [location] of turtle i = 35 [set l "isolation room"] ;; this line is only for reference since no contacts will ever occur in isolation room

        ;; when flag equals 1 it means contact starts and will start storing data of contact for output later
        array:set flag f 1
        ]

        ;; probability of a spread of infection if an infected agent and makes contact with a healthy agent
        if [distance turtle i] of turtle k < effective-distance-of-infection[
          if [health] of turtle i = "infectious" and [health] of turtle k = "susceptible" [
            if random probability-of-infection = 1 [ ;;probability-of-infection silder number, the higher the less probable of infection spread
              ask turtle k [set health "infectious"]
              set num-infections num-infections + 1
            ]
          ]
          if [health] of turtle k = "infectious" and [health] of turtle i = "susceptible" [
            if random probability-of-infection = 1 [ ;;probability-of-infection silder number, the higher the less probable of infection spread
              ask turtle i [set health "infectious"]
              set num-infections num-infections + 1
            ]
          ]
        ]
        ;; summing each distances of each tick for the duration of contact
        array:set distance-sum ds array:item distance-sum ds + [distance turtle i] of turtle k
        ;; set tick-start ts to the first tick of contact, this tick is saved for duration calculation
        if array:item tick-start ts = 0 [
        array:set tick-start ts real-ticks
        ]


        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;OUTPUT;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;; when flag equals 0 after it's been 1, it means contact ends and outputs the data of the contact
        if [location] of turtle i != [location] of turtle k [
          array:set flag f 0

          ;; converting location 'number' into location 'text'
          set num-interactions num-interactions + 1 ;;counting number of interactions

          if array:item tick-start ts = 1 [ ;; the first tick should start at 0
          array:set tick-start ts 0
          set duration real-ticks - array:item tick-start ts
          ]
          if array:item tick-start ts != 1[
          set duration real-ticks - array:item tick-start ts ;; calculate duration of contact (current tick - starting tick)
          ]

          set distance-avg  array:item distance-sum ds / duration

          ;; variable for agent-name array to output
          let ii i - 30
          let kk k - 30

          ;; the data of the MySQL file, the format is ('subject', 'compare', 'location', 'average distance', 'tick-start', 'tick-end', 'duration')
          ;; all values are either char or int
          ;; currently contact is being reported per tick and without duration

          ;; this will print in the text file
          file-type "('" file-type array:item agent-name ii file-type " " file-type [agent-num] of turtle i file-type "', '" file-type array:item agent-name kk file-type " "
          file-type [agent-num] of turtle k file-type "', '" file-type array:item location-of-contact l file-type "', " file-type round distance-avg file-type", "
          file-type array:item tick-start ts file-type ", "file-type real-ticks file-type ", " file-type duration file-type ")," file-print""

          ;;;;;;;DEBUGGING outputs to track variables;;;;;;;;;;;;;;;;;;
          ;;type "tick start: " print array:item tick-start ts
          ;;type "tick: " print ticks
          ;;type "ds: " print ds
          ;;type "average distance: " print distance-avg
          ;;type "distance sum: " print array:item distance-sum ds
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;printed;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          type "('" type array:item agent-name ii type " " type [agent-num] of turtle i type "', '" type array:item agent-name kk type " " type [agent-num] of turtle k
          type "', '" type array:item location-of-contact l type "', " type round distance-avg type", " type array:item tick-start ts type ", "
          type real-ticks type ", " type duration type ")," print""
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

          array:set tick-start ts 0 ;; clear tick-start so tick-start will be updated again for next contact
          array:set distance-sum ds 0 ;; clear distance-sum so distance-sum will be updated again for next contact
        ]
      ]
      ]
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
235
10
867
643
-1
-1
9.6
1
10
1
1
1
0
0
0
1
-32
32
-32
32
1
1
1
ticks
30.0

BUTTON
13
15
97
48
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
13
79
97
112
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
13
47
97
80
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
104
15
220
60
Number of Interations
num-interactions
17
1
11

MONITOR
105
60
220
105
Number of Infections
num-infections
17
1
11

SLIDER
11
195
221
228
effective-distance-of-infection
effective-distance-of-infection
0
50
2.0
1
1
NIL
HORIZONTAL

SLIDER
11
228
221
261
probability-of-infection
probability-of-infection
10
20000
2500.0
1
1
^-1
HORIZONTAL

INPUTBOX
11
360
107
420
infection-source
39.0
1
0
Number

SLIDER
11
261
221
294
infected-to-remove-time
infected-to-remove-time
0
1000000
187536.0
1
1
NIL
HORIZONTAL

SLIDER
11
294
220
327
number-of-loops
number-of-loops
0
1000
96.0
1
1
NIL
HORIZONTAL

MONITOR
105
105
220
150
current loop number
loop-counter
17
1
11

SLIDER
11
327
183
360
number-of-runs
number-of-runs
0
500
20.0
1
1
NIL
HORIZONTAL

MONITOR
105
150
221
195
current run number
run-counter
17
1
11

@#$#@#$#@
## WHAT IS IT?

This example shows how to make turtles "walk" from node to node on a network, by following links.

## EXTENDING THE MODEL

Animate the turtles as they move from node to node.

## RELATED MODELS

* Lattice-Walking Turtles Example
* Grid-Walking Turtles Example

<!-- 2007 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
12
Rectangle -7500403 true false 15 15 285 285
Rectangle -7500403 false false 210 255 210 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
random-seed 2
setup
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

breed [ zombies zombie ]
breed [ patient0s patient0 ]
breed [ humans human ]
patches-own [genericc]
humans-own [ stamina builder hunter doctor pleb infected? safecolor infectionlength]
globals [ cure-development ]
zombies-own [ rotting ]

; SETUP
to setup
  ca
  reset-ticks
  setup-buildings
  setup-turtles
  setup-globals
end
;_____________________________________________
to setup-globals
  set cure-development 0
  ask zombies [set rotting 1000]
    ask humans [
    set infected? false
    set infectionlength 0
    ]
end
;_____________________________________________
to setup-turtles

set-default-shape zombies "zombie"
set-default-shape humans "person"
;_____________________________________
; Patient 0

  create-patient0s 1
  [
    setxy 40 0
    set shape "patient0"
    set size 1.2
  ]
;_____________________________________
; Humans

  create-humans Starting-Humans
  [
    choosesafecolor
    set color yellow + random 3
    setxy random-pxcor random-pycor
    if pxcor >= 30
     [set xcor xcor - random 30 - 20]
    set size 1.2
    assignroles
  ]
end

to choosesafecolor
  let x random 3
 if x = 0
    [set safeColor blue]
 if x = 1
    [set safeColor red]
 if x = 2
    [set safecolor gray]
end

to assignroles
  set color yellow
  let x random 100
  if x < 23 and x > 1
  [ set builder orange
    set shape "builder"
    set color orange]
  if x < 2
  [ set doctor blue
    set shape "doctor"
    set color violet]
  if random x > 22 and x < 28
  [ set hunter red
    set shape "hunter"
    set color red ]

end
;_____________________________________________
to setup-buildings

; Generic buildings for generic people

ask patches with [0 = pxcor mod 8 and 0 = pycor mod 8 and pxcor < 29]
  [ set pcolor gray]
repeat 2 [
  ask patches with [pcolor = gray] [
    ask neighbors
      [set pcolor gray]
     ]
  ]

ask patches
  [set genericc count neighbors with
    [pcolor = black]
  if pcolor = gray or pcolor = red and genericc > 0
    [set pcolor white]
  ]

;_______________________________________
; Creating the hospital

ask patches with [pxcor = 0 and pycor = 0]
  [set pcolor red]
repeat 9
  [ ask patches with [pcolor = red] [
    ask neighbors
      [set pcolor red]
  ]
  ]
ask patches
  [set genericc count neighbors with
    [pcolor = black]
  if pcolor = red and genericc > 0
    [set pcolor white]
  ]

; Creating the armory
ask patches with [ pxcor = min-pxcor + 5 and pycor = min-pycor + 5]
  [ set pcolor blue]
repeat 5 [
  ask patches with [pcolor = blue]
    [
      ask neighbors
        [set pcolor blue]
    ]
]
end

;_______________________________________________________________________________________________________


; HUMAN BEHAVIORS
to human-behavior

  ask humans with [doctor != blue]
  [ movearound
   if safecolor != [pcolor] of patch-here
     [
       ifelse any? zombies in-radius human-vision-radius
       [runawayfromzombie]
       [wiggle]
     ]
   if infected?
     [
       set infectionlength infectionlength + 1
       turnzombie
     ]
  ]
end

to turnzombie
if infectionlength > incubation-period
  [ hatch-zombies 1 [
    rt 90
    set color green + random 3
    set rotting 1000
  ]
   die
  ]
end

to hunter-behavior
  ask humans with [hunter = red]
  [
    if any? zombies in-radius hunter-kill-radius
    [
 ask one-of zombies in-radius hunter-kill-radius
   [die]
    ]
  ]
end

to doctor-behavior
  ask humans with [doctor = blue]
  [
    wiggle
    ifelse cure-development < 100
    [developcure]
    [ask zombies-here
      [cure]
    ]
  ]
end

to developcure
  set cure-development cure-development + (count zombies / 100)
end

to cure
  if any? zombies in-radius human-vision-radius
    [face min-one-of zombies [distance myself]
      fd .8
      hatch-humans 1
      [
        rt 90
        assignroles
      ]
      die
    ]
end

to builder-behavior
  ask humans with [builder = orange]
  [ fixsh*t ]
end

to fixsh*t
  if pcolor >= white - 5 and pcolor <= 9
    [set pcolor pcolor + .1]
end

to movearound
  if not any? zombies in-radius human-vision-radius
  [if random 100 < 30
    [choosesafecolor]
  ]
end

to wiggle
  fd .2
  rt random 20
  lt random 20
  if stamina < maximum-stamina
  [set stamina stamina + .5]
end
to runawayfromzombie
  face min-one-of zombies [ distance myself ]
  set heading ( heading - 180 )
    ifelse stamina > 1
    [fd .8 set stamina stamina - 1]
    [fd .1]
end


; __________________________________________________________________________________________________
; ZOMBIE BEHAVIOR

to zombie-behavior
ask zombies [

; Armory Death
  if pcolor = blue [die]

; Moving Around
  ifelse [pcolor] of patch-here = red or [pcolor] of patch-here >= white - 5
  [shambleback]
  [
    ifelse any? humans with [infected? != true and doctor = blue] in-cone zombie-vision-radius zombie-vision-angle
    [
      face min-one-of humans [distance myself] fd zombie-speed * 2
      killdoctors
      breaksh*t
    ]
    [ shamble ]

    ifelse rotting > 0
      [
        ifelse pcolor != black and pcolor != white
        [ set rotting (rotting - rotting-rate / 50) ]
        [ set rotting (rotting - rotting-rate / 75) ]
      ]
      [crumble]
  ]

; Infection
if random 100 < infection-chance
  [ ask humans-here [zombify] ]
]
end

to breaksh*t
  if pcolor >= white - 5 and pcolor < 10
    [set pcolor pcolor - 0.1]
end

to killdoctors
  if cure-development != 100
  [ if any? humans with [doctor = blue] in-cone zombie-vision-radius zombie-vision-angle
    [ face min-one-of humans with [doctor = blue] [distance myself] fd zombie-speed * 1.5 ]
  ]
  end

to shamble
  fd zombie-speed
  rt random 20
  lt random 20
end
to shambleback
  bk zombie-speed * 2
  rt random 20
  lt random 20
end

to crumble
  set shape "cow"
  set color brown + random 3
  stamp
  die
end

to zombify
  set infected? true
end

; __________________________________________________________________________________________________
; Patient Zero Behavior

to patient0-behavior
  ask patient0s [
    ifelse any? humans in-cone zombie-vision-radius zombie-vision-angle
    [
      face min-one-of humans [distance myself] fd zombie-speed * 1.5
    ]
    [fakewiggle]
if pcolor = black or pcolor = white or pcolor = gray
     [ask humans-here
       [zombify0]
     ]
  ]
end

to zombify0
  hatch-zombies 1
  [
    rt 90
    set color green + random 3
    set rotting 1000
  ]
  die
end
to fakewiggle
  fd .2
  rt random 20
  lt random 20
end

; __________________________________________________________________________________________________
to go
  every 1 / 30
    [
      human-behavior
      hunter-behavior
      doctor-behavior
      builder-behavior
      patient0-behavior
      zombie-behavior
      tick
    ]
end


; BREAKDOWN
; Maggie Zhao
; setupglobals and setupturtles
; 1.11-12.17 added cure development and curing zombies
; 1.13.17 added rotting rate
; 1.15.17 added infection chance, infection length, and turning humans
; 11.16.17 wrote Info tab
@#$#@#$#@
GRAPHICS-WINDOW
273
10
1492
652
46
23
13.0
1
10
1
1
1
0
1
1
1
-46
46
-23
23
1
1
1
ticks
30.0

SLIDER
1
63
129
96
Starting-humans
Starting-humans
0
400
224
1
1
NIL
HORIZONTAL

SLIDER
1
100
128
133
Maximum-Stamina
Maximum-Stamina
0
100
17
1
1
NIL
HORIZONTAL

SLIDER
137
61
269
94
zombie-vision-radius
zombie-vision-radius
0
10
8
1
1
NIL
HORIZONTAL

SLIDER
135
100
268
133
zombie-vision-angle
zombie-vision-angle
0
100
42
1
1
NIL
HORIZONTAL

SLIDER
0
177
129
210
hunter-kill-radius
hunter-kill-radius
0
10
3
1
1
NIL
HORIZONTAL

MONITOR
134
256
268
301
zombies
Count zombies
17
1
11

MONITOR
3
257
130
302
humans
Count humans
17
1
11

SLIDER
136
137
267
170
zombie-speed
zombie-speed
0
1
0.9
.1
1
NIL
HORIZONTAL

SLIDER
136
179
267
212
rotting-rate
rotting-rate
0
100
48
1
1
NIL
HORIZONTAL

SLIDER
135
216
267
249
infection-chance
infection-chance
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
1
216
130
249
incubation-period
incubation-period
0
100
58
1
1
NIL
HORIZONTAL

BUTTON
39
13
112
46
setup
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
124
12
187
45
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
-1
137
129
170
human-vision-radius
human-vision-radius
0
10
4
1
1
NIL
HORIZONTAL

PLOT
30
312
230
462
Cure Progression
Ticks
Cure Development
0.0
1000.0
0.0
100.0
true
true
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot cure-development"

@#$#@#$#@
Zombies: Advanced Infection

## WHAT IS IT?

This model simulates a hypothetical zombie apocalypse. We took the original zombie lab and advanced it, giving both zombies and humans more features.

## HOW IT WORKS

The model uses three different types of turtles- patient zero, humans, and zombies, to replicate a post-apocalyptic city. Initially, humans will wander around the city. Patient Zero, who is undetectable by humans, will actively chase humans to turn them into zombies with a 100% infection rate.  Humans specialize into certain occupations- doctors, builders, hunters, or plebeians. Doctors develop the cure, builders rebuild safe zones after zombies destroy them (explained later), hunters kill zombies, and plebeians are zombie fodder. Humans walk around, occasionally stopping within buildings, until they detect a zombie within their vision radius, which will cause them to choose a safe spot and run away. When humans run away, their stamina slowly decreases, and when it hits zero, they will walk at a slower rate, allowing zombies to catch up and eat them. After the cure is fully developed, doctors will follow zombies and cure them, reverting them back into a human with a randomly assigned job.

## HOW TO USE IT

The SETUP button creates a “city” with 35 buildings, an armory, a hospital, a predetermined number of humans with certain character traits, and one Patient Zero. Human and zombie behaviors are determined according to the values of the interface’s 11 sliders (described below). After the setup, you can run the program by clicking GO (pretty self explanatory, right?). The GO button is a forever button, so it will continue to run the program until there are only zombies or only humans left.
A human and zombie monitor show how many of each type of turtle there are. There is also a cure development graph, which shows the ongoing progress of the cure.
Here is a summary of the sliders in the model. They are explained in more detail below.
-STARTING-HUMANS: Determines the initial size of human population
-HUMAN-VISION-RADIUS: How far away a human will be able to detect the presence of a      zombie. If a zombie is in this radius, the human will run away.
HUNTER-KILL-RADIUS: The radius in which a hunter will be able to kill a zombie
MAXIMUM-STAMINA: This determines how much stamina a human starts out with. Humans can slowly regain stamina by wiggling (up until maximum stamina), but every time they run away, their stamina decreases drastically.
ZOMBIE-SPEED: The speed at which a zombie travels. The faster you set it, the faster he goes. Watch him fly!
ZOMBIE-VISION-RADIUS: The radius in which a zombie can detect his food.
ZOMBIE-VISION-ANGLE: The angle of the cone in which said zombie detects food.
ROTTING-RATE: How quickly the zombie will rot. Zombies start out with a “health” of 1000, and with each tick, their health decreases by the slider number. This is also affected by whether or not they are in a building, which slows down the rotting rate.
INFECTION-CHANCE: Only Patient Zero is guaranteed to turn a human into a zombie! All zombies after that have an infection-chance chance of converting humans.
INCUBATION-PERIOD: How many ticks it will take before humans will turn into zombies and start eating other people.
CURE-DEVELOPMENT-RATE: How quickly doctors will develop a cure; the more zombies there are, the quicker they will work.

## THINGS TO NOTICE

Our zombies went to Stuyvesant and became smarter! Now, they will break down buildings to get to the tasty humans inside. As the zombies pound down on the buildings, the walls will turn darker shades of gray until it matches the inside color, which does not protect the humans. It is the builder’s job to repair houses. Zombies will also prioritize killing doctors over other humans. After zombies are fully rotted, they turn into cows (carcasses).
Humans also get an upgrade (but not TOO much). They will leave their safe zones and wander again after zombies leave their area.
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

builder
false
0
Circle -7500403 true true 110 5 80
Polygon -13791810 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Polygon -955883 true false 105 30 120 0 180 0 195 15 210 15 225 30 105 30
Polygon -955883 true false 120 90 150 90 180 90 195 90 180 195 120 195 105 90 120 90
Polygon -1184463 true false 105 90 135 195 150 195 120 90 105 90
Polygon -1184463 true false 180 90 195 90 165 195 150 195 180 90

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

doctor
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 104 91 119 196 89 286 104 301 134 301 149 226 164 301 194 301 209 286 179 196 194 91
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Polygon -13791810 true false 120 45 181 45 177 73 122 72 119 45
Polygon -1 true false 112 38 119 46
Line -1 false 109 39 121 48
Line -1 false 179 49 190 39
Line -1 false 121 69 117 78
Line -1 false 176 72 182 77
Polygon -16777216 true false 139 89 160 89 149 105 142 90
Polygon -16777216 true false 150 104 139 119 150 145 161 119 151 105
Polygon -13791810 true false 105 90 126 90 151 130 177 91 193 90 185 163 198 251 102 251 115 163 103 91

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

hunter
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 194 91 239 151 224 181 164 106
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Polygon -2674135 true false 120 0 195 0 195 30 210 60 195 75 180 45 120 45 105 75 90 60 105 30 105 0 195 0
Polygon -13791810 true false 114 202 96 269 136 293 149 225 165 293 206 265 184 200 150 210
Polygon -2674135 true false 104 90 194 89 234 144 218 174 190 136 201 216 94 215 110 138 81 172 67 141 105 91
Polygon -6459832 true false 79 62 115 184 103 194 91 153 98 151 71 68 80 65

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

patient0
false
0
Polygon -8630108 true false 225 105 240 180 210 180 195 120
Polygon -8630108 true false 75 105 60 180 90 180 105 120
Circle -8630108 true false 110 5 80
Polygon -8630108 true false 105 90 120 195 105 300 120 300 135 300 150 225 165 300 180 300 195 300 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 285 105 180 105 165 75 105 135 75 150 75 165 75 225 105 195 165 195 180 195 285

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

zombie
false
0
Circle -7500403 true true 125 5 80
Polygon -7500403 true true 105 75 120 180 90 270 105 285 135 285 150 210 165 285 195 285 210 270 180 180 195 75
Rectangle -7500403 true true 127 64 172 79
Polygon -7500403 true true 195 75 285 90 285 120 180 105
Polygon -7500403 true true 255 120 165 120 165 150 240 150

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
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

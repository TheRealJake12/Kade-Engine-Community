-- Script for forced middlescroll.

local receptor = null
local R0 = null 
local R1 = null 
local R2 = null 
local R3 = null 
local R4 = null 
local R5 = null 
local R6 = null 
local R7 = null 

function start(song)
    
end

-- this gets called starts when the level loads.
function songStart()
    R0 = _G['receptor_0']
    R1 = _G['receptor_1']
    R2 = _G['receptor_2']
    R3 = _G['receptor_3']
    R4 = _G['receptor_4']
    R5 = _G['receptor_5']
    R6 = _G['receptor_6']
    R7 = _G['receptor_7']
    
          for i = 4, 7 do 
            receptor = _G['receptor_'..i]
            receptor.tweenPos(receptor, receptor.defaultX + -320, receptor.y, 0.35)
            receptor.tweenAngle(receptor, receptor.angle + 360, 0.35)
        end
     R0:tweenAlpha(0, 0.35)
     R1:tweenAlpha(0, 0.35)
     R2:tweenAlpha(0, 0.35)
     R3:tweenAlpha(0, 0.35)

     strumLine1Visible	= false
     end

end

-- this gets called every frame
function update(elapsed) -- arguments, how long it took to complete a frame
    
end

-- this gets called every beat
function beatHit(beat) -- arguments, the current beat of the song

end

-- this gets called every step
function stepHit(step) -- arguments, the current step of the song (4 steps are in a beat)

end

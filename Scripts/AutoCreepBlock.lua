require("libs.ScriptConfig")
require("libs.Utils")

local config = ScriptConfig.new()
config:SetParameter("CreepBlockKey", "N", config.TYPE_HOTKEY)
config:Load()
	
creepblockkey = config.CreepBlockKey

local reg = false local myId = nil local firstmove = false local closestCreep = nil local blocksleep = 0 local creepTable = {}

local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local statusText = drawMgr:CreateText(-50,-25,-1,"AutoBlock: Hold ''" .. string.char(creepblockkey) .. "''",F14) statusText.visible = false
local disableText = drawMgr:CreateText(-50,-15,-1,"",F14) disableText.visible = false

function Main(tick)
	if not PlayingGame() or client.paused then return end	
	local me = entityList:GetMyHero() if not me then return end	
	local ID = me.classId if ID ~= myId then Close() end			
	statusText.entity = me
	statusText.entityPosition = Vector(0,0,me.healthbarOffset)
	disableText.entity = me
	disableText.entityPosition = Vector(0,0,me.healthbarOffset)	
	if client.gameTime > 0 then 
		disableText.visible = true
		disableText.text = "Disable in " .. math.floor(25 - client.gameTime) .. " seconds."
	end
	if client.gameTime >= 25 then
		disableText.visible = false
		statusText.visible = false
		myId = nil
		closestCreep = nil
		creepTable = {}
		script:Disable()
	else
		statusText.visible = true
	end
	GetCreeps(me)		
	if IsKeyDown(creepblockkey) and not client.chat then
		CreepBlock(me)
	end
end

function CreepBlock(me)
	local startingpoint = Vector(-4781,-3969,261)
	local startingpoint2 = Vector(-4250,-3983,261)
	local endingpoint = Vector(-1159,-725,132)
	if me.team == LuaEntity.TEAM_DIRE then
		startingpoint = Vector(3929,3420,263)
		startingpoint2 = Vector(3816,3306,170)
		endingpoint = Vector(116,250,127)
	end
	if client.gameTime >= (1.48 - client.latency/1000) and GetTick() > blocksleep then
		blocksleep = GetTick() + me.movespeed/2 - client.latency/1000
		if me.position == startingpoint2 or GetDistance2D(me,startingpoint2) < 50 or GetDistance2D(endingpoint,me) < 4000 then
			firstmove = true
		end
		if not firstmove then 
			me:Move(startingpoint2) 
		else
			for creepHandle, creepClass in pairs(creepTable) do	
				if creepClass.spawned and creepClass.alive and creepClass.team == me.team and creepClass.health > 0 then
					if not closestCreep or (GetDistance2D(creepClass,endingpoint) - 25) < GetDistance2D(closestCreep,endingpoint) then
						closestCreep = creepClass
					end
					if closestCreep and GetDistance2D(me,closestCreep) <= 500 then
						local alfa = closestCreep.rotR
						local p = Vector(closestCreep.position.x + closestCreep.movespeed * math.cos(alfa), closestCreep.position.y + closestCreep.movespeed * math.sin(alfa), closestCreep.position.z)
						me:Move(p)
						if GetDistance2D(endingpoint,me) < 4600 and SleepCheck() then
							if GetDistance2D(me, closestCreep) > 35 and (GetDistance2D(me,endingpoint) + 50) < GetDistance2D(closestCreep,endingpoint) then
								me:Stop()
								Sleep(1500/me.movespeed - client.latency/1000)
							end
						end
					end
				end
			end
		end
	elseif client.gameTime < 0 and me.position ~= startingpoint and SleepCheck() then
		me:Move(startingpoint) Sleep(1000)
	end
end

function GetCreeps(me)
	local creeps = entityList:GetEntities({classId=CDOTA_BaseNPC_Creep_Lane,alive=true,visible=true})
	for _, dEntity in ipairs(creeps) do
		if dEntity.spawned and GetDistance2D(me, dEntity) < math.max(me.attackRange, 800) and not creepTable[dEntity.handle] then
			creepTable[dEntity.handle] = dEntity
		end	
	end
	for creepHandle, creepClass in pairs(creepTable) do
		if not creepClass.alive or GetDistance2D(me, creepClass) > math.max(me.attackRange, 800) then
			creepTable[creepHandle] = nil
		end
	end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me then 
			script:Disable()
		else
			statusText.visible = false
			disableText.visible = false
			reg = true
			myId = me.classId
			firstmove = false
			closestCreep = nil
			creepTable = {}
			script:RegisterEvent(EVENT_TICK, Main)
			script:UnregisterEvent(Load)
		end
	end	
end

function Close()
	statusText.visible = false
	disableText.visible = false
	myId = nil
	closestCreep = nil
	creepTable = {}
	if reg then
		script:UnregisterEvent(Main)
		script:RegisterEvent(EVENT_TICK, Load)	
		reg = false
	end
end

script:RegisterEvent(EVENT_CLOSE, Close)
script:RegisterEvent(EVENT_TICK, Load)
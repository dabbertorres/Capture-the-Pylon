--[[
	Capture the Pylon - dabbertorres
	Each team has a base (a pylon). In the middle there is another pylon.
	The goal is to capture the center pylon (run into it) and run back to your base.
	If you do that, you get a point. Do it 5 times, and your team wins!
]]
local player = {handle = nil, hasPylon = false}

local playerList = {}

local pylonODF = "nparr"
local pylon = nil
--path that the pylon to capture spawns at.
--Should ideally be directly in the middle of the map.
local pylonSpawn = "pylonSpawn"

local capturesToWin = 5

--the path Team one's pylon spawns at.
local teamOneBaseSpawn = "TeamOneSpawn"
local teamOneBase = nil
--the path Team two's pylon spawns at.
local teamTwoBaseSpawn = "TeamTwoSpawn"
local teamTwoBase = nil

local teamOneCaptures = 0
local teamTwoCaptures = 0
local bGameOver = false

function Receive(from, type, data)
	if type == 'p' then	--a player picked up the pylon
		playerList[tonumber(data)].hasPylon = true
		DisplayMessage("Player "..data.." picked up the pylon!")
	elseif type == 'c' then	--a player captured the pylon
		if tonumber(data) % 2 == 0 then	--team two captured it
			playerList[tonumber(data)].hasPylon = false	--remove pylon from player
			teamTwoCaptures = teamTwoCaptures + 1
			DisplayMessage("Player "..data.." captured the pylon for Team 2!")
		else	--team one captured it
			playerList[tonumber(data)].hasPylon = false	--remove pylon from player
			teamOneCaptures = teamOneCaptures + 1
			DisplayMessage("Player "..data.." captured the pylon for Team 1!")
		end
	elseif type == 'w' then	--a team won
		if data == "one" then
			DisplayMessage("Team 1 wins!")
		else
			DisplayMessage("Team 2 wins!")
		end
	end
end

function CreatePlayer(id, name, team)
	local p = {}
	setmetatable(p, player)
	p.handle = GetPlayerHandle(team)
	table.insert(playerList, team, p)
end

function DeletePlayer(id, name, team)
	--if player leaving is carrying the pylon, respawn it
	if playerList[team].hasPylon and IsHosting() then
		pylon = BuildObject(pylonODF, 0, pylonSpawn)
	end
	table.remove(playerList, team)
end

function Start()
	if IsHosting() then
		pylon = BuildObject(pylonODF, 0, pylonSpawn)
		teamOneBase = BuildObject(pylonODF, 0, teamOneBaseSpawn)
		teamTwoBase = BuildObject(pylonODF, 0, teamTwoBaseSpawn)
	
		--Team 1
		Ally(1, 3)
		Ally(1, 5)
		Ally(1, 7)
	
		Ally(3, 5)
		Ally(3, 7)
	
		Ally(5, 7)
	
		--Team 2
		Ally(2, 4)
		Ally(2, 6)
		Ally(2, 8)
	
		Ally(4, 6)
		Ally(4, 8)
	
		Ally(6, 8)
	
		LockAllies(true)
	end
end

function Update()
	if IsHosting() then
		if pylon ~= nil then	--pylon is not being carried
			for h in ObjectsInRange(5, pylon) do	--if a player captures the pylon
				if GetTeamNum(h) ~= 0 then
					playerList[GetTeamNum(h)].hasPylon = true
					RemoveObject(pylon)
					pylon = nil
					Send(0, 'p', GetTeamNum(h))
					DisplayMessage("Player "..GetTeamNum(h).." picked up the pylon!")
					break	--make sure we don't make two players 'have' the pylon
				end
			end
		else
			--Check team 1
			for h in ObjectsInRange(5, teamOneBase) do
				if GetTeamNum(h) ~= 0 and GetTeamNum(h) % 2 == 1 then
					if playerList[GetTeamNum(h)].hasPylon then
						playerList[GetTeamNum(h)].hasPylon = false	--remove pylon
						pylon = BuildObject(pylonODF, 0, pylonSpawn)	--respawn pylon
						Send(0, 'c', GetTeamNum(h))
						DisplayMessage("Player "..GetTeamNum(h).." captured the pylon for Team 1!")
						break
					end
				end
			end
		
		--Check team 2
			for h in ObjectsInRange(5, teamTwoBase) do
				if GetTeamNum(h) ~= 0 and GetTeamNum(h) % 2 == 0 then
					if playerList[GetTeamNum(h)].hasPylon then
						playerList[GetTeamNum(h)].hasPylon = false	--remove pylon
						pylon = BuildObject(pylonODF, 0, pylonSpawn)	--respawn pylon
						Send(0, 'c', GetTeamNum(h))
						DisplayMessage("Player "..GetTeamNum(h).." captured the pylon for Team 2!")
						break
					end
				end
			end
		end
	
		if teamOneCaptures >= capturesToWin and not bGameOver then
			Send(0, 'w', "one")
			teamOneCaptures = teamOneCaptures + 1
			DisplayMessage("Team 1 wins!")
			bGameOver = true
		elseif teamTwoCaptures >= capturesToWin and not bGameOver then
			Send(0, 'w', "two")
			teamTwoCaptures = teamTwoCaptures + 1
			DisplayMessage("Team 2 wins!")
			bGameOver = true
		end
	end
end

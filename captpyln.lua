--[[
	Capture the Pylon - dabbertorres
	Each team has a base (a pylon). In the middle there is another pylon.
	The goal is to capture the center pylon (run into it) and run back to your base.
	If you do that, you get a point. Do it 5 times, and your team wins!
]]
local Player = {hasPylon = false, name = nil}

local playerList = {}

local PYLON_ODF = "nparr"
local pylon = nil
--path that the pylon to capture spawns at.
--Should ideally be directly in the middle of the map.
local PYLON_SPAWN = "pylonSpawn"

local CAPTURES_TO_WIN = 5

--the path Team one's pylon spawns at.
local TEAM_ONE_BASE_SPAWN = "TeamOneSpawn"
local teamOneBase = nil
--the path Team two's pylon spawns at.
local TEAM_TWO_BASE_SPAWN = "TeamTwoSpawn"
local teamTwoBase = nil

local teamOneCaptures = 0
local teamTwoCaptures = 0
local gameOver = false

function Receive(from, type, ...)
	if type == 'p' then	--a player picked up the pylon
		local playerNum = ...
		if playerList[playerNum] ~= nil then
			playerList[playerNum].hasPylon = true
			DisplayMessage("Player "..playerNum..", "..playerList[playerNum].name..", picked up the pylon!")
		end
	elseif type == 'c' then	--a player captured the pylon
		local playerNum = ...
		if playerList[playerNum] ~= nil then
			playerList[playerNum].hasPylon = false	--remove pylon from player
			DisplayMessage("Player "..playerNum..", "..playerList[playerNum].name..", captured the pylon for Team "..((playerNum % 2 == 1) and 1 or 2).."!")

			if playerNum % 2 == 0 then	--team two captured it
				teamTwoCaptures = teamTwoCaptures + 1
			else	--team one captured it
				teamOneCaptures = teamOneCaptures + 1
			end
		end
	elseif type == 'w' then	--a team won
		local teamNum = ...
		DisplayMessage("Team "..teamNum.." wins!")
		gameOver = true
	elseif type == 'u' then	--update captures
		local t, c = ...
		if t == 1 then
			teamOneCaptures = c
		else
			teamTwoCaptures = c
		end
	elseif type == 'l' then	--player updates
		if select('#', ...) >= 3 then
			local p, hp, n = ...
			playerList[p].hasPylon = hp
			playerList[p].name = n
		else
			playerList[p] = nil
		end
	elseif type == 'r' then	--reset game
		teamOneCaptures = 0
		teamTwoCaptures = 0
		gameOver = false
	end
end

function CreatePlayer(id, name, team)
	setmetatable(playerList[team], Player)
	playerList[team].hasPylon = false
	playerList[team].name = name
end

function AddPlayer(id, name, team)
	if isHosting() then
		Send(id, 'u', 1, teamOneCaptures)
		Send(id, 'u', 2, teamTwoCaptures)

		for i = 1, 8 do
			if playerList[i] ~= nil then
				Send(id, 'l', i, playerList[i].hasPylon, playerList[i].name)
			else
				Send(id, 'l', i)
			end
		end
	end
end

function DeletePlayer(id, name, team)
	--if player leaving is carrying the pylon, respawn it
	if playerList[team].hasPylon then
		playerList[team].hasPylon = false
		if isHosting() then
			pylon = BuildObject(PYLON_ODF, 0, PYLON_SPAWN)
		end
	end
	playerList[team] = nil
end

function Start()
	if IsHosting() then
		pylon = BuildObject(PYLON_ODF, 0, PYLON_SPAWN)
		teamOneBase = BuildObject(PYLON_ODF, 0, TEAM_ONE_BASE_SPAWN)
		teamTwoBase = BuildObject(PYLON_ODF, 0, TEAM_TWO_BASE_SPAWN)

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

function Update(timestep)
	if IsHosting() then
		if pylon ~= nil then	--pylon is not being carried
			for h in ObjectsInRange(5, pylon) do	--if a player captures the pylon
				if GetTeamNum(h) ~= 0 then
					playerList[GetTeamNum(h)].hasPylon = true
					RemoveObject(pylon)
					pylon = nil
					Send(0, 'p', GetTeamNum(h))
					break	--make sure we don't make two players 'have' the pylon
				end
			end
		else
			--Check team 1
			for h in ObjectsInRange(5, teamOneBase) do
				if GetTeamNum(h) ~= 0 and GetTeamNum(h) % 2 == 1 then
					if playerList[GetTeamNum(h)].hasPylon then
						playerList[GetTeamNum(h)].hasPylon = false	--remove pylon
						pylon = BuildObject(PYLON_ODF, 0, PYLON_SPAWN)	--respawn pylon
						Send(0, 'c', GetTeamNum(h))
						break
					end
				end
			end

		--Check team 2
			for h in ObjectsInRange(5, teamTwoBase) do
				if GetTeamNum(h) ~= 0 and GetTeamNum(h) % 2 == 0 then
					if playerList[GetTeamNum(h)].hasPylon then
						playerList[GetTeamNum(h)].hasPylon = false	--remove pylon
						pylon = BuildObject(PYLON_ODF, 0, PYLON_SPAWN)	--respawn pylon
						Send(0, 'c', GetTeamNum(h))
						break
					end
				end
			end
		end

		if (teamOneCaptures >= CAPTURES_TO_WIN or teamTwoCaptures >= CAPTURES_TO_WIN) and not gameOver then
			Send(0, 'w', (teamOneCaptures >= CAPTURES_TO_WIN) and 1 or 2)	--equivalent to teamOneCaptures >= CAPTURES_TO_WIN ? 1 : 2
			gameOver = true
		end
	end
end

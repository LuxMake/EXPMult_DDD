--EXP Multiplier Mod

LUAGUI_NAME = "DDD Exp Multiplier"
LUAGUI_AUTH = "Lux"
LUAGUI_DESC = "An exp multiplier mod for Dream Drop Distance. Hold Left on D-Pad for 3 seconds on title screen to change mult. Multipliers are also loaded from the save file."

local EXP_MULT = 2 --Change this to change multiplier

--Memory Addresses
local _expAddr = {0x7B2A94, 0x7B2C34} --Address for exp table
local _saveAddr = {0xA41D94, 0xA41614} --Sora destiny islands story as not all flags are used
local _roomAddr = {0x9CF731, 0x9CF721} --Current room
local _dPad = {0x9E9E98, 0x9E9E88} --Which dpad button is being held
local _isEpic = 0x7F7109
local _isSteam = 0x7F7041

--Mod States
local gameVer = 0 --What version are we running
local _expTbl = {} --Store vanilla table values
local canExecute = false
local _multApplied = false

--Manage title screen features
local _gameState = 0 --0: Mod init; 1: On Title Screen; 2: Game started
local _onTitle = true
local _saveChecked = false
local _dPadHeld = 0
local _holdTimer = 180

function GameVersion()
  if ReadLong(_isEpic) == 0x7265737563697065 then
    ConsolePrint("Running Exp Multiplier for EGS")
    gameVer = 2
    return true
  elseif ReadLong(_isSteam) == 0x7265737563697065 then
    ConsolePrint("Running Exp Multiplier for Steam")
    gameVer = 1
    return true
  end
  return false
end

function _OnInit()
	if GameVersion() then
		canExecute = true
		if ReadByte(_expAddr[gameVer]) == 0x28 then
			ReadExpTable()
			ConsolePrint("Exp Multiplier set to "..tostring(EXP_MULT).."x")
		else
			ConsolePrint("Exp Multiplier already set; cannot write to table")
		end
	else
		ConsolePrint("Dream Drop Distance not detected. Make sure your game is up to date.")
	end
end

function _OnFrame()
	if canExecute then
		if _onTitle then
			if ReadByte(_roomAddr[gameVer]) ~= 0xFF then --No longer on title screen
				_onTitle = false
				CheckSavedMultiplier()
				return
			end

			if ReadByte(_dPad[gameVer]) == 0x80 then --Are we holding the dpad button
				_dPadHeld = _dPadHeld + 1
				if _dPadHeld > _holdTimer then --Held for long enough; increment multiplier
					EXP_MULT = EXP_MULT+1
					if EXP_MULT > 10 then --Cap multiplier at 10
						EXP_MULT = 1
					end
					ConsolePrint("Exp Multiplier set to "..tostring(EXP_MULT).."x")
					_dPadHeld = 0 --Reset timer
				end
			else --Button released; reset timer
				_dPadHeld = 0
			end
		else
			if not _saveChecked then
				CheckSavedMultiplier()
			end
			if not _multApplied then
				WriteExpTable()
			end
		end
	end
end

function CheckSavedMultiplier() --Read multiplier from the save file
	if ReadByte(_saveAddr[gameVer]+0x07) == 0x00 then
		WriteByte(_saveAddr[gameVer]+0x07, EXP_MULT)
		ConsolePrint("Saved exp multiplier to game.")
	else
		EXP_MULT = ReadByte(_saveAddr[gameVer]+0x07)
		ConsolePrint("Loaded exp multiplier from file.")
		ConsolePrint("Exp Multiplier set to "..tostring(EXP_MULT).."x")
	end
	_saveChecked = true
end

function ReadExpTable()
	for x=0, 98 do
		local _nextAddr = _expAddr[gameVer]+(x*4)
		local _tableVal = ReadInt(_nextAddr)
		table.insert(_expTbl, _tableVal)
	end
end

function WriteExpTable()
	local _realExpMult = 1/EXP_MULT
	if #_expTbl > 0 then --Do not run if we could not collect the exp table
		for x=0, 98 do
			local _nextAddr = _expAddr[gameVer]+(x*4)
			WriteInt(_nextAddr, _expTbl[x+1]*_realExpMult)
		end
		ConsolePrint("Successfully applied "..tostring(EXP_MULT).."x multiplier.")
	else
		ConsolePrint("Exp Table could not be collected. Did the multiplier mod already run?")
	end
	_multApplied = true
end
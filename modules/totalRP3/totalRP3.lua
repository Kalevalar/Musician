Musician.TRP3 = LibStub("AceAddon-3.0"):NewAddon("Musician.TRP3", "AceEvent-3.0")

local MODULE_NAME = "TRP3"
Musician.AddModule(MODULE_NAME)

local playersPlayingMusic = {}
local IS_PLAYING_TIMEOUT = 3

function Musician.TRP3:OnEnable()
	if TRP3_API then
		Musician.Utils.Debug(MODULE_NAME, "Total RP3 module started.")
		Musician.TRP3.HookPlayerNames()
		Musician.TRP3.HookNamePlates()
		Musician.TRP3.HookPlayerMap()
		TRP3_API.Events.registerCallback("WORKFLOW_ON_FINISH", function()
			Musician.TRP3.HookTooltip()
		end)
		Musician.TRP3:RegisterMessage(Musician.Events.SongChunk, Musician.TRP3.OnSongChunk)
	end
end

--- Return RP display name for player
-- @param player (string)
-- @return (string)
function Musician.TRP3.GetRpName(player)
	player = Musician.Utils.NormalizePlayerName(player)
	local trpPlayer = AddOn_TotalRP3.Player.static.CreateFromCharacterID(player)
	return trpPlayer:GetCustomColoredRoleplayingNamePrefixedWithIcon()
end

--- Hook player name formatting
--
function Musician.TRP3.HookPlayerNames()
	Musician.Utils.FormatPlayerName = Musician.TRP3.GetRpName
end

--- Hook TRP player tooltip
--
function Musician.TRP3.HookTooltip()
	Musician.Utils.Debug(MODULE_NAME, "Adding tooltip support.")

	-- Add Musician version to Total RP player tooltip
	TRP3_CharacterTooltip:HookScript("OnShow", function(t)
		Musician.Registry.UpdateTooltipInfo(TRP3_CharacterTooltip, t.target, TRP3_API.ui.tooltip.getSmallLineFontSize())
	end)

	--- Update Total RP player tooltip to add missing Musician client version, if applicable.
	hooksecurefunc(Musician.Registry, "UpdatePlayerTooltip", function(player)
		if TRP3_CharacterTooltip ~= nil and TRP3_CharacterTooltip.target == player then
			Musician.Registry.UpdateTooltipInfo(TRP3_CharacterTooltip, player, TRP3_API.ui.tooltip.getSmallLineFontSize())
		end
	end)
end

--- Hook TRP player nameplates (standard)
--
function Musician.TRP3.HookNamePlates()
	if AddOn_TotalRP3 and AddOn_TotalRP3.NamePlates and AddOn_TotalRP3.NamePlates.BlizzardDecoratorMixin then
		Musician.Utils.Debug(MODULE_NAME, "Adding nameplate support.")
		hooksecurefunc(AddOn_TotalRP3.NamePlates.BlizzardDecoratorMixin, "UpdateNamePlateName", function(self, namePlate)
			Musician.NamePlates.UpdateNoteIcon(namePlate)
		end)
	end
end

--- Returns true if the player is currently playing some music
-- @param player (string)
-- @return (boolean)
function Musician.TRP3.IsPlayingMusic(player)
	if not(playersPlayingMusic[player]) then return false end

	if playersPlayingMusic[player] + IS_PLAYING_TIMEOUT < GetTime() then
		playersPlayingMusic[player] = nil
		return false
	end

	return true
end

--- OnSongChunk
--
function Musician.TRP3.OnSongChunk(event, sender, mode, songId, chunkDuration, playtimeLeft, posY, posX, posZ, instanceID, guid)
	local now = GetTime()

	playersPlayingMusic[sender] = now

	local playerName, time
	for playerName, time in pairs(playersPlayingMusic) do
		if time + IS_PLAYING_TIMEOUT < now then
			playersPlayingMusic[playerName] = nil
		end
	end
end

--- onPinUpdate
--
local function onPinUpdate(self, elapsed)
	local isPlayingMusic = Musician.TRP3.IsPlayingMusic(self.musicianPlayer)
	local r, g, b, a = unpack(self.musicianColor)

	if isPlayingMusic then
		self.musicianBlinkTime = self.musicianBlinkTime + elapsed
		local blink = abs(1 - 2 * (4 * self.musicianBlinkTime % 1))
		self.Texture:SetVertexColor(r, g, b, Lerp(.33, 1, blink))
	elseif self.musicianIsPlayingMusic ~= isPlayingMusic then
		self.Texture:SetVertexColor(r, g, b, a)
	end

	self.musicianIsPlayingMusic = isPlayingMusic
end

--- Hook TRP player map
--
function Musician.TRP3.HookPlayerMap()

	if TRP3_PlayerMapPinMixin then

		--- TRP3_PlayerMapPinMixin.GetDisplayDataFromPoiInfo
		--
		if TRP3_PlayerMapPinMixin.GetDisplayDataFromPoiInfo then
			local TRP3_PlayerMapPinMixin_GetDisplayDataFromPoiInfo = TRP3_PlayerMapPinMixin.GetDisplayDataFromPoiInfo
			TRP3_PlayerMapPinMixin.GetDisplayDataFromPoiInfo = function(self, poiInfo, ...)
				local displayData = TRP3_PlayerMapPinMixin_GetDisplayDataFromPoiInfo(self, poiInfo, ...)

				local sender = poiInfo.sender
				displayData.musicianIsRegistered = Musician.Registry.PlayerIsRegistered(sender)
				displayData.musicianPlayer = sender

				-- Check if the player is actually playing music
				displayData.musicianIsPlayingMusic = false
				if playersPlayingMusic[sender] then
					if playersPlayingMusic[sender] + IS_PLAYING_TIMEOUT < GetTime() then
						playersPlayingMusic[sender] = nil
					else
						displayData.musicianIsPlayingMusic = true
					end
				end

				-- Slightly raise priority if the player has no special relationship with this one
				if displayData.musicianIsRegistered and displayData.categoryPriority == -1 then
					if displayData.musicianIsPlayingMusic then
						displayData.categoryPriority = 99
					else
						displayData.categoryPriority = -.5
					end
				end

				return displayData
			end
		end

		--- TRP3_PlayerMapPinMixin.Decorate
		--
		if TRP3_PlayerMapPinMixin.Decorate then
			local TRP3_PlayerMapPinMixin_Decorate = TRP3_PlayerMapPinMixin.Decorate
			TRP3_PlayerMapPinMixin.Decorate = function(self, displayData, ...)

				local newDisplayData = Mixin({}, displayData)
				local isPlayingMusic = false

				-- Append note icon to player name and replace pin texture by a musical note
				if displayData.musicianIsRegistered then
					local icon

					isPlayingMusic = Musician.TRP3.IsPlayingMusic(displayData.musicianPlayer)
					if isPlayingMusic then
						icon = Musician.Utils.GetChatIcon(Musician.IconImages.Note, 1, .82, 0)
					else
						icon = Musician.Utils.GetChatIcon(Musician.IconImages.Note)
					end

					newDisplayData.playerName = newDisplayData.playerName .. " " .. icon
					self.Texture:SetTexture("Interface\\AddOns\\Musician\\ui\\textures\\map-pin.blp")
					self.HighlightTexture:SetTexture("Interface\\AddOns\\Musician\\ui\\textures\\map-pin-highlight.blp")
				end

				-- Decorate
				TRP3_PlayerMapPinMixin_Decorate(self, newDisplayData, ...)

				-- Attach OnUpdate script if registered
				if displayData.musicianIsRegistered then
					self.musicianBlinkTime = 0
					self.musicianColor = { self.Texture:GetVertexColor() }
					self.musicianPlayer = displayData.musicianPlayer
					self:SetScript("OnUpdate", onPinUpdate)
				else
					self:SetScript("OnUpdate", nil)
				end
			end
		end
	end

end

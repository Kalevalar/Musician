Musician = LibStub("AceAddon-3.0"):NewAddon("Musician", "AceEvent-3.0")

function Musician:OnInitialize()
	Musician.Utils.Print(string.gsub(Musician.Msg.STARTUP, "{version}", Musician.Utils.Highlight(GetAddOnMetadata("Musician", "Version"))))

	-- Init settings
	local defaultSettings = {
		minimapPosition = 154,
		mutedPlayers = {}
	}
	if Musician_Settings ~= nil then
		local k, v
		for k,v in pairs(Musician_Settings) do defaultSettings[k] = v end
	end
	Musician_Settings = defaultSettings

	Musician.songs = {}
	Musician.sourceSong = nil
	Musician.songIsPlaying = false
	Musician.globalMute = false
	Musician.nextSongId = 1

	Musician.Comm.Init()
	Musician.Registry.Init()
	Musician.SetupHooks()
	Musician.Preloader.Init()

	C_Timer.NewTicker(0.5, function() Musician.Utils.MuteGameMusic() end)

	MusicianFrame.Init()
	MusicianButton.Init()
	Musician.TrackEditor.Init()

	Musician:RegisterMessage(Musician.Events.SongStop, Musician.OnSongStopped)
	Musician:RegisterMessage(Musician.Events.SongPlay, Musician.OnSongPlayed)
	Musician:RegisterMessage(Musician.Events.SongImportSucessful, Musician.OnSourceImportSuccessful)
	Musician:RegisterMessage(Musician.Events.SongImportFailed, Musician.OnSourceImportFailed)

	-- @var frame (Frame)
	Musician.playerFrame = CreateFrame("Frame")
	Musician.playerFrame:SetFrameStrata("HIGH")
	Musician.playerFrame:EnableMouse(false)
	Musician.playerFrame:SetMovable(false)

	Musician.playerFrame:SetScript("OnUpdate", Musician.OnUpdate)

	-- /musician command
	SlashCmdList["MUSICIAN"] = function(cmd)

		cmd = strlower(strtrim(cmd))

		-- Stop all music currently playing
		if cmd == "stop" or cmd == "panic" then

			if Musician.sourceSong then
				Musician.sourceSong:Stop()
			end

			local song, player
			for player, song in pairs(Musician.songs) do
				song:Stop()
			end

			-- Show main window
		elseif cmd == "show" or cmd == "" then
			MusicianFrame:Show()
			MusicianFrameSource:SetFocus()
		end
	end

	SLASH_MUSICIAN1 = "/musician"
	SLASH_MUSICIAN2 = "/music"
	SLASH_MUSICIAN3 = "/mus"

	-- /stopmusic command
	SlashCmdList["STOPMUSIC"] = function()
		SlashCmdList["MUSICIAN"]("stop")
	end

	SLASH_STOPMUSIC1 = "/stopmusic"
	SLASH_STOPMUSIC2 = "/stopmus"
	SLASH_STOPMUSIC3 = "/musicstop"
	SLASH_STOPMUSIC4 = "/musstop"
end

--- Stop a song playing by a player
-- @param playerName (string)
-- @param remove (boolean)
function Musician.StopPlayerSong(playerName, remove)
	if Musician.songs[playerName] then
		Musician.songs[playerName]:Stop()
		if remove then
			Musician.songs[playerName] = nil
			collectgarbage()
		end
	end
end

--- Handle playing song
-- @param event (table)
-- @param song (Musician.Song)
function Musician.OnSongPlayed(event, song)
	local playerName = song.player

	if Musician.Utils.PlayerIsMyself(playerName) then
		Musician.songIsPlaying = true
		Musician.Comm.isPlaySent = false
		SendChatMessage(Musician.Utils.GetPromoEmote(), "EMOTE")
	end

	Musician.Comm:SendMessage(Musician.Events.RefreshFrame)
end

--- Handle stopped song
-- @param event (table)
-- @param song (Musician.Song)
function Musician.OnSongStopped(event, song)
	local playerName = song.player

	if playerName ~= nil and Musician.songs[playerName] ~= nil then
		if Musician.Utils.PlayerIsMyself(playerName) then
			Musician.songIsPlaying = false
			Musician.Comm.isStopSent = false
		end
		Musician.Utils.MuteGameMusic()
	end

	Musician.Comm:SendMessage(Musician.Events.RefreshFrame)
end

--- Import song from encoded string
-- @param str (string)
function Musician.ImportSource(str)
	-- Remove previously importing song
	if Musician.importingSong ~= nil then
		Musician.importingSong.importing = false
		Musician.importingSong = nil
	end

	Musician.importingSong = Musician.Song.create()
	collectgarbage()
	Musician.importingSong:Import(str, true)
end

--- Handle successful source import
--
function Musician.OnSourceImportSuccessful()
	-- Stop previous source song being played
	if Musician.sourceSong and  Musician.sourceSong:IsPlaying() then
		Musician.sourceSong:Stop()
	end

	Musician.sourceSong = Musician.importingSong
	Musician.importingSong = nil
	collectgarbage()

	Musician.Comm:SendMessage(Musician.Events.RefreshFrame)
	Musician.Comm:SendMessage(Musician.Events.SourceSongLoaded)
end

--- Handle failed source import
--
function Musician.OnSourceImportFailed()
	Musician.importingSong = nil
	collectgarbage()
	Musician.Comm:SendMessage(Musician.Events.RefreshFrame)
end

--- Perform all on-frame actions
-- @param frame (Frame)
-- @param elapsed (number)
function Musician.OnUpdate(frame, elapsed)
	Musician.Preloader.OnUpdate(elapsed)

	if Musician.sourceSong then
		Musician.sourceSong:OnUpdate(elapsed)
	end

	if Musician.importingSong then
		Musician.importingSong:OnUpdate(elapsed)
	end

	if Musician.streamingSong then
		Musician.streamingSong:OnUpdate(elapsed)
	end

	local song, player
	for player, playerSong in pairs(Musician.songs) do
		playerSong:OnUpdate(elapsed)
	end
end

--- Mute or unmute a player
-- @param playerName (string)
-- @param isMuted (boolean)
function Musician.MutePlayer(playerName, isMuted)
	if Musician.PlayerIsMuted(playerName) == isMuted then
		return
	end

	local icon, msg
	if isMuted then
		Musician_Settings.mutedPlayers[playerName] = true
		icon = Musician.Icons.PlayerMuted
		msg = Musician.Msg.PLAYER_IS_MUTED
	else
		Musician_Settings.mutedPlayers[playerName] = nil
		icon = Musician.Icons.PlayerUnmuted
		msg = Musician.Msg.PLAYER_IS_UNMUTED
	end

	msg = msg.gsub(msg, "{player}", Musician.Utils.Highlight(Musician.Utils.GetPlayerLink(playerName)))
	msg = msg.gsub(msg, "{icon}", Musician.Utils.GetChatIcon(icon))
	Musician.Utils.Print(msg)
end

--- Returns true if the player is muted
-- @param playerName (string)
-- @return (boolean)
function Musician.PlayerIsMuted(playerName)
	return Musician_Settings.mutedPlayers[playerName] == true
end

--- Setup hooks
--
function Musician.SetupHooks()

	-- Hyperlinks
	--

	hooksecurefunc("ChatFrame_OnHyperlinkShow", function(self, link, text, button)
		local args = { strsplit(':', link) }
		if args[1] == "musician" then
			-- Stop current song for player
			if args[2] == "stop" then
				PlaySound(80)
				Musician.StopPlayerSong(args[3])
			-- Mute player
			elseif args[2] == "mute" then
				PlaySound(80)
				Musician.MutePlayer(args[3], true)
			-- Unmute player
			elseif args[2] == "unmute" then
				PlaySound(80)
				Musician.MutePlayer(args[3], false)
			-- Seek source song
			elseif args[2] == "seek" and Musician.sourceSong ~= nil then
				Musician.sourceSong:Seek(args[3])
			end
		end
	end)

	local HookedSetHyperlink = ItemRefTooltip.SetHyperlink
	function ItemRefTooltip:SetHyperlink(link, ...)
		if (link and link:sub(0, 8) == "musician") then
			return
		end
		return HookedSetHyperlink(self, link, ...)
	end

	-- Workaround for the CanReportPlayer bug with crafted emotes
	--

	local HookedCanReportPlayer = C_ChatInfo.CanReportPlayer
	C_ChatInfo.CanReportPlayer = function(playerLocation)
		local canReport = false
		pcall(function()
			canReport = HookedCanReportPlayer(playerLocation)
		end)
		return canReport
	end

	-- Player dropdown menus
	--

	-- Add player dropdown menu options
	--
		
	hooksecurefunc("UnitPopup_ShowMenu", function(dropdownMenu, which, unit, name, userData)
		if UIDROPDOWNMENU_MENU_LEVEL == 1 and (which == "PARTY" or which == "PLAYER" or which == "RAID_PLAYER" or which == "FRIEND" or which == "FRIEND_OFFLINE" or which == "TARGET") then
			local isPlayer = dropdownMenu.unit and UnitIsPlayer(dropdownMenu.unit) or dropdownMenu.chatTarget
			local isMyself = false
			local isMuted = false
			local isPlaying = false
			local isRegistered = false
			local player

			if isPlayer then
				if dropdownMenu.chatTarget then
					player = Musician.Utils.NormalizePlayerName(dropdownMenu.chatTarget)
				else
					if dropdownMenu.server then
						player = dropdownMenu.name .. '-' .. dropdownMenu.server
					else
						player = Musician.Utils.NormalizePlayerName(dropdownMenu.name)
					end
				end

				isMyself = Musician.Utils.PlayerIsMyself(player)
				isMuted = Musician.PlayerIsMuted(player)
				isPlaying = Musician.songs[player] ~= nil and Musician.songs[player]:IsPlaying()
				isRegistered = Musician.Registry.players[player] ~= nil
			end

			local items = {
				{
					value = "MUSICIAN_SUBSECTION_TITLE_MUTED",
					text = Musician.Msg.PLAYER_MENU_TITLE .. " " .. Musician.Utils.GetChatIcon(Musician.Icons.PlayerMuted),
					isTitle = true,
					visible = isPlayer and isRegistered and not(isMyself) and isMuted
				},
				{
					value = "MUSICIAN_SUBSECTION_TITLE_UNMUTED",
					text = Musician.Msg.PLAYER_MENU_TITLE .. " " .. Musician.Utils.GetChatIcon(Musician.Icons.PlayerUnmuted),
					isTitle = true,
					visible = isPlayer and isRegistered and not(isMyself) and not(isMuted)
				},
				{
					value = "MUSICIAN_STOP",
					text = Musician.Msg.PLAYER_MENU_STOP_CURRENT_SONG,
					visible = isPlayer and isRegistered and not(isMyself) and isPlaying and not(isMuted)
				},
				{
					value = "MUSICIAN_MUTE",
					text = Musician.Msg.PLAYER_MENU_MUTE,
					visible = isPlayer and isRegistered and not(isMyself) and not(isMuted)
				},
				{
					value = "MUSICIAN_UNMUTE",
					text = Musician.Msg.PLAYER_MENU_UNMUTE,
					visible = isPlayer and isRegistered and not(isMyself) and isMuted
				},
			}

			if isPlayer and isRegistered and not(isMyself) then
				UIDropDownMenu_AddSeparator(1)
			end

			local item
			for _, item in pairs(items) do
				if item.visible then
					local info = UIDropDownMenu_CreateInfo()
					info.text = item.text
					info.isTitle = item.isTitle
					info.func = UnitPopup_OnClick
					info.notCheckable = true
					info.value = item.value
					info.arg1 = dropdownMenu
					UIDropDownMenu_AddButton(info)
				end
			end
		end
	end)

	-- Handle actions in player dropdown menus
	--

	hooksecurefunc("UnitPopup_OnClick", function(self)
		local dropdownMenu = self.arg1
		local button = self.value
		local isPlayer = dropdownMenu and (dropdownMenu.unit and UnitIsPlayer(dropdownMenu.unit) or dropdownMenu.chatTarget)
		local player

		if isPlayer then
			if dropdownMenu.chatTarget then
				player = Musician.Utils.NormalizePlayerName(dropdownMenu.chatTarget)
			else
				if dropdownMenu.server then
					player = dropdownMenu.name .. '-' .. dropdownMenu.server
				else
					player = Musician.Utils.NormalizePlayerName(dropdownMenu.name)
				end
			end

			if button == "MUSICIAN_MUTE" then
				Musician.MutePlayer(player, true)
			elseif button == "MUSICIAN_UNMUTE" then
				Musician.MutePlayer(player, false)
			elseif button == "MUSICIAN_STOP" then
				Musician.StopPlayerSong(player)
			end
		end
	end)

	-- Add muted/unmuted status to player messages when playing
	-- Add stop button to "Player plays music" emote
	local messageEventFilter = function(self, event, msg, player, arg3, arg4, arg5, pflag, ...)

		local fullPlayerName = Musician.Utils.NormalizePlayerName(player)

		-- "Player is playing music."
		if Musician.Utils.HasPromoEmote(msg) and event == "CHAT_MSG_EMOTE" then

			-- Music is loaded and actually playing
			if Musician.songs[fullPlayerName] ~= nil and Musician.songs[fullPlayerName]:IsPlaying() then

				-- Ignore emote if the player has already been notified
				if Musician.songs[fullPlayerName].notified then
					return true
				end

				-- Remove the "promo" part of the emote and mark as already notified
				Musician.songs[fullPlayerName].notified = true
				msg = Musician.Msg.EMOTE_PLAYING_MUSIC

				-- Add action link if playing music (and not current player)
				if not(Musician.Utils.PlayerIsMyself(fullPlayerName)) then
					-- Stop music
					if not(Musician.PlayerIsMuted(fullPlayerName)) then
						local stopAction = Musician.Utils.Highlight(Musician.Utils.GetLink("musician", Musician.Msg.STOP, "stop", fullPlayerName), 'FF0000')
						msg = msg .. " " .. Musician.Utils.Highlight('[') .. stopAction .. Musician.Utils.Highlight(']')
					-- Unmute player
					else
						local unmuteAction = Musician.Utils.Highlight(Musician.Utils.GetLink("musician", Musician.Msg.UNMUTE, "unmute", fullPlayerName), '00FF00')
						msg = msg .. " " .. Musician.Utils.Highlight('[') .. unmuteAction .. Musician.Utils.Highlight(']')
					end
				end

			-- Music is not loaded
			else
				-- Player is not in the registry (other server)
				if Musician.Registry.players[fullPlayerName] == nil then
					msg = Musician.Msg.EMOTE_PLAYING_MUSIC .. " " .. Musician.Utils.Highlight(Musician.Msg.EMOTE_PLAYER_OTHER_REALM, 'FF0000')
				-- Song has not been loaded
				else
					return true
				end
			end
		end

		-- Add muted/unmuted flag if currently playing music
		if Musician.songs[fullPlayerName] ~= nil then
			if pflag and _G["CHAT_FLAG_" .. pflag] then
				if Musician.PlayerIsMuted(fullPlayerName) then
					_G["CHAT_FLAG_" .. pflag .. "_MUSICIAN_MUTED"] = _G["CHAT_FLAG_" .. pflag] .. CHAT_FLAG_MUSICIAN_MUTED
					pflag = pflag .. "_MUSICIAN_MUTED"
				else
					_G["CHAT_FLAG_" .. pflag .. "_MUSICIAN_UNMUTED"] = _G["CHAT_FLAG_" .. pflag] .. CHAT_FLAG_MUSICIAN_UNMUTED
					pflag = pflag .. "_MUSICIAN_UNMUTED"
				end
			else
				if Musician.PlayerIsMuted(fullPlayerName) then
					pflag = "MUSICIAN_MUTED"
				else
					pflag = "MUSICIAN_UNMUTED"
				end
			end
		end

		return false, msg, player, arg3, arg4, arg5, pflag, ...
	end

	CHAT_FLAG_MUSICIAN_MUTED = Musician.Utils.GetChatIcon(Musician.Icons.PlayerMuted)
	CHAT_FLAG_MUSICIAN_UNMUTED = Musician.Utils.GetChatIcon(Musician.Icons.PlayerUnmuted)

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", messageEventFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", messageEventFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", messageEventFilter)
end



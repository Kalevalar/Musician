Musician = LibStub("AceAddon-3.0"):NewAddon("Musician", "AceEvent-3.0")

local MODULE_NAME = "Main"
Musician.modules = { MODULE_NAME } -- All modules

local tipsAndTricks = {}

--- OnInitialize
--
function Musician:OnInitialize()
	Musician.Utils.Print(string.gsub(Musician.Msg.STARTUP, "{version}", Musician.Utils.Highlight(GetAddOnMetadata("Musician", "Version"))))

	-- Init settings
	local defaultSettings = {
		minimap = {
			minimapPos = 154,
			hide = false
		},
		nextSongId = 0,
		enableEmote = true,
		enableEmotePromo = true,
		emoteHintShown = false,
		enableTipsAndTricks = true,
		debug = {},
		mutedPlayers = {}
	}

	Musician_Settings = Mixin(defaultSettings, Musician_Settings or {})

	Musician.songs = {}
	Musician.sourceSong = nil
	Musician.globalMute = false

	Musician.Comm.Init()
	Musician.Registry.Init()
	Musician.SetupHooks()
	Musician.Preloader.Init()

	C_Timer.NewTicker(0.5, function() Musician.Utils.MuteGameMusic() end)
	Musician:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(1, function() Musician.Utils.MuteGameMusic(true) end)
	end)

	MusicianFrame.Init()
	MusicianButton.Init()
	Musician.TrackEditor.Init()
	Musician.KeyboardUtils.Init()
	Musician.KeyboardConfig.Init()
	Musician.Live.Init()
	Musician.Keyboard.Init()
	Musician.Options.Init()

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
	SlashCmdList["MUSICIAN"] = Musician.RunCommandLine

	SLASH_MUSICIAN1 = "/musician"
	SLASH_MUSICIAN2 = "/music"
	SLASH_MUSICIAN3 = "/mus"
end

--- Add a module
-- @param moduleName (string)
function Musician.AddModule(moduleName)
	table.insert(Musician.modules, moduleName)
end

--- Get command definitions
-- @return (table)
function Musician.GetCommands()
	local commands = {}

	-- Show main window

	table.insert(commands, {
		command = { "", "show", "import" },
		text = Musician.Msg.COMMAND_SHOW,
		func = function()
			MusicianFrame:Show()
		end
	})

	-- Play/stop song

	table.insert(commands, {
		command = { "play", "tplay", "toggleplay" },
		text = Musician.Msg.COMMAND_PLAY,
		func = Musician.Comm.TogglePlaySong
	})

	-- Stop playing song

	table.insert(commands, {
		command = { "stop" },
		text = Musician.Msg.COMMAND_STOP,
		func = Musician.Comm.StopSong
	})

	-- Preview/stop previewing song

	table.insert(commands, {
		command = {
			"preview", "previewplay", "playpreview",
			"tpreview", "tpreviewplay", "tplaypreview", "togglepreviewplay", "toggleplaypreview",
			"test", "testplay", "playtest"
		},
		text = Musician.Msg.COMMAND_PREVIEW_PLAY,
		func = function(arg)
			if Musician.sourceSong then
				if Musician.sourceSong:IsPlaying() then
					Musician.sourceSong:Stop()
				else
					Musician.sourceSong:Play()
				end
			end
		end
	})

	-- Stop previewing song

	table.insert(commands, {
		command = {
			"previewstop", "stoppreview",
			"teststop", "stoptest"
		},
		text = Musician.Msg.COMMAND_PREVIEW_STOP,
		func = function(arg)
			if Musician.sourceSong and Musician.sourceSong:IsPlaying() then
				Musician.sourceSong:Stop()
			end
		end
	})

	-- Open track editor

	table.insert(commands, {
		command = { "edit", "tracks" },
		text = Musician.Msg.COMMAND_SONG_EDITOR,
		func = MusicianFrame.TrackEditor
	})

	-- Show live keyboard

	table.insert(commands, {
		command = { "live", "keyboard" },
		text = Musician.Msg.COMMAND_LIVE_KEYBOARD,
		func = function()
			MusicianFrameSource:ClearFocus()
			Musician.Keyboard.Show()
		end
	})

	-- Configure keyboard

	table.insert(commands, {
		command = {
			"setupkeyboard", "keyboardsetup",
			"configkeyboard", "keyboardconfig"
		},
		text = Musician.Msg.COMMAND_CONFIGURE_KEYBOARD,
		func = function()
			MusicianFrameSource:ClearFocus()
			MusicianKeyboardConfig:Show()
		end
	})

	-- Live demo mode

	table.insert(commands, {
		command = {
			"livedemo", "demolive",
			"keyboarddemo", "demokeyboard",
		},
		params = Musician.Msg.COMMAND_LIVE_DEMO_PARAMS,
		text = Musician.Msg.COMMAND_LIVE_DEMO,
		unpackArgs = true,
		func = function(param1, param2)
			local upperTrackIndex = tonumber(param1)
			if upperTrackIndex and upperTrackIndex <= 0 then
				upperTrackIndex = nil
			end
			local lowerTrackIndex = tonumber(param2)
			if lowerTrackIndex and lowerTrackIndex <= 0 then
				lowerTrackIndex = nil
			end
			Musician.Keyboard.EnableDemoMode(upperTrackIndex, lowerTrackIndex)
		end
	})

	-- Display help

	table.insert(commands, {
		command = { "help" },
		text = Musician.Msg.COMMAND_HELP,
		func = Musician.Help
	})

	return commands
end

--- Display command-line help
--
function Musician.Help()
	Musician.Utils.Print(Musician.Msg.COMMAND_LIST_TITLE)

	local row
	for _, row in pairs(Musician.GetCommands()) do

		local params = ""
		if row.params then
			params = Musician.Utils.FormatText(row.params) .. "\n"
		end

		local cmd = ""
		if row.command[1] ~= "" then
			cmd = row.command[1] .. " "
		end

		Musician.Utils.Print(
			Musician.Utils.Highlight("/mus " .. cmd) ..
			params ..
			Musician.Utils.FormatText(row.text)
		)
	end
end

--- Run command line
-- @param commandLine (string)
function Musician.RunCommandLine(commandLine)
	local normalizedCommandLine = string.gsub(commandLine, "[%s]+", " ")
	local args = { string.split(" ", strtrim(normalizedCommandLine)) }
	local cmd = strtrim(strlower(table.remove(args, 1)))

	local commands = Musician.GetCommands()

	-- Add hidden debug command
	table.insert(commands, {
		command = {
			"debug"
		},
		unpackArgs = true,
		func = function(arg1, arg2)
			local module, state
			if arg2 == nil then
				state = arg1
			else
				module, state = arg1, arg2
			end

			if state == "on" then state = true
			elseif state == "off" then state = false
			else state = nil end

			if module ~= nil then
				if state then
					Musician_Settings.debug[module] = true
					Musician.Utils.Debug(nil, "Debug mode enabled for module " .. module .. ".")
				else
					Musician_Settings.debug[module] = nil
					Musician.Utils.Debug(nil, "Debug mode disabled for module " .. module .. ".")
				end
			else
				if state then
					for _, module in ipairs(Musician.modules) do
						Musician_Settings.debug[module] = true
					end
					Musician.Utils.Debug(nil, "Debug mode enabled for all modules.")
				else
					Musician_Settings.debug = {}
					Musician.Utils.Debug(nil, "Debug mode disabled for all modules.")
				end
			end
		end
	})

	local row, command
	for _, row in pairs(commands) do
		for _, command in pairs(row.command) do
			if cmd == command then
				if row.unpackArgs then
					row.func(unpack(args))
				else
					row.func(table.concat(args, " "))
				end
				return
			end
		end
	end

	local errorMessage = Musician.Msg.ERR_COMMAND_UNKNOWN
	errorMessage = string.gsub(errorMessage, "{command}", Musician.Utils.Highlight(cmd))
	errorMessage = string.gsub(errorMessage, "{help}", Musician.Utils.Highlight("/mus help"))
	Musician.Utils.PrintError(errorMessage)
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
	-- Send promo emote if my song is playing
	if song.player and Musician.songs[song.player] ~= nil and Musician.Utils.PlayerIsMyself(song.player) then
		Musician.Utils.SendPromoEmote()
	end
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

	Musician:SendMessage(Musician.Events.SourceSongLoaded)
end

--- Handle failed source import
--
function Musician.OnSourceImportFailed()
	Musician.importingSong = nil
	collectgarbage()
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

	Musician:SendMessage(Musician.Events.Frame, elapsed)
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
		icon = Musician.IconImages.NoteDisabled
		msg = Musician.Msg.PLAYER_IS_MUTED
	else
		Musician_Settings.mutedPlayers[playerName] = nil
		icon = Musician.IconImages.Note
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
			-- Open options panel
			elseif args[2] == "options" then
				Musician.Options.Show()
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
				isRegistered = Musician.Registry.PlayerIsRegistered(player)
			end

			local items = {
				{
					value = "MUSICIAN_SUBSECTION_TITLE_MUTED",
					text = Musician.Msg.PLAYER_MENU_TITLE .. " " .. Musician.Utils.GetChatIcon(Musician.IconImages.NoteDisabled),
					isTitle = true,
					visible = isPlayer and isRegistered and not(isMyself) and isMuted
				},
				{
					value = "MUSICIAN_SUBSECTION_TITLE_UNMUTED",
					text = Musician.Msg.PLAYER_MENU_TITLE .. " " .. Musician.Utils.GetChatIcon(Musician.IconImages.Note),
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

	CHAT_FLAG_MUSICIAN_MUTED = Musician.Utils.GetChatIcon(Musician.IconImages.NoteDisabled)
	CHAT_FLAG_MUSICIAN_UNMUTED = Musician.Utils.GetChatIcon(Musician.IconImages.Note)

	local messageEventFilter = function(self, event, msg, player, languageName, channelName, playerName2, pflag, ...)

		local fullPlayerName = Musician.Utils.NormalizePlayerName(player)

		local isPromoEmote = false
		local isPromoEmoteSuccessful = false

		-- "Player is playing music."
		if Musician.Utils.HasPromoEmote(msg) and event == "CHAT_MSG_EMOTE" then

			isPromoEmote = true

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

				isPromoEmoteSuccessful = true

				-- Music is not loaded
			else
				-- Player is not in the channel and not in my group: it's from another realm
				if not(Musician.Utils.PlayerIsOnSameRealm(player)) and not(Musician.Utils.PlayerIsInGroup(player)) then
					msg = Musician.Msg.EMOTE_PLAYING_MUSIC .. " " .. Musician.Utils.Highlight(Musician.Msg.EMOTE_PLAYER_OTHER_REALM, 'FF0000')
				else -- Song has not been loaded (incompatible version)
					local errorMsg = string.gsub(Musician.Msg.EMOTE_SONG_NOT_LOADED, '{player}', Musician.Utils.GetPlayerLink(fullPlayerName))
					msg = Musician.Msg.EMOTE_PLAYING_MUSIC .. " " .. Musician.Utils.Highlight(errorMsg, 'FF0000')
				end

				isPromoEmoteSuccessful = false
			end
		end

		-- Add muted/unmuted flag if currently playing music
		if Musician.songs[fullPlayerName] ~= nil and Musician.songs[fullPlayerName]:IsPlaying() then
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

		-- Send promo emote event
		if isPromoEmote then
			Musician:SendMessage(Musician.Events.PromoEmote, isPromoEmoteSuccessful, msg, fullPlayerName, ...)
		end

		return false, msg, player, languageName, channelName, playerName2, pflag, ...
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", messageEventFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", messageEventFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", messageEventFilter)
end

--- Add a tips and tricks callback
-- @param callback {function}
-- @param priority {boolean} If true, add the tip to the top of the list
function Musician.AddTipsAndTricks(callback, priority)
	if priority then
		table.insert(tipsAndTricks, 1, callback)
	else
		table.insert(tipsAndTricks, callback)
	end
end

--- Show the first
-- @param callback {function}
function Musician.ShowTipsAndTricks()
	if not(Musician_Settings.enableTipsAndTricks) then return end
	if #tipsAndTricks > 0 then
		local callback = table.remove(tipsAndTricks, 1)
		callback()
	end
end


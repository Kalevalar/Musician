Musician.Frame = LibStub("AceAddon-3.0"):NewAddon("Musician.Frame", "AceEvent-3.0")

local sourceBuffer
local i

local loadingProgressbarWidth
local buttonProgressbarWidth

MusicianFrame.Init = function()
	MusicianFrame:SetClampedToScreen(true)
	MusicianFrame.Refresh()

	Musician.Frame:RegisterMessage(Musician.Events.RefreshFrame, MusicianFrame.Refresh)
	Musician.Frame:RegisterMessage(Musician.Events.SongImportProgress, MusicianFrame.RefreshLoadingProgressBar)
	Musician.Frame:RegisterMessage(Musician.Events.SongImportComplete, MusicianFrame.RefreshLoadingProgressBar)
	Musician.Frame:RegisterMessage(Musician.Events.SongPlay, MusicianFrame.RefreshPlayingProgressBar)
	Musician.Frame:RegisterMessage(Musician.Events.SongStop, MusicianFrame.RefreshPlayingProgressBar)
	Musician.Frame:RegisterMessage(Musician.Events.SongCursor, MusicianFrame.RefreshPlayingProgressBar)
	
	MusicianFrame.Clear()
	MusicianFrameTitle:SetText(Musician.Msg.PLAY_A_SONG)
	MusicianFrameClearButton:SetText(Musician.Msg.CLEAR)
	MusicianFrameTrackEditorButton:SetText(Musician.Msg.EDIT)

	MusicianFrameSource:SetMaxBytes(512)
	MusicianFrameSource:SetScript("OnTextChanged", MusicianFrame.SourceChanged)
	MusicianFrameSource:SetScript("OnChar", function(self, c)
		sourceBuffer[i] = c
		i = i + 1
	end)

	loadingProgressbarWidth = MusicianFrameTextBackgroundLoadingProgressBar:GetWidth()
	buttonProgressbarWidth = MusicianFramePlayButtonProgressBar:GetWidth()
	MusicianFrameTextBackgroundLoadingProgressBar:Hide()
	MusicianFrameTestButtonProgressBar:Hide()
	MusicianFramePlayButtonProgressBar:Hide()
end

MusicianFrame.Focus = function()
	if not(MusicianFrameSource:HasFocus()) then
		MusicianFrameSource:HighlightText(0)
		MusicianFrameSource:SetFocus()
	end
end

MusicianFrame.Clear = function(noFocus)
	sourceBuffer = {}
	i = 1
	MusicianFrameSource:SetText(MusicianFrame.GetDefaultText())
	MusicianFrameSource:HighlightText(0)

	if not(noFocus) then
		MusicianFrameSource:SetFocus()
	end
end

MusicianFrame.TrackEditor = function()
	MusicianTrackEditor:Show()
end

MusicianFrame.SourceChanged = function(self, isUserInput)
	MusicianFrameSource:HighlightText(0, 0)
	MusicianFrameSource:ClearFocus()

	if isUserInput then
		MusicianFrame.ImportSource()
		MusicianFrame.Focus()
		sourceBuffer = {}
		i = 1
	end
end

MusicianFrame.ImportSource = function()
	local source = table.concat(sourceBuffer)
	if source == "" or source == MusicianFrame.GetDefaultText() then
		return
	end
	
	Musician.ImportSource(source)
end

MusicianFrame.Test = function()
	if Musician.sourceSong then
		if Musician.sourceSong:IsPlaying() then
			Musician.sourceSong:Stop()
		else
			Musician.sourceSong:Play()
		end
	end
	Musician.Comm:SendMessage(Musician.Events.RefreshFrame)
end

MusicianFrame.Play = function()
	if Musician.songIsPlaying then
		Musician.Comm.StopSong()
	else
		Musician.Comm.PlaySong()
	end
end

MusicianFrame.GetDefaultText = function()
	return string.gsub(Musician.Msg.PASTE_MUSIC_CODE, "{url}", Musician.CONVERTER_URL)
end

MusicianFrame.Refresh = function()

	-- Track editor button
	if Musician.sourceSong == nil then
		MusicianFrameTrackEditorButton:Disable()
		MusicianTrackEditor:Hide()
	else
		MusicianFrameTrackEditorButton:Enable()
	end

	-- Test song button
	if Musician.sourceSong == nil then
		MusicianFrameTestButton:Disable()
	else
		MusicianFrameTestButton:Enable()
	end

	if Musician.sourceSong ~= nil and Musician.sourceSong:IsPlaying() then
		MusicianFrameTestButton:SetText(Musician.Msg.STOP_TEST)
	else
		MusicianFrameTestButton:SetText(Musician.Msg.TEST_SONG)
	end

	-- Play button
	if Musician.Comm.isPlaySent or Musician.Comm.isStopSent or not(Musician.sourceSong) and not(Musician.songIsPlaying) then
		MusicianFramePlayButton:Disable()
	else
		MusicianFramePlayButton:Enable()
	end

	if Musician.songIsPlaying then
		MusicianFramePlayButton:SetText(Musician.Msg.STOP)
	else
		MusicianFramePlayButton:SetText(Musician.Msg.PLAY)
	end
end

MusicianFrame.RefreshLoadingProgressBar = function(event, song, progression)
	if not(song.importing) then
		MusicianFrameTextBackgroundLoadingProgressBar:Hide()
		MusicianFrame.Clear(true)
	else
		MusicianFrameTextBackgroundLoadingProgressBar:Show()

		if progression ~= nil then
			MusicianFrameTextBackgroundLoadingProgressBar:SetWidth(max(1, loadingProgressbarWidth * progression))
		end
	end
end

MusicianFrame.RefreshPlayingProgressBar = function(event, song)
	local progressBar

	if song == Musician.sourceSong then
		progressBar = MusicianFrameTestButtonProgressBar
	elseif song == Musician.songs[Musician.Utils.NormalizePlayerName(UnitName("player"))] then
		progressBar = MusicianFramePlayButtonProgressBar
	else
		return
	end

	local progression = song:GetProgression()
	if progression ~= nil then
		progressBar:Show()
		progressBar:SetWidth(max(1, buttonProgressbarWidth * progression))
	else
		progressBar:Hide()
	end
end

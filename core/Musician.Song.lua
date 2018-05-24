Musician.Song = {}
Musician.Song.__index = Musician.Song

--- Constructor
-- @param packedSongData (string)
-- @param crop (boolean)
function Musician.Song.create(packedSongData, crop)
	local self = {}
	setmetatable(self, Musician.Song)

	-- @field tracks (table) Song tracks, including instrument and notes
	self.tracks = {}

	-- @field duration (float) Song duration in seconds
	self.duration = 0

	-- @field name (string) Song title
	self.name = nil

	-- @field player (string) Player name, with realm slug
	self.player = nil

	-- @field notified (boolean) True when the notification for the song playing has been displayed
	self.notified = false

	-- @field preloading (boolean) True when the song samples are preloading
	self.preloading = false

	-- @field preloaded (boolean) True when the song samples have been preloaded
	self.preloaded = false

	-- @field playing (boolean) True when the song is playing
	self.playing = false

	-- @field cropFrom (number) Play song from this position
	self.cropFrom = 0

	-- @field cropTo (number) Play song until this position
	self.cropTo = 0

	-- @field cursor (number) Cursor position, in seconds
	self.cursor = 0

	-- @field soloTracks (number) Number of tracks in solo
	self.soloTracks = 0

	-- @field speed (number) Playing speed
	self.speed = 1

	if packedSongData then
		self:Unpack(packedSongData, crop)
	end

	return self
end

--- Returns true if the song is playing or about to be played (preloading).
-- @return (boolean)
function Musician.Song:IsPlaying()
	return self.preloading or self.playing
end

--- Mute or unmute track
-- @param track (object)
-- @param isMuted (boolean)
function Musician.Song:SetTrackMuted(track, isMuted)
	if isMuted then
		self:TrackNotesOff(track)
	end

	track.muted = isMuted
end

--- Returns true if the track is muted
-- @param track (object)
-- @return (boolean)
function Musician.Song:TrackIsMuted(track)
	return track.muted or self.soloTracks > 0 and not(track.solo)
end

--- Set/unset track solo
-- @param track (object)
-- @param isMuted (boolean)
function Musician.Song:SetTrackSolo(track, isSolo)
	if track.solo and not(isSolo) then
		track.solo = false
		self.soloTracks = self.soloTracks - 1
	elseif not(track.solo) and isSolo then
		track.solo = true
		self.soloTracks = self.soloTracks + 1
		local track
		for _, track in pairs(self.tracks) do
			if self:TrackIsMuted(track) then
				self:TrackNotesOff(track)
			end
		end
	end
end

--- Preload song samples into memory cache
-- @param callback (function) Function to be called when preloading is complete
function Musician.Song:Preload(callback)

	-- Already preloaded
	if self.preloaded then
		if callback then
			callback()
		end
		return
	end

	self.preloading = true

	-- Get all samples (notes per instrument) needed
	local track, note
	local notes = {}

	for _, track in pairs(self.tracks) do
		for _, note in pairs(track.notes) do
			local noteString = track.instrument .. note[1]
			notes[noteString] = {track.instrument, note[1]}
		end
	end

	local noteCount = 0
	for _, note in pairs(notes) do
		noteCount = noteCount + 1
	end

	-- Synchronize callback
	if callback then
		-- Max loading time for a sample has been measured to 3 ms (5400 RPM HDD on USB2)
		C_Timer.After(noteCount * 0.003 + 1, callback)
	end

	-- Preload samples
	local index = 0
	local duration = .25
	for _, note in pairs(notes) do
		local soundFile, _ = Musician.Utils.GetSoundFile(note[1], note[2])
		if soundFile ~= nil then
			local play, handle = PlaySoundFile(soundFile, 'SFX')
			if play then
				StopSound(handle, 0)
			end
		end
	end

	self.preloaded = true
end

--- Play song
function Musician.Song:Play()
	self:Reset()
	self:Resume()
end

--- Reset song to initial position
function Musician.Song:Reset()
	self:SongNotesOff()
	self:Seek(self.cropFrom)
end

--- Seek to position
-- @param cursor (number)
function Musician.Song:Seek(cursor)

	--- Perform seek within track
	-- @param cursor (number) Position to reach
	-- @param track (table)
	local trackSeek = function(cursor, track)
		local noteCount = table.getn(track.notes)

		if noteCount == 0 then
			return
		end

		-- Cursor is before the first note
		if cursor <= track.notes[1][2] then
			track.playIndex = 1
			return
		-- Cursor is after the last note
		elseif cursor > track.notes[noteCount][2] then
			track.playIndex = noteCount + 1
			return
		end

		local from = 1
		local to = noteCount
		local index = max(1, min(noteCount, track.playIndex))

		if cursor <= track.notes[index][2] then
			to = index
		else
			from = index
		end

		local found = false
		while not(found) do
			index = from + floor((to - from) / 2 + .5)

			-- Exact position found! Find first note at exact position
			while index >= 1 and track.notes[index][2] == cursor do
				found = true
				index = index - 1
			end

			if found then
				track.playIndex = index + 1
				return
			end

			-- In-between position found
			if cursor > track.notes[index - 1][2] and cursor <= track.notes[index][2] then
				track.playIndex = index
				return
			end

			-- Seek before
			if cursor < track.notes[index][2] then
				to = index
				-- Seek after
			else
				from = index
			end
		end
	end

	cursor = max(0, min(cursor, self.duration))

	if cursor == self.cursor then
		return
	end

	self:SongNotesOff()

	local track
	for _, track in pairs(self.tracks) do
		trackSeek(cursor, track)
	end

	self.cursor = cursor
	Musician.Comm:SendMessage(Musician.Events.SongCursor, self)
end

--- Resume a song playing
function Musician.Song:Resume()
	-- Preload and delay playout if necessary
	self:Preload(function()
		self.preloading = false
		self.playing = true
	end)

	Musician.Comm:SendMessage(Musician.Events.SongPlay, self)
end

--- Stop song
function Musician.Song:Stop()
	self:SongNotesOff()
	self.preloading = false
	self.playing = false
	Musician.Comm:SendMessage(Musician.Events.SongStop, self)
end

--- Main on update function, play notes accordingly to every frame.
-- @param elapsed (number)
function Musician.Song:OnUpdate(elapsed)
	if not(self.playing) then
		return
	end

	local from = self.cursor
	local to = self.cursor + elapsed * self.speed
	self.cursor = to

	local track
	for _, track in pairs(self.tracks) do
		-- Notes On
		while track.notes[track.playIndex] and (track.notes[track.playIndex][2] >= from) and (track.notes[track.playIndex][2] < to) do
			if elapsed < 1 then -- Do not play notes if frame is longer than 1 s (after loading screen) to avoid slowdowns
				self:NoteOn(track, track.playIndex, soundFile)
			end
			track.playIndex = track.playIndex + 1
		end

		-- Notes Off
		local noteIndex, noteOn
		for noteIndex, noteOn in pairs(track.notesOn) do
			if noteOn[1] < to then -- Off time is in the past
				self:NoteOff(track, noteIndex)
			end
		end
	end

	Musician.Comm:SendMessage(Musician.Events.SongCursor, self)

	-- Song has ended
	if to >= self.cropTo then
		self:Stop()
	end
end

--- Play a note
-- @param track (table) Reference to the track
-- @param noteIndex (int) Note index
function Musician.Song:NoteOn(track, noteIndex)
	local key, time, duration = unpack(track.notes[noteIndex])
	local soundFile, instrumentData = Musician.Utils.GetSoundFile(track.instrument, key + track.transpose)
	if soundFile == nil then
		return
	end

	-- Send notification emote
	if self.player ~= nil and Musician.Utils.PlayerIsInRange(self.player) and not(self.notified) then
		Musician.Utils.DisplayEmote(self.player, Musician.songs[self.player].guid, Musician.Msg.EMOTE_PLAYING_MUSIC)
		self.notified = true
	end

	-- Do not play note if the source song is playing or if the player is out of range
	local sourceSongIsPlaying = Musician.sourceSong ~= nil and Musician.sourceSong:IsPlaying()
	if self.player ~= nil and (sourceSongIsPlaying or not(Musician.Utils.PlayerIsInRange(self.player))) or self:TrackIsMuted(track) or Musician.globalMute or Musician.PlayerIsMuted(self.player) then
		return
	end

	-- Play note sound file
	local play, handle = PlaySoundFile(soundFile, 'SFX')

	-- Add note to notesOn with sound handle and note off time
	if play then
		local endTime = self.cursor + duration / self.speed
		track.notesOn[noteIndex] = {endTime, handle, instrumentData.decay}
		track.polyphony = track.polyphony + 1
		Musician:SendMessage(Musician.Events.NoteOn, self, track, noteIndex, endTime, instrumentData.decay)
	end
end

--- Stop a note of a track
-- @param track (table) Reference to the track
-- @param noteIndex (int) Note index
function Musician.Song:NoteOff(track, noteIndex)
	if track.notesOn[noteIndex] ~= nil then
		local handle = track.notesOn[noteIndex][2]
		StopSound(handle, track.notesOn[noteIndex][3])
		track.notesOn[noteIndex] = nil
		track.polyphony = track.polyphony - 1
		Musician:SendMessage(Musician.Events.NoteOff, self, track, noteIndex)
	end
end

--- Stop all notes of a track
-- @param track (table) Reference to the track
function Musician.Song:TrackNotesOff(track)
	local noteIndex, noteOn
	for noteIndex, noteOn in pairs(track.notesOn) do
		self:NoteOff(track, noteIndex)
	end
end

--- Stop all notes of the song
function Musician.Song:SongNotesOff()
	local track
	for _, track in pairs(self.tracks) do
		self:TrackNotesOff(track)
	end
end

--- Pack a note into a string
-- @param note (table)
-- @param fps (float)
-- @param transpose (number)
-- @return (string)
function Musician.Song:PackNote(note, fps, transpose)
	-- KTTD : key, time, duration
	return Musician.Utils.PackNumber(max(0, min(255, note[1] + transpose)), 1) .. Musician.Utils.PackTime(note[2] - self.cropFrom, 2, fps) .. Musician.Utils.PackTime(min(note[3], Musician.MAX_NOTE_DURATION), 1, Musician.DURATION_FPS)
end

--- Unpack note from string
-- @param str (string)
-- @param fps (float)
-- @return (table)
function Musician.Song:UnpackNote(str, fps)
	-- KTTD : key, time, duration
	return {
		Musician.Utils.UnpackNumber(string.sub(str, 1, 1)),
		Musician.Utils.UnpackTime(string.sub(str, 2, 3), fps),
		Musician.Utils.UnpackTime(string.sub(str, 4, 4), Musician.DURATION_FPS)
	}
end

--- Pack a track into a string
-- @param track (table)
-- @param fps (float)
-- @return (string)
function Musician.Song:PackTrack(track, fps)
	local packedTrack = ""

	-- Notes
	local note
	local noteCount = 0
	for _, note in pairs(track.notes) do
		if note[2] >= self.cropFrom and note[2] <= self.cropTo then
			packedTrack = packedTrack .. self:PackNote(note, fps, track.transpose)
			noteCount = noteCount + 1
		end
	end

	if noteCount > 0 then
		-- TINN : Track Id, instrument ID, Number of notes
		packedTrack = Musician.Utils.PackNumber(track.id, 1) .. Musician.Utils.PackNumber(track.instrument, 1) .. Musician.Utils.PackNumber(noteCount, 2)	 .. packedTrack
	end

	return packedTrack
end

--- Unpack a track from string
-- @param str (string)
-- @param fps (float)
-- @return (table)
function Musician.Song:UnpackTrack(str, fps)
	local track = {}

	-- TINN : Track Id, instrument ID, Number of notes
	track.id = Musician.Utils.UnpackNumber(string.sub(str, 1, 1))
	track.midiInstrument = Musician.Utils.UnpackNumber(string.sub(str, 2, 2))
	track.instrument = track.midiInstrument

	local noteCount  = Musician.Utils.UnpackNumber(string.sub(str, 3, 4))

	track.notes = {}
	local noteId
	for noteId = 0, noteCount - 1 do
		local cursor = 5 + noteId * 4 -- Notes are 4-byte long
		table.insert(track.notes, self:UnpackNote(string.sub(str, cursor, cursor + 3), fps))
	end

	-- Current playing note index
	track.playIndex = 1

	-- Track is muted
	track.muted = (noteCount == 0)

	-- Track is solo
	track.solo = false

	-- Track transposition
	track.transpose = 0

	-- Notes currently playing
	track.notesOn = {}

	-- Polyphony
	track.polyphony = 0

	-- Channel number
	track.channel = nil

	-- Track name
	track.name = nil

	return track
end

--- Pack a song into a string
-- @return (string)
function Musician.Song:Pack()
	local packedSong = Musician.FILE_HEADER
	local songName = string.sub(self.name, 1, 255)
	local duration = ceil(self.cropTo - self.cropFrom)
	local fps = 65535 / duration -- 2^16

	-- Pack tracks
	local packedTracks = ""
	local packedTrackCount = 0
	local track
	for _, track in pairs(self.tracks) do
		if not(self:TrackIsMuted(track)) and Musician.MIDI_INSTRUMENT_MAPPING[track.instrument] ~= "none" then
			local packedTrack = self:PackTrack(track, fps)
			if packedTrack ~= "" then
				packedTracks = packedTracks .. packedTrack
				packedTrackCount = packedTrackCount + 1
			end
		end
	end

	-- Song name length, song name
	packedSong = packedSong .. Musician.Utils.PackNumber(string.len(songName), 1) .. songName

	-- Song duration
	packedSong = packedSong .. Musician.Utils.PackNumber(duration, 2)

	-- Number of tracks
	packedSong = packedSong .. Musician.Utils.PackNumber(packedTrackCount, 1)

	-- Tracks
	packedSong = packedSong .. packedTracks

	return packedSong
end

--- Unpack song metadata from string
-- @param str (string)
function Musician.Song:UnpackMetadata(str)
	local cursor = 1

	while cursor <= string.len(str) do

		-- TRN: Track names
		if string.sub(str, cursor, cursor + 2) == 'TRN' then
			cursor = cursor + 3
			local track

			for	_, track in pairs(self.tracks) do
				local length = Musician.Utils.UnpackNumber(string.sub(str, cursor, cursor))
				if length > 0 then
					track.name = string.sub(str, cursor + 1, cursor + length)
				end
				cursor = cursor + length + 1
			end

		-- TRC: Track channels
		elseif string.sub(str, cursor, cursor + 2) == 'TRC' then
			cursor = cursor + 3
			local track
			for	_, track in pairs(self.tracks) do
				track.channel = Musician.Utils.UnpackNumber(string.sub(str, cursor, cursor))
				cursor = cursor + 1
			end

		-- Unsupported
		else
			return

		end
	end
end

--- Unpack a song from string
-- @param str (string)
-- @param crop (boolean)
function Musician.Song:Unpack(str, crop)
	local cursor = 1

	-- Check format
	if string.sub(str, 1, string.len(Musician.FILE_HEADER)) ~= Musician.FILE_HEADER then
		error(Musician.Msg.INVALID_MUSIC_CODE)
	end
	cursor = cursor + string.len(Musician.FILE_HEADER)

	-- Song name length (1), song name
	local songNameLength = Musician.Utils.UnpackNumber(string.sub(str, cursor, cursor))
	cursor = cursor + 1
	self.name = string.sub(str, cursor, cursor + songNameLength - 1)
	cursor = cursor + songNameLength

	-- song duration (2)
	local duration = Musician.Utils.UnpackNumber(string.sub(str, cursor, cursor + 1))
	local fps = 65535 / duration -- 2^16
	self.duration = duration
	if crop then
		self.cropTo = 0
		self.cropFrom = self.duration
	else
		self.cropTo = self.duration
		self.cropFrom = 0
	end

	cursor = cursor + 2

	-- number of tracks (1)
	local trackCount = Musician.Utils.UnpackNumber(string.sub(str, cursor, cursor))
	cursor = cursor + 1

	-- tracks
	local trackId
	self.tracks = {}
	for trackId = 0, trackCount - 1 do
		local trackLength = Musician.Utils.UnpackNumber(string.sub(str, cursor + 2, cursor + 3))
		local trackEnd = cursor + 3 + trackLength * 4
		local track = self:UnpackTrack(string.sub(str, cursor, trackEnd), fps)
		track.index = trackId + 1
		table.insert(self.tracks, track)
		if track.notes[1] ~= nil and crop then
			local noteCount = table.getn(track.notes)
			self.cropFrom = min(self.cropFrom, track.notes[1][2])
			self.cropTo = max(self.cropTo, track.notes[noteCount][2] + track.notes[noteCount][3])
		end
		cursor = trackEnd + 1
	end

	-- metadata
	self:UnpackMetadata(string.sub(str, cursor))

	self.cursor = self.cropFrom
end

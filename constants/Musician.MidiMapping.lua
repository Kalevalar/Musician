local Percussion = Musician.MIDI_PERCUSSIONS
local Instrument = Musician.MIDI_INSTRUMENTS

Musician.MIDI_INSTRUMENT_MAPPING = {
	-- Piano
	[Instrument.AcousticGrandPiano] = "dulcimer",
	[Instrument.BrightAcousticPiano] = "dulcimer",
	[Instrument.ElectricGrandPiano] = "dulcimer",
	[Instrument.HonkyTonkPiano] = "dulcimer",
	[Instrument.ElectricPiano1] = "dulcimer",
	[Instrument.ElectricPiano2] = "dulcimer",
	[Instrument.Harpsichord] = "harp",
	[Instrument.Clavi] = "harp",

	-- Chromatic Percussion
	[Instrument.Celesta] = "dulcimer",
	[Instrument.Glockenspiel] = "dulcimer",
	[Instrument.MusicBox] = "dulcimer",
	[Instrument.Vibraphone] = "dulcimer",
	[Instrument.Marimba] = "dulcimer",
	[Instrument.Xylophone] = "dulcimer",
	[Instrument.TubularBells] = "dulcimer",
	[Instrument.Dulcimer] = "dulcimer",

	-- Organ
	[Instrument.DrawbarOrgan] = "lute",
	[Instrument.PercussiveOrgan] = "lute",
	[Instrument.RockOrgan] = "lute",
	[Instrument.ChurchOrgan] = "lute",
	[Instrument.ReedOrgan] = "lute",
	[Instrument.Accordion] = "lute",
	[Instrument.Harmonica] = "lute",
	[Instrument.TangoAccordion] = "lute",

	-- Guitar
	[Instrument.AcousticGuitarNylon] = "lute",
	[Instrument.AcousticGuitarSteel] = "lute",
	[Instrument.ElectricGuitarJazz] = "clean-guitar",
	[Instrument.ElectricGuitarClean] = "clean-guitar",
	[Instrument.ElectricGuitarMuted] = "clean-guitar",
	[Instrument.OverdrivenGuitar] = "distorsion-guitar",
	[Instrument.DistortionGuitar] = "distorsion-guitar",
	[Instrument.Guitarharmonics] = "distorsion-guitar",

	-- Bass
	[Instrument.AcousticBass] = "lute",
	[Instrument.ElectricBassFinger] = "bass-guitar",
	[Instrument.ElectricBassPick] = "bass-guitar",
	[Instrument.FretlessBass] = "bass-guitar",
	[Instrument.SlapBass1] = "bass-guitar",
	[Instrument.SlapBass2] = "bass-guitar",
	[Instrument.SynthBass1] = "bass-guitar",
	[Instrument.SynthBass2] = "bass-guitar",

	-- Strings
	[Instrument.Violin] = "fiddle",
	[Instrument.Viola] = "fiddle",
	[Instrument.Cello] = "cello",
	[Instrument.Contrabass] = "cello",
	[Instrument.TremoloStrings] = "fiddle",
	[Instrument.PizzicatoStrings] = "lute",
	[Instrument.OrchestralHarp] = "harp",
	[Instrument.Timpani] = "bodhran-bassdrum-low",

	-- Ensemble
	[Instrument.StringEnsemble1] = "fiddle",
	[Instrument.StringEnsemble2] = "fiddle",
	[Instrument.SynthStrings1] = "fiddle",
	[Instrument.SynthStrings2] = "fiddle",
	[Instrument.ChoirAahs] = "male-voice",
	[Instrument.VoiceOohs] = "female-voice",
	[Instrument.SynthVoice] = "female-voice",
	[Instrument.OrchestraHit] = "lute",

	-- Brass
	[Instrument.Trumpet] = "trumpet",
	[Instrument.Trombone] = "trombone",
	[Instrument.Tuba] = "trombone",
	[Instrument.MutedTrumpet] = "trumpet",
	[Instrument.FrenchHorn] = "trumpet",
	[Instrument.BrassSection] = "trumpet",
	[Instrument.SynthBrass1] = "trumpet",
	[Instrument.SynthBrass2] = "trumpet",

	-- Reed
	[Instrument.SopranoSax] = "clarinet",
	[Instrument.AltoSax] = "clarinet",
	[Instrument.TenorSax] = "bassoon",
	[Instrument.BaritoneSax] = "bassoon",
	[Instrument.Oboe] = "clarinet",
	[Instrument.EnglishHorn] = "clarinet",
	[Instrument.Bassoon] = "bassoon",
	[Instrument.Clarinet] = "clarinet",

	-- Pipe
	[Instrument.Piccolo] = "recorder",
	[Instrument.Flute] = "recorder",
	[Instrument.Recorder] = "recorder",
	[Instrument.PanFlute] = "recorder",
	[Instrument.BlownBottle] = "recorder",
	[Instrument.Shakuhachi] = "recorder",
	[Instrument.Whistle] = "recorder",
	[Instrument.Ocarina] = "recorder",

	-- Synth Lead
	[Instrument.Lead1Square] = "clarinet",
	[Instrument.Lead2Sawtooth] = "fiddle",
	[Instrument.Lead3Calliope] = "recorder",
	[Instrument.Lead4Chiff] = "recorder",
	[Instrument.Lead5Charang] = "recorder",
	[Instrument.Lead6Voice] = "female-voice",
	[Instrument.Lead7Fifths] = "fiddle",
	[Instrument.Lead8BassLead] = "lute",

	-- Synth Pad
	[Instrument.Pad1Newage] = "lute",
	[Instrument.Pad2Warm] = "fiddle",
	[Instrument.Pad3Polysynth] = "fiddle",
	[Instrument.Pad4Choir] = "fiddle",
	[Instrument.Pad5Bowed] = "fiddle",
	[Instrument.Pad6Metallic] = "fiddle",
	[Instrument.Pad7Halo] = "fiddle",
	[Instrument.Pad8Sweep] = "fiddle",

	-- Synth Effects
	[Instrument.FX1Rain] = "dulcimer",
	[Instrument.FX2Soundtrack] = "dulcimer",
	[Instrument.FX3Crystal] = "dulcimer",
	[Instrument.FX4Atmosphere] = "dulcimer",
	[Instrument.FX5Brightness] = "dulcimer",
	[Instrument.FX6Goblins] = "dulcimer",
	[Instrument.FX7Echoes] = "dulcimer",
	[Instrument.FX8SciFi] = "dulcimer",

	-- Ethnic
	[Instrument.Sitar] = "harp",
	[Instrument.Banjo] = "lute",
	[Instrument.Shamisen] = "lute",
	[Instrument.Koto] = "harp",
	[Instrument.Kalimba] = "dulcimer",
	[Instrument.Bagpipe] = "bagpipe",
	[Instrument.Fiddle] = "fiddle",
	[Instrument.Shanai] = "bagpipe",

	-- Percussive
	[Instrument.TinkleBell] = "lute",
	[Instrument.Agogo] = "none",
	[Instrument.SteelDrums] = "dulcimer",
	[Instrument.Woodblock] = "none",
	[Instrument.TaikoDrum] = "bodhran-bassdrum-low",
	[Instrument.MelodicTom] = "bodhran-snare-long-hi",
	[Instrument.SynthDrum] = "bodhran-snare-long-low",
	[Instrument.ReverseCymbal] = "none",

	-- Sound Effects
	[Instrument.GuitarFretNoise] = "none",
	[Instrument.BreathNoise] = "none",
	[Instrument.Seashore] = "none",
	[Instrument.BirdTweet] = "none",
	[Instrument.TelephoneRing] = "none",
	[Instrument.Helicopter] = "none",
	[Instrument.Applause] = "none",
	[Instrument.Gunshot] = "none",

	-- Percussions
	[Instrument.Percussions] = "percussions",
	[Instrument.Drumkit] = "drumkit",

	-- None
	[Instrument.None] = "none",
}

Musician.MIDI_PERCUSSION_MAPPING = {
	[Percussion.Laser] = "none",
	[Percussion.Whip] = "none",
	[Percussion.ScratchPush] = "bodhran-roll-hi",
	[Percussion.ScratchPull] = "bodhran-roll-low",
	[Percussion.StickClick] = "bodhran-stick-hi",
	[Percussion.SquareClick] = "bodhran-stick-hi",
	[Percussion.MetronomeClick] = "bodhran-stick-med",
	[Percussion.MetronomeBell] = "bodhran-stick-low",
	[Percussion.AcousticBassDrum] = "bodhran-bassdrum-low",
	[Percussion.BassDrum1] = "bodhran-bassdrum-hi",
	[Percussion.SideStick] = "bodhran-stick-low",
	[Percussion.AcousticSnare] = "bodhran-snare-long-low",
	[Percussion.HandClap] = "clap",
	[Percussion.ElectricSnare] = "bodhran-snare-long-hi",
	[Percussion.LowFloorTom] = "bodhran-tom-long-low",
	[Percussion.ClosedHiHat] = "tambourine-hit1",
	[Percussion.HighFloorTom] = "bodhran-tom-long-med",
	[Percussion.PedalHiHat] = "tambourine-shake-short",
	[Percussion.LowTom] = "bodhran-tom-long-hi",
	[Percussion.OpenHiHat] = "tambourine-shake-long",
	[Percussion.LowMidTom] = "bodhran-tom-short-low",
	[Percussion.HiMidTom] = "bodhran-tom-short-med",
	[Percussion.CrashCymbal1] = "tambourine-crash-long1",
	[Percussion.HighTom] = "bodhran-tom-short-hi",
	[Percussion.RideCymbal1] = "tambourine-hit1",
	[Percussion.ChineseCymbal] = "tambourine-shake-long",
	[Percussion.RideBell] = "tambourine-hit2",
	[Percussion.Tambourine] = "tambourine-hit2",
	[Percussion.SplashCymbal] = "tambourine-crash-short-hi",
	[Percussion.Cowbell] = "bodhran-stick-low",
	[Percussion.CrashCymbal2] = "tambourine-crash-long2",
	[Percussion.Vibraslap] = "bodhran-guiro-hi",
	[Percussion.RideCymbal2] = "tambourine-hit2",
	[Percussion.HiBongo] = "bodhran-tom-short-hi",
	[Percussion.LowBongo] = "bodhran-tom-short-low",
	[Percussion.MuteHiConga] = "bodhran-stick-hi",
	[Percussion.OpenHiConga] = "bodhran-tom-short-hi",
	[Percussion.LowConga] = "bodhran-tom-short-low",
	[Percussion.HighTimbale] = "bodhran-tom-long-hi",
	[Percussion.LowTimbale] = "bodhran-tom-long-med",
	[Percussion.HighAgogo] = "bodhran-stick-hi",
	[Percussion.LowAgogo] = "bodhran-stick-low",
	[Percussion.Cabasa] = "rattle-egg",
	[Percussion.Maracas] = "rattle-egg",
	[Percussion.ShortWhistle] = "none",
	[Percussion.LongWhistle] = "none",
	[Percussion.ShortGuiro] = "bodhran-stick-med",
	[Percussion.LongGuiro] = "bodhran-guiro-low",
	[Percussion.Claves] = "bodhran-stick-med",
	[Percussion.HiWoodBlock] = "bodhran-stick-hi",
	[Percussion.LowWoodBlock] = "bodhran-stick-low",
	[Percussion.MuteCuica] = "none",
	[Percussion.OpenCuica] = "none",
	[Percussion.MuteTriangle] = "tambourine-crash-short1",
	[Percussion.OpenTriangle] = "tambourine-crash-short2",
	[Percussion.Shaker] = "rattle-egg",
	[Percussion.SleighBell] = "tambourine-shake-long",
	[Percussion.BellTree] = "none",
	[Percussion.Castanets] = "clap",
	[Percussion.SurduDeadStroke] = "bodhran-tom-long-low",
	[Percussion.Surdu] = "bodhran-tom-short-low",
	[Percussion.SnareDrumRod] = "none",
	[Percussion.OceanDrum] = "none",
	[Percussion.SnareDrumBrush] = "none",
}

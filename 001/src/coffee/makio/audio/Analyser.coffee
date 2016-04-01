Stage = require('makio/core/Stage')
Signal = require('signals')

class Analyser

	@waveData = [] #waveform - from 0 - 1 . no sound is 0.5. Array [binCount]
	@levelsData = [] #levels of each frequecy - from 0 - 1 . no sound is 0. Array [levelsCount]
	@levelHistory = []

	@BEAT_HOLD_TIME = 0.87 #num of frames to hold a beat
	@BEAT_DECAY_RATE = 0.99
	@BEAT_MIN = 0.16 #level less than this is no beat

	#BPM STUFF
	@volume = 0
	@bpmTime = 0 # bpmTime ranges from 0 to 1. 0 = on beat. Based on tap bpm
	@ratedBPMTime = 550
	@count = 0
	@msecsFirst = 0
	@msecsPrevious = 0
	@msecsAvg = 633 #time between beats (msec)
	@gotBeat = false

	@levelsCount = 16 #should be factor of 512
	@beatCutOff = 0
	@beatTime = 0

	@controllers = []

	@init=(audioContext, @gainNode)=>
		@onBeat = new Signal()
		@controls = []
		@analyser = audioContext.createAnalyser()
		@analyser.smoothingTimeConstant = 0.3
		@analyser.fftSize = 2048
		@binCount = @analyser.frequencyBinCount
		@levelBins = Math.floor(@binCount / @levelsCount)
		@freqByteData = new Uint8Array(@binCount)
		@timeByteData = new Uint8Array(@binCount)

		for i in [0...256]
			@levelHistory.push(0)
		return

	@update=()=>
		if(@analyser == null)
			return

		@analyser.getByteFrequencyData(@freqByteData)
		@analyser.getByteTimeDomainData(@timeByteData)

		for i in [0...@binCount] by 1
			@waveData[i] = ((@timeByteData[i] - 128) /128 )

		for i in [0...@levelsCount] by 1
			sum = 0
			for j in [0...@levelBins] by 1
				sum += @freqByteData[(i * @levelBins) + j]
				@levelsData[i] = sum / @levelBins / 256

		@detectBeat()
		@bpmTime = (new Date().getTime() - @bpmStart)/@msecsAvg
		return

	@detectBeat = ()=>
		sum = 0
		for j in [0...@levelsCount] by 1
			sum += @levelsData[j]

		@volume = sum / @levelsCount
		@volume /= @gainNode.gain.value

		@levelHistory.push(@volume)
		@levelHistory.shift(1)

		if (@volume  > @beatCutOff && @volume > @BEAT_MIN)
			# console.log("BEAT")
			@onBeat.dispatch()
			@beatCutOff = @volume *1.1
			@beatTime = 0
		else
			if (@beatTime <= @BEAT_HOLD_TIME)
				@beatTime++
			else
				@beatCutOff *= @BEAT_DECAY_RATE
				@beatCutOff = Math.max(@beatCutOff,@BEAT_MIN)
		return

module.exports = Analyser

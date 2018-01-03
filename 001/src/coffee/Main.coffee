# All great stories start with a Main.coffee
audioPlayer 		= require('web-audio-player')
detectAutoplay 		= require('detect-audio-autoplay')
detectMediaSource 	= require('detect-media-element-source')
tapEvent 			= require('tap-event')
createAudioContext  = require('ios-safe-audio-context')


Stage 			= require('makio/core/Stage')
Stage3d 		= require('makio/core/Stage3d')
OrbitControl 	= require('makio/3d/OrbitControls')
M 				= require('makio/math/M')
Analyser 		= require('makio/audio/Analyser')
Interactions 	= require('makio/core/Interactions')

require('BinaryLoader.js')


class Main

	# Entry point
	constructor:(@callback)->

		@callback(.5)
		@time = 0
		@div = 1
		@targetDiv = 1
		@musicOn = true

		# ---------------------------------------------------------------------- INIT STAGE 2D / 3D

		Stage3d.init({background:0xffffff})
		Stage3d.control = new OrbitControl(Stage3d.camera,10)

		@material = new THREE.RawShaderMaterial({
			vertexShader:require('text.vs')
			fragmentShader:require('text.fs')
			transparent:false
			depthWrite:false
			depthTest:false
		})
		binLoader = new THREE.BinaryLoader();
		binLoader.load( "3d/logo.js", ( geometry, materials )=>
			geometry.computeBoundingBox()
			geometry.computeBoundingSphere()
			geometry.computeVertexNormals()
			mesh = new THREE.Mesh( geometry, @material )
			Stage3d.add(mesh)
		)

		@ring = new THREE.Mesh(new THREE.RingGeometry(10,5), @material)
		Stage3d.add @ring

		material = new THREE.MeshBasicMaterial({color:0,transparent:true,depthWrite:false,depthTest:false})
		@torus = new THREE.Mesh(new THREE.TorusGeometry(10,.6,16,64), material)
		Stage3d.add @torus

		material = new THREE.MeshBasicMaterial({color:0,transparent:true,depthWrite:false,depthTest:false,wireframe:true})
		@sphere = new THREE.Mesh(new THREE.IcosahedronGeometry(10,3), material)
		Stage3d.add @sphere

		material = new THREE.MeshBasicMaterial({color:0,transparent:true,depthWrite:false,depthTest:false,wireframe:true})
		@sphere2 = new THREE.Mesh(new THREE.IcosahedronGeometry(30,3), material)
		Stage3d.add @sphere2

		# ---------------------------------------------------------------------- INIT AUDIO

		@context = createAudioContext()
		@masterGain = @context.createGain()
		@masterGain.gain.value = .03

		Analyser.init(@context, @masterGain)
		Analyser.onBeat.add(@onBeat)
		@masterGain.connect(@context.destination)
		@masterGain.connect(Analyser.analyser)

		detectAutoplay((autoplay)=>
			w = if parent then parent.window else window
			if autoplay then canplay()
			else
				onTap = ( ev  )=>
					w.removeEventListener('touchend', onTap)
					ev.preventDefault()
					canplay()
			w.addEventListener('touchend', onTap)
		)

		canplay=()=>
			detectMediaSource((supportsMediaElement)=>
				@context.resume()
				shouldBuffer = !supportsMediaElement
				start(@context, shouldBuffer)
			, @context)

		start=(audioContext, shouldBuffer)=>
			audio = audioPlayer(['audio/S03_ARCH.mp3'], {
				context: audioContext,
				buffer: shouldBuffer,
				loop: true
			})
			audio.on('load', ()=>
				audio.play()
				audioContext.resume()
				audio.node.connect(@masterGain)
			)

		# ---------------------------------------------------------------------- AUDIO ON / OFF

		@soundImg = document.querySelector('.sound')
		@soundImg.addEventListener('click',@toogleSound)

		# ---------------------------------------------------------------------- UPDATE / RESIZE LISTENERS
		Stage.onUpdate.add(@update)
		Stage.onResize.add(@resize)
		# Interactions.onMove.add(@onMove)
		@callback(1)
		return

	# -------------------------------------------------------------------------- UPDATE

	toogleSound:()=>
		@musicOn = !@musicOn
		if @musicOn
			@soundImg.src = "img/sound_on.png"
			@masterGain.connect(@context.destination)
		else
			@soundImg.src = "img/sound_off.png"
			@masterGain.disconnect()
		return

	update:(dt)=>
		Analyser.update(dt)

		# Post Effect
		# ?

		if(@psycho>0)
			@material.wireframe = Math.random()>.5
			@material.side = if Math.random()>.5 then THREE.OneSided else THREE.DoubleSided
		else
			@material.wireframe = false

		@torus.material.wireframe = @material.wireframe
		@torus.material.opacity *= 0.9

		@sphere2.material.opacity *= 0.9
		@sphere.material.opacity *= 0.9

		Stage3d.control.radius = 10+Analyser.volume*4

		@psycho -= dt
		return

	# -------------------------------------------------------------------------- onBeat

	onBeat:(e)=>
		# Camera
		if(Math.random()>.5)
			Stage3d.control.theta = Math.PI/4+Math.random()*Math.PI/2
			Stage3d.control.phi = 1+Math.random()

		if(Math.random()>.5)
			@torus.material.opacity = 1

		if(Math.random()>.8)
			@sphere.material.opacity = 1

		if(Math.random()>.94)
			@sphere2.material.opacity = 1


		Stage3d.control._radius = 10+Analyser.volume*7

		# Material
		if Math.random()>.9
			@psycho = 500
		return

	# -------------------------------------------------------------------------- onMove

	onMove:(e)=>

		return

	# -------------------------------------------------------------------------- RESIZE

	resize:()=>
		return

module.exports = Main

class window.CoreGame
  MOVE_SPEED = 300
  NUM_CLOUDS = 5 # max on screen at once
  
  # These other NUM constants are how many live at once
  # (not necessarily the number you see on screen).
  NUM_BALLOONS = 5
  NUM_BIRDS = 3
  
  # Maximum speeds (usually range is 50-100% of this value)
  MAX_CLOUD_SPEED = 200
  MAX_BALLOON_SPEED = 250
  MAX_BIRD_SPEED = 300
  MAX_BIRD_VERTICAL_SPEED = 50
  
  gameOver = false  
    
  create: () ->
    @game.physics.startSystem(Phaser.Physics.ARCADE)
    @numBalloonsCollected = 0
    
    @game.add.sprite(0, 0, 'sky')    
    @clouds = @game.add.group()
    @clouds.enableBody = true

    # NUM_CLOUDS clouds, randomly strewn
    for i in [1..NUM_CLOUDS]
      randomX = Math.random() * (2 * @game.width) # can start on-screen or off-screen
      randomY = Math.random() * @game.height
      cloud = @clouds.create(randomX, randomY, 'cloud')
      quarterSpeed = MAX_CLOUD_SPEED / 4      
      # 25-100% of MAX_CLOUD_SPEED
      cloud.body.velocity.x = -(Math.random() * 3 * quarterSpeed) - quarterSpeed      
      scale = this._pickCloudScale()
      cloud.scale.setTo(scale, scale)      
    
    @balloons = @game.add.group()
    @balloons.enableBody = true
      
    # NUM_BALLOONS balloons, randomly strewn
    this._spawnBalloon() for i in [1..NUM_BALLOONS]      
    
    # UI indicator
    balloons = @game.add.sprite(8, @game.height - 64 - 8, 'ui-balloons')
    #@numBalloons = @game.add.text(16, @game.height - 32, 'x0', { fill: '#000' })
    
    @birds = @game.add.group()
    @birds.enableBody = true
    this._spawnBird() for i in [1 .. NUM_BIRDS]      
    
    @player = @game.add.sprite(0, 0, 'player')
    @game.physics.enable(@player, Phaser.Physics.ARCADE)
    
    @blackout = @game.add.sprite(0, 0, 'blackout')
    @blackout.alpha = 1
    @game.add.tween(@blackout).to({ alpha: 0 }, 500, null).start()
    
    @game.camera.follow(@player)
    @cursors = game.input.keyboard.createCursorKeys()
    
    # Used for game-over and restart
    fadeInTween = @game.add.tween(@blackout)
    @fadeOutTween = @game.add.tween(@blackout)
    @fadeOutTween.to({ alpha: 1 }, 500, null)
    @fadeOutTween.onComplete.add(() ->
      @gameOverText.destroy()
      @scoreText.destroy()
      @restart.kill()
      
      fadeInTween.to({ alpha: 0 }, 500, null)
      fadeInTween.start()
      fadeInTween.onComplete.add(() ->
        @gameOver = false
        @restarting = false
      , this)
      
      this._reset()
    , this)
    
    # Debugging only    
    @game.time.advancedTiming = true
    #@fps = @game.add.text(0, 0, '', { fill: '#000' })
    
    window.setInterval(() =>
      message = "#{@game.time.fps} FPS"
      #@fps.text = message unless @game.time.fps == 0
      console.info(message) unless @game.time.fps == 0
    , 1000);
    
  update: () ->   
    this._checkForGameOver()
    this._respawnOffScreenClouds()
    this._applyWavesToBalloons()
    
    if (!@gameOver)
      @game.physics.arcade.overlap(@player, @balloons, this._balloonCollected, null, this)
      @game.physics.arcade.collide(@player, @birds)
      this._updatePlayerVelocity()    
      this._respawnOffScreenBalloons()
      this._respawnOffScreenBirds()      
    else
      if (game.input.activePointer.isDown)
        @gameOver = false
        # Don't allow multiple clicks while restarting
        if (!@restarting)
          @restarting = true
          @fadeOutTween.start()
        
    
  # begin: private methods
  
  _updatePlayerVelocity: () ->
    return if @gameOver == true
    if @cursors.up.isDown
      @player.body.velocity.y = -1 * MOVE_SPEED;
    else if @cursors.down.isDown
      @player.body.velocity.y = MOVE_SPEED;
    else
      # Standing still
    
    if @cursors.left.isDown
      @player.body.velocity.x = -1 * MOVE_SPEED;
    else if @cursors.right.isDown
      @player.body.velocity.x = MOVE_SPEED;
    else
      # Standing still
    
    # Decelerate
    @player.body.velocity.x *= 0.9 if @player.body.velocity.x != 0      
    @player.body.velocity.y *= 0.9 if @player.body.velocity.y != 0
      
    @player.body.velocity.x = 0 if Math.abs(@player.body.velocity.x) <= 5
    @player.body.velocity.y = 0 if Math.abs(@player.body.velocity.y) <= 5
    
  _respawnOffScreenClouds: () ->
    @clouds.forEach((cloud) ->
      if cloud.x <= -cloud.width
        cloud.x = this._pickRandomX()
        cloud.y = Math.random() * @game.height
        scale = this._pickCloudScale()
        cloud.scale.setTo(scale, scale)
    , this)
    
  _respawnOffScreenBalloons: () ->
    @balloons.forEach((balloon) ->
      if balloon.x <= -balloon.width
        balloon.x = this._pickRandomX()
        balloon.y = Math.random() * (@game.height - 64)
        balloon.randomY = (Math.random() * 500)
    , this)
  
  _respawnOffScreenBirds: () ->    
    @birds.forEach((bird) ->
      this._spawnBird(bird) if bird.x <= -bird.width
    , this)     
      
  _applyWavesToBalloons: () ->
    @balloons.forEach((balloon) ->
      balloon.y += (2 * Math.sin((@game.time.now + balloon.randomY) / 500))
    , this)
    
  _pickRandomX: () ->
    return @game.width + (Math.random() * @game.width)
  
  _pickCloudScale: () ->
    return 0.25 + (Math.random() * 0.75)
    
  _balloonCollected: (player, balloon) ->
      balloon.kill()
      @numBalloonsCollected += 1
      #@numBalloons.text = "x#{@numBalloonsCollected}"
      this._spawnBalloon()
      
  _spawnBalloon: () ->
    randomX = this._pickRandomX();
    randomY = Math.random() * (@game.height - 64)
    balloon = @balloons.create(randomX, randomY, 'balloon')
    # 50-100% of target speed
    halfSpeed = MAX_BALLOON_SPEED / 2
    balloon.body.velocity.x = -(Math.random() * halfSpeed) - halfSpeed
    balloon.randomY = (Math.random() * 2500)
    
  _spawnBird: (bird) ->
    randomX = this._pickRandomX()
    randomY = Math.random() * game.height
    
    if !bird?
      bird = @birds.create(randomX, randomY, 'bird')
      bird.body.immovable = true
    else
      bird.x = randomX
      bird.y = randomY      
    
    halfSpeed = MAX_BIRD_SPEED / 2    
    bird.body.velocity.x = -(Math.random() * halfSpeed) - halfSpeed
    bird.body.velocity.y = ((Math.random() * (MAX_BIRD_VERTICAL_SPEED / 2)) + (MAX_BIRD_VERTICAL_SPEED / 2))
    bird.body.velocity.y *= -1 if randomY >= @game.height / 2
    
  _checkForGameOver: () ->
    @oldGameOver = @gameOver
    @gameOver = true if @player.x <= -@player.width || @player.x >= @game.width || @player.y <= -@player.height || @player.y >= @game.height
    this._gameOver() if (@oldGameOver != true && @gameOver == true && !@restarting)
      
  _gameOver: () ->
    @gameOverText = @game.add.sprite(0, 0, 'ui-game-over')
    this._centerImage(@gameOverText)
    @gameOverText.y -= @gameOverText.height / 2
    
    @restart = @game.add.sprite(0, 0, 'ui-restart')
    this._centerImage(@restart)
    @restart.y = @gameOverText.y + @gameOverText.height + 48
    
    @player.body.velocity.x = 0
    @player.body.velocity.y = 0
    
    @scoreText = @game.add.text(350, @restart.y - 48, "Score: #{@numBalloonsCollected}")
    
  _centerImage: (sprite) ->
    sprite.x = (@game.width - sprite.width) / 2
    sprite.y = (@game.height - sprite.height) / 2
    
    @blackout.bringToTop()
    
  # After game over, on start-new-game
  _reset: () ->
    @restarting = false    
    @player.x = @player.y = 0
    @player.body.velocity.x = 0
    @player.body.velocity.y = 0
    @numBalloonsCollected = 0
    #@numBalloons.text = "x#{@numBalloonsCollected}"

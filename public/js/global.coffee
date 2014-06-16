# Dependencies
# Well, it's jQuery!
#= require vendor/jquery-1.7.1.min.js

# The great Modernizr to monitor feature support
#= require vendor/modernizr.custom.js

# Improve the touch experience by removing the tap delay
#= require vendor/fastclick.js

# Helper to bind the hash change event
#= require vendor/jquery-hashchange.js

# Allow jQuery to animate 2D transformations
#= require vendor/jquery.transform2d.js

# Imrpove the jQuery animate method by using CSS3 transitions when possible
#= require vendor/jquery.animate-enhanced.min.js

# Add the scrollTo method to jQuery
#= require vendor/jquery.scrollTo.min.js

# Add a better support for background position within the CSS method
#= require vendor/bgpos.js

# Patch the requestAnimationFrame function for better compatibility
#= require vendor/rAF.js

# Allow responsive iframe
#= require vendor/jquery.responsiveiframe.js

(($, window) ->
  $ui = $uis = null
  currentStep = 0
  scrollDuration = 300
  defaultEntranceDuration = 800
  maxWidth  = maxHeight = null

  ###*
   * Initializrs the page
  ###
  init = ->
    buildUI()
    buildAnimations()
    # Get container sizes
    maxWidth  = $ui.width()
    maxHeight = $ui.height()
    # Resize container and its spots
    scaleContainer()
    stepsPosition()
    spotsSize()
    spotsPosition()
    bindUI()
    # Allow resizable iframe
    window.ri = responsiveIframe()
    ri.allowResponsiveEmbedding()
    # Remove loading overlay
    $uis.body.removeClass "js-loading"
    # Read the step from the hash
    readStepFromHash()
    # Activate fast click to avoid tap delay on touch screen
    new FastClick(document.body)

  ###*
   * Gets every jquery shortcuts
   * @return {Object} Main page container
  ###
  buildUI = ->
    $ui = $("#container")
    $uis =
      wdw               : $(window)
      body              : $("body")
      steps             : $ui.find(".step")
      spots             : $ui.find(".spot")
      overflow          : $("#overflow")
      navitem           : $("#overflow .to-step")
      previous          : $("#overflow .nav .arrows .previous")
      next              : $("#overflow .nav .arrows .next")
      tinyScroll        : $("#overflow .nav .tiny-scroll")
      tinyScrollTracker : $("#overflow .nav .tiny-scroll .tracker")
    return $ui

  ###*
   * Bind javascript event on page elements
   * @return {Object} jQuest window ibject
  ###
  bindUI = ->
    $uis.steps.on "click", ".spot", showSpot
    $uis.previous.on "click", previousStep
    $uis.next.on "click", nextStep
    $(window).keydown keyboardNav
    $(window).resize resize
    $(window).hashchange readStepFromHash
    # Open links begining by http in a new window
    $("a[href^='http://']").attr "target", "_blank"
    $("a[href^='https://']").attr "target", "_blank"



  ###*
   * Builds the animations array dynamicly to allow relative computation
   * @return {Array} List of animations
  ###
  buildAnimations = ->
    # Entrance animations patterns
    @entrance =
      fadeIn:
        from: { opacity: '0' }
        to:   { opacity: '1' }

      up:
        from: { top: $ui.width(), left: 0 }
        to:   { top: 0 }

      down:
        from: { top: -1 * $ui.width(), left: 0 }
        to:   { top: 0 }

      left:
        from: { left: $ui.width(), top: 0  }
        to:   { left: 0 }

      right:
        from: { left: -1 * $ui.width(), top: 0 }
        to:   { left: 0 }

      stepUp:
        from: { top: 100, left: 0}
        to:   { top: 0 }

      stepDown:
        from: { top: -100, left: 0}
        to:   { top: 0 }

      stepLeft:
        from: { left: 100, top: 0}
        to:   { left: 0 }

      stepRight:
        from: { left: -100, top: 0}
        to:   { left: 0 }

      zoomIn:
        from: { transform: "scale(0)" }
        to:   { transform: "scale(1)" }

      zoomOut:
        from: { transform: "scale(2)" }
        to:   { transform: "scale(1)" }

      clockWise:
        from: { transform: "rotate(0deg)" }
        to:   { transform: "rotate(360deg)" }

      counterClockWise:
        from: { transform: "rotate(0deg)" }
        to:   { transform: "rotate(-360deg)" }

      topRightCorner:
        from: ($spot)->
          left: $spot.outerWidth(), top: -$spot.outerHeight()
        to:
          left: 0, top: 0

      topLeftCorner:
        from: ($spot)->
          left: -$spot.outerWidth(), top: -$spot.outerHeight()
        to:
          left: 0, top: 0

      bottomRightCorner:
        from: ($spot)->
          left: $spot.outerWidth(), top: $spot.outerHeight()
        to:
          left: 0, top: 0

      bottomLeftCorner:
        from: ($spot)->
          left: -$spot.outerWidth(), top: $spot.outerHeight()
        to:
          left: 0, top: 0


  ###*
   * Scale the size of the container
   * @return {Number} Scale applied to the container
  ###
  scaleContainer = ->
    return unless Modernizr.csstransforms
    scale = Math.min 1, $uis.wdw.width() / maxWidth
    # Allow the parent iframe to fits with the container
    $uis.body.css "min-height", $uis.overflow.height() * scale
    $uis.overflow.css "transform", "scale(#{scale})"
    scale

  ###*
   * Position every steps in the container
   * @return {Array} Steps list
  ###
  stepsPosition = ->
    $uis.steps.each (i, step) ->
      $step = $(step)
      switch $uis.overflow.data("navigation")
        when "vertical"
          $step.css "top",  i * maxHeight
        else
          $step.css "left", i * maxWidth

  ###*
   * Resize every spots according its wrapper
   * @return {Array} Spots list
  ###
  spotsSize = ->
    $uis.spots.each (i, spot) ->
      $spot = $(this)
      $spot.css "width",  $spot.find(".js-animation-wrapper").outerWidth()
      $spot.css "height", $spot.find(".js-animation-wrapper").outerHeight()


  ###*
   * Position every spots in each steps
   * @return {Array} Spots list
  ###
  spotsPosition = ->

    # Add a negative margin on each spot
    # (position the spot from its center)
    $uis.spots.each (i, spot) ->
      $spot = $(spot)
      if $spot.data("origin") == "center"
        $spot.css "margin-left", $spot.outerWidth() / -2
        $spot.css "margin-top", $spot.outerHeight() / -2

  ###*
   * TODO: open a contextual popin when clicking on a spot
   * @param  {Object} event Click event
   * @return {[type]}       [description]
  ###
  showSpot = (event) ->
    $this = $(this)
    alert $this.data("html")  if $this.data("html")

  ###*
   * Bind the keyboard keydown event to navigate through the page
   * @param  {Object} event Keydown event
   * @return {Object}       Keydown event
  ###
  keyboardNav = (event) ->
    switch event.keyCode
      # Left and up
      when 37, 38 then previousStep()
      # Right and down
      when 39, 40 then nextStep()
      # Stop here for the other keys
      else return event
    event.preventDefault()

  ###*
   * Go to the previous step
   * @return {Number} New current step number
  ###
  previousStep = ->
    changeStepHash 1 * currentStep - 1

  ###*
   * Go to the next step
   * @return {Number} New current step number
  ###
  nextStep = ->
    changeStepHash 1 * currentStep + 1

  ###*
   * Change the URL hash to fit to the given step
   * @param  {Number} step Target step
   * @return {String}      New location hash
  ###
  changeStepHash = (step=0) ->
    location.hash = "#step=" + step  if step >= 0 and step < $uis.steps.length

  ###*
   * Just go to step directcly
   * @return {Number} New step number
  ###
  readStepFromHash = -> goToStep getHashParams().step or 0

  ###*
   * Slide to the given step
   * @param  {Number} step New current step number
   * @return {Number}      New current step number
  ###
  goToStep = (step=0) ->
    if step >= 0 and step < $uis.steps.length
      # Update the current step id
      currentStep = 1 * step
      # Prevent scroll queing
      jQuery.scrollTo.window().queue([]).stop()
      # Change the way to scroll according the navigation
      switch $uis.overflow.data("navigation")
        when "vertical"
          params = 'top': maxHeight*currentStep, 'left': 0
        else
          params = 'left': maxWidth*currentStep, 'top': 0
      # Then scroll
      $ui.scrollTo params, scrollDuration
      # Remove current class
      $uis.steps.removeClass("js-current").eq(currentStep).addClass "js-current"
      # Add a class to the body
      # Is this the first step ?
      $uis.body.toggleClass "js-first", currentStep is 0
      # Is this the last step ?
      $uis.body.toggleClass "js-last", currentStep is $uis.steps.length - 1
      # Update the menu
      $uis.navitem.removeClass("active").filter("[data-step=#{currentStep}]").addClass("active")
      # Hides element with entrance
      $uis.steps.eq(currentStep).find(".spot[data-entrance] .js-animation-wrapper").addClass "hidden"
      # Clear all spot animations
      clearSpotAnimations()
      # Add the entrance animation after the scroll
      setTimeout doEntranceAnimations, scrollDuration
      # Update the tiny scroll
      updateTinyScroll()
    return currentStep

  ###*
   * Set step animations
  ###
  doEntranceAnimations = ->
    # Launch hotspot background animations
    doSpotAnimations()
    # Find the current step
    $step = $uis.steps.filter(".js-current")
    # Number of element behind before animate the entrance
    queue = 0
    # Find spots with animated entrance
    $step.find(".spot[data-entrance]").each (i, elem) ->
      $elem = $(elem)
      # Get tge data from the element
      data = $elem.data()
      # Works on an animation wrapper
      $wrapper = $elem.find(".js-animation-wrapper")
      # Get the animation keys of the given element
      animationKeys = data.entrance.split(" ")
      # Clear existing timeout
      clearTimeout $wrapper.t  if $wrapper.t
      # Initial layout
      from = to = {}
      # For each animation key
      $.each animationKeys, (i, animationKey)->
        # Get the animation (and create a clone object)
        animation = $.extend true, {}, entrance[animationKey]
        # If the animation exist
        if animation?
          # Merge the layout object recursively
          if typeof(animation.from) is 'function'
            from = $.extend true, animation.from($elem), from
          else
            from = $.extend true, animation.from, from
          if typeof(animation.to) is 'function'
            to   = $.extend true, animation.to($elem), to
          else
            to   = $.extend true, animation.to, to

      # Stop every current animations and show the element
      # Also, set the original style if needed
      $wrapper.stop().css(from).removeClass "hidden"
      # Only if a "to" layout exists
      if to?
        # If there is a queue
        queue++  if $elem.data("queue")?
        # Take the element entrance duration
        # or default duration
        duration = data.entranceDuration or defaultEntranceDuration

        # explicite duration
        if $elem.data("queue") > 1
          entranceDelay = $elem.data("queue")
        else
          # calculate the entrance duration according the number of element before
          entranceDelay = duration * queue

        # Wait a duration...
        $wrapper.t = setTimeout(
          # Closure function to transmit "to"
          (
            (to)->
              ->
                # ...before animate the wrapper
                $wrapper.animate to, duration
          )(to)
        # ...and increase the queue
        , entranceDelay)


  ###*
   * Clear every spots animations
   * @return {Array} Spots list
  ###
  clearSpotAnimations = ->
    $uis.spots.each (i, spot) ->
      $spot = $(spot)
      if $spot.d
        window.cancelAnimationFrame $spot.d
        delete ($spot.d)

  ###*
   * Trigger spots background animations in the current step
   * @return {Array} List of the spots
  ###
  doSpotAnimations = ->
    # Find the current step
    $step = $uis.steps.filter(".js-current")
    # Find its spots
    $spots = $step.find(".spot")

    # On each spot, create an animation
    $spots.each (i, spot) ->
      data = $(spot).data()
      requestField = "d"

      # Is there a background and an animation on it
      if data["background"] and data["backgroundDirection"] isnt `undefined`
        # Reset background position
        $(spot).find(".js-animation-wrapper").css "background-position", "0 0"
        # Clear existing request animation frame
        window.cancelAnimationFrame spot[requestField]  if spot[requestField]
        requestParams = closureAnimation(spot, requestField, renderSpotAnimation)
        # Add animation frame with a closure function
        spot[requestField] = window.requestAnimationFrame(requestParams)

  ###*
   * Process spot rendering
   * @param  {Object} spot Spot html element
   * @return {Array}       Directions array
  ###
  renderSpotAnimation = (spot) ->
    $spot = $(spot)
    $wrapper = $spot.find ".js-animation-wrapper"
    data = $spot.data()
    directions = ("" + data.backgroundDirection).split(" ")
    speed = data.backgroundSpeed or 3
    lastRAF = spot.lastRAF or 0

    # Skip this render if its too early
    return false if new Date().getTime() - lastRAF < (data.backgroundFrequency or 0)

    # Set the time of the last animation
    spot.lastRAF = new Date().getTime()

    # Allow several animation
    $(directions).each (i, direction) ->
      switch direction
        when "left"
          $wrapper.css "backgroundPositionX", "-=" + speed
        when "right"
          $wrapper.css "backgroundPositionX", "+=" + speed
        when "top"
          $wrapper.css "backgroundPositionY", "-=" + speed
        when "bottom"
          $wrapper.css "backgroundPositionY", "+=" + speed
        else
          # We receive a number,
          # we interpret it as a direction degree
          unless isNaN(direction)
            radian = direction * Math.PI / 180.0
            x0 = $wrapper.css("backgroundPositionX")
            y0 = $wrapper.css("backgroundPositionY")
            x = speed * Math.cos(radian)
            y = speed * Math.sin(radian)
            $wrapper.css "backgroundPositionX", "+=" + x
            $wrapper.css "backgroundPositionY", "+=" + y

  ###*
   * Closure function to execute the given function within the receive element
   * @param  {Object}   elem         HTML element
   * @param  {String}   requestField Name of the field into elem where record the animation frame
   * @param  {Function} func         Callback function of the animation
  ###
  closureAnimation = (elem, requestField, func) ->
    ->
      # Continue to the next frame
      # Add animation frame with a closure function
      elem[requestField] = window.requestAnimationFrame(closureAnimation(elem, requestField, func))  if elem[requestField]
      # Apply the animation render
      func

  ###*
   * Update a tiny scroll in the to left corner
  ###
  updateTinyScroll = ->
    # If the tiny scroll exists
    if $uis.tinyScroll.length
      # Fixed value
      # (note: it's totaly the wrong way but we're are quiet un hurry)
      trackerHeight = 37
      trackerSpace  = 100
      # Calculate the progression according the current step
      progression   = currentStep/($uis.steps.length-1)
      # Deduce the background position
      backgroundPositionY = (trackerSpace - trackerHeight) * progression
      # Update the tracker background
      $uis.tinyScrollTracker.css backgroundPositionY: backgroundPositionY


  ###*
   * Bind the windows rezie event
  ###
  resize = -> scaleContainer()

  ###*
   * Read the parameters into the location hash using the following format:
   * /#foo=2&bar=3
   * @copyright http://stackoverflow.com/questions/4197591/parsing-url-hash-fragment-identifier-with-javascript#comment10274416_7486972
   * @return {Object} Data object]
  ###
  getHashParams = ->
    hashParams = {}
    e = undefined
    a = /\+/g # Regex for replacing addition symbol with a space
    r = /([^&;=]+)=?([^&;]*)/g
    d = (s) ->
      decodeURIComponent s.replace(a, " ")

    q = window.location.hash.substring(1)
    hashParams[d(e[1])] = d(e[2])  while e = r.exec(q)
    hashParams

  # When the window is completely loaded, launch the page !
  $(window).load init

) jQuery, window
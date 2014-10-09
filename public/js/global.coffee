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

# Spot's tooltips
#= require vendor/jquery.tooltipster.min.js

(($, window) ->
  $ui = $uis = null
  currentStep = 0
  scrollDuration = 600
  defaultEntranceDuration = 800
  maxWidth  = maxHeight = null
  entranceTimeout = animationTimeout = null

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
    spotsLayout()
    spotsPosition()
    bindUI()
    # Allow resizable iframe
    window.ri = responsiveIframe()
    ri.allowResponsiveEmbedding() ; ri.messageParent(false)
    # Remove loading overlay
    $uis.body.removeClass "js-loading"
    # Read the step from the hash
    readStepFromHash()
    # Activate fast click to avoid tap delay on touch screen
    new FastClick(document.body)
    # Activate tooltips
    $('.js-tooltip').tooltipster contentAsHTML: yes, theme: 'tooltipster-light'

  ###*
   * Gets every jquery shortcuts
   * @return {Object} Main page container
  ###
  buildUI = ->
    $ui = $("#container")
    $uis =
      wdw               : $(window)
      body              : $("body")
      nav               : $(".nav .steps")
      navToggler        : $(".js-nav-toggler")
      analyse           : $("#analyse")
      analyseToggler    : $(".js-analyse-toggler")
      steps             : $ui.find(".step")
      spots             : $ui.find(".spot")
      parallaxes        : $ui.find("[data-parallax]")
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
    $uis.navToggler.on 'click', -> $uis.nav.toggleClass "hidden"
    $uis.analyseToggler.on 'click', -> $uis.analyse.toggleClass "hidden"
    $uis.steps.on "click",      ".spot", clickSpot
    $uis.steps.on "mouseenter", ".spot", enterSpot
    $uis.steps.on "mouseleave", ".spot", leaveSpot
    $uis.previous.on "click", previousStep
    $uis.next.on "click", nextStep
    $(window).keydown keyboardNav
    $(window).resize resize
    $(window).hashchange readStepFromHash
    # Open links begining by http in a new window
    $("[href^='http://']").attr "target", "_blank"
    $("[data-href^='http://']").attr "target", "_blank"
    $("[href^='https://']").attr "target", "_blank"
    $("[data-href^='https://']").attr "target", "_blank"
    # Update element with parallax
    updateParallaxes() if Modernizr.csstransforms and $uis.parallaxes.length



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
  spotsLayout = ->
    $uis.spots.each (i, spot) ->
      $spot = $(@)
      $spot.toggleClass "clickable", $spot.data("href")? or $spot.data("activable")?
      # Save intial class
      $spot.data "initial-class", $spot.attr("class")
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
   * Click on a spot
   * @param  {Object} event Click event
   * @return {[type]}       [description]
  ###
  clickSpot = (event) ->
    $this = $(@)
    # Open a link if need
    if $this.data("href")?
      if $this.attr("target") is "_blank"
        window.open $this.data("href"), '_blank'
      else
        window.location = $this.data("href")
    # Get the "activable" option for this spot
    activable = $this.data("activable")
    # This spot can be activated
    if activable
      # Find the current step
      $step = $uis.steps.filter(".js-current")
      # Class to apply to active element
      activeClass = $this.data("active-class") or "js-active"
      # If the activable option is a string
      # we may disable other element of the same family
      selector = if activable isnt "data-activable" then activable else "." + activeClass
      $step.find(selector).each ->
        # Each element must have a custom active class
        relativeActiveClass = $(@).data("active-class") or activeClass
        $(@).removeClass activeClass
      # Add the right class to this spot
      $this.addClass activeClass
      # Play spots animations
      doEntranceAnimations(no)

  ###*
   * Mouse enter on a spot
   * @param  {Object} event Click event
   * @return {[type]}       [description]
  ###
  enterSpot = (event)->
    clickSpot.call(@, event) if $(@).data("trigger") is "hover"
  ###*
   * Mouse leave a spot
   * @param  {Object} event Click event
   * @return {[type]}       [description]
  ###
  leaveSpot = (event) ->
    $this = $(@)
    # Should we deactivate this element
    if $this.data("activable") and $this.data("trigger") is "hover"
      # Class to remove from the active element
      activeClass = $this.data("active-class") or "js-active"
      # This spot can be activated
      $this.removeClass activeClass
      # Play spots animations
      doEntranceAnimations(no)

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
      $uis.steps.removeClass("js-current js-next js-previous").eq(currentStep).addClass "js-current"
      # Previous and next slide have a special class
      $uis.steps.eq(currentStep - 1).addClass "js-previous"
      $uis.steps.eq(currentStep + 1).addClass "js-next"
      # Add a class to the body
      # Is this the first step ?
      $uis.body.toggleClass "js-first", currentStep is 0
      # Is this the last step ?
      $uis.body.toggleClass "js-last", currentStep is $uis.steps.length - 1
      # We are animating the step
      $uis.body.addClass "js-animating"
      # Update the menu
      $uis.navitem.removeClass("js-active").filter("[data-step=#{currentStep}]").addClass("js-active")
      # Hides element with entrance
      # Remove every previous animations
      $uis.steps.eq(currentStep).find(".spot[data-entrance] .js-animation-wrapper").addClass("hidden")
      # Clear all spot animations
      clearSpotAnimations()
      # Pre-hide unresolved spots
      $uis.steps.eq(currentStep).find(".spot").each ->
        $spot = $(@)
        $spot.attr "class", $spot.data("initial-class")
        # Hide the wrapper
        $spot.find(".js-animation-wrapper").addClass("hidden") unless isResolved($spot)
      # Clear existing timeout
      window.clearTimeout(entranceTimeout)
      window.clearTimeout(animationTimeout)
      # Add the entrance animation after the scroll
      entranceTimeout = setTimeout ->
        # Remove the body class 'js-animating' when animations are over
        animationTimeout = setTimeout ->
          # Notices that the application is running animation
          $uis.body.removeClass "js-animating"
        # The function to setup animation returns the duration
        # of the animation
        , doEntranceAnimations()
      , scrollDuration
      # Update the tiny scroll
      updateTinyScroll()
    return currentStep

  ###*
   * Function to check if the given element is resolved
  ###
  isResolved = ($spot)->
    resolved = yes
    if resolve = $spot.data("resolve")
      $resolve = $(resolve)
      # This spot might have a "resolve" option.
      # This means that the element with the name inside the resolve
      # option must be activated
      $resolve.each ->
        $r = $(@)
        # Every element to resolve must be activated
        resolved &= $r.hasClass($r.data("active-class") or 'js-active')
    # Also check parents
    $spot.parents(".spot").each -> resolved &= isResolved $(@)
    # Continue to the next spot if $resolve is not activated
    resolved

  ###*
   * Set step animations
  ###
  doEntranceAnimations = (stepEntrance=yes)->
    # Launch hotspot background animations
    doSpotAnimations()
    # Find the current step
    $step = $uis.steps.filter(".js-current")
    # Those spots
    $spots = $step.find(".spot")
    # Delay added
    queueDelay = 0
    # Function to check if the given element is resolved
    isResolved = ($spot)->
      resolved = yes
      if resolve = $spot.data("resolve")
        $resolve = $(resolve)
        # This spot might have a "resolve" option.
        # This means that the element with the name inside the resolve
        # option must be activated
        $resolve.each ->
          $r = $(@)
          # Every element to resolve must be activated
          resolved &= $r.hasClass($r.data("active-class") or 'js-active')
      # Also check parents
      $spot.parents(".spot").each -> resolved &= isResolved $(@)
      # Continue to the next spot if $resolve is not activated
      resolved
    # Find spots with animated entrance
    $spots.each (i, spot) ->
      $spot = $(spot)
      $wrapper = $spot.find(".js-animation-wrapper")
      # Does this element was resolved before?
      previouslyResolved = $spot.data("previously-resolved")? and $spot.data("previously-resolved")
      # Stop if the given element isnt resolved
      unless isResolved $spot
        # First entrance doesn't animate hidden element
        unless previouslyResolved
          # Hide every unresolved elements
          $wrapper.addClass("hidden")
        else
          # Animate the spot without delay
          # Note: the third option plays the animation in the other direction
          animateSpot $spot, 0, no
        # Can't be animated next time
        $spot.data("previously-resolved", no)
      else
        if not previouslyResolved or stepEntrance
          # Can't be animated next time
          $spot.data("previously-resolved", yes)
          # Animate the spot after the queued delay and update it
          queueDelay = animateSpot $spot, queueDelay
        else
          # Prevent from element to not being display
          $wrapper.removeClass("hidden")
    return queueDelay


  animateSpot = ($spot, queueDelay, show=yes)->
    # Get tge data from the element
    data = $spot.data()
    # Works on an animation wrapper
    $wrapper = $spot.find(".js-animation-wrapper")
    # Get the animation keys of the given element
    animationKeys = (data.entrance or "").split(" ")
    # Clear existing timeout
    clearTimeout $wrapper.t if $wrapper.t
    # Initial layout
    [from, to] = getAnimationFrames animationKeys, show
    # Stop every current animations and show the element
    # Also, set the original style if needed
    $wrapper.stop().css(from).removeClass "hidden"
    # Hidden the element after the animation when not showing
    callback = if show then (->) else (($wrapper)->-> $wrapper.addClass("hidden") )($wrapper)
    # Only if a "to" layout exists
    if to?
      # Take the element entrance duration
      # or default duration
      duration = data.entranceDuration or defaultEntranceDuration
      # If there is a queue
      if $spot.data("queue")?
        # explicite duration
        if $spot.data("queue") > 1
          entranceDelay = $spot.data("queue")
          queueDelay = entranceDelay + duration
        else
          # calculate the entrance duration according the number of element before
          entranceDelay = queueDelay
          queueDelay += duration
      else
        # Add the entrance delay for the next element
        queueDelay = Math.max queueDelay, duration
      # Wait a duration...
      # Closure function to transmit "to"
      $wrapper.t = setTimeout ((to)->->
          # ...before animate the wrapper
          $wrapper.animate to, duration, callback
        )(to)
      # ...and increase the queue
      , entranceDelay or 0
    # No animation, just callb the callback
    else do callback

    return queueDelay

  ###*
   * Returns an array of the states of the given animations
   * @return {Array} From state and To state
  ###
  getAnimationFrames = (animationKeys, show=yes)->
    # Initial layout
    from = to = {}
    # For each animation key
    $.each animationKeys, (i, animationKey)->
      # Get the animation (and create a clone object)
      animation = $.extend true, {}, entrance[animationKey]
      # If the animation exist
      if animationKey isnt "" and animation?
        if animation.from.transform?
          return unless Modernizr.csstransforms
        # Merge the layout object recursively
        if typeof(animation.from) is 'function'
          from = $.extend true, animation.from($spot), from
        else
          from = $.extend true, animation.from, from
        if typeof(animation.to) is 'function'
          to   = $.extend true, animation.to($spot), to
        else
          to   = $.extend true, animation.to, to
    return if show then [from, to] else [to, from]

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

    requestField = "d"
    # On each spot, create an animation
    $spots.each (i, spot) ->
      $spot = $(spot)
      data  = $spot.data()
      # Is there a background and an animation on it
      if data["background"] and data["backgroundDirection"] isnt `undefined`
        # Reset background position
        $spot.find(".js-animation-wrapper").css "background-position", "0 0"
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
   * Update the parallaxes positions
   * @return {[type]} [description]
  ###
  updateParallaxes = ()=>
    window.requestAnimationFrame updateParallaxes
    # According the navigation type...
    switch $uis.overflow.data("navigation")

      when "horizontal"
        # ...extract the property to change
        offset  = "left"
        prop    = "translateX"

      when "vertical"
        # ...extract the property to change
        offset  = "top"
        prop    = "translateY"

    # Distance from the top of the window
    refDist = $ui.offset()[offset]
    # Apply a function to each parallax element
    $uis.parallaxes.each (i, parallax)=>
      $parallax = $(parallax)
      # The step containing the parallax
      $step = $parallax.closest('.step')
      # Distance of the parent step from the top of the container
      delta = $step.offset()[offset] - refDist
      # Speed of the movement
      speed = 1 * ( $parallax.data("parallax") or 0.5 )
      # Transform the position using the right property
      $parallax.css "transform", "#{prop}(#{speed*delta}px)"

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
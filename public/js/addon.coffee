(($, window) ->
  $ui = $uis = null

  ###*
   * Initializrs the page
  ###
  init = ->
    buildUI()
    bindUI()

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
      nav               : $(".nav .steps")
      navToggler        : $(".js-nav-toggler")
      analyse           : $("#analyse")
      analyseToggler    : $(".js-analyse-toggler")
    return $ui

  ###*
   * Bind javascript event on page elements
   * @return {Object} jQuest window ibject
  ###
  bindUI = ->
    $uis.navToggler.on 'click', -> $uis.nav.toggleClass "hidden"
    $uis.analyseToggler.on 'click', ->
      # Get analyse content from "hidden-content" attribute
      content = $uis.steps.filter(".js-current").find(".hidden-content").html() or ""
      # Update analyse content
      $uis.analyse.find(".js-content").html(content)
      # Display or show the popup
      $uis.analyse.toggleClass "hidden"

  # When the window is completely loaded, launch the page !
  $(window).load init

) jQuery, window
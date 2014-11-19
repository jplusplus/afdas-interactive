# Pointer event polyfill for IE
#= require vendor/pointer_events_polyfill.js

(($, window) ->
  $ui = $uis = null

  ###*
   * Initializrs the page
  ###
  init = ->
    buildUI()
    bindUI()
    PointerEventsPolyfill.initialize({})

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
      analyseContent    : $("#analyse-content")
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
      content = $(".js-current .hidden-content").html() or ""
      # Update analyse content
      $uis.analyseContent.html(content)
      # Display or show the popup
      $uis.analyse.toggleClass "hidden"

  # When the window is completely loaded, launch the page !
  $(window).load init

) jQuery, window
### Module dependencies ###
express = require("express")
http    = require("http")
path    = require("path")

# Create the Express app
app = express()

###*
 * App configuration callback
 * @return {Object} The app
###
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.set "page", "page/"
  app.set "data", __dirname + "/data"

  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()

  ### Public assets managers ###
  app.use require("connect-assets")(src: __dirname + "/public")
  app.use express.static(path.join(__dirname, "public"))

  ### Views helpers ###
  # Register helpers for use in view's
  app.locals require("./utils").locals
  # Add context helpers
  app.use require("./utils").context

  ### Configure router ###
  # @warning Needs to be after helpers
  app.use app.router
  # Load the default route file
  require("./routes") app

app.configure "development", ->
  app.locals.pretty = yes
  app.use express.errorHandler()

app.configure "production", ->
  app.locals.pretty = yes


http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

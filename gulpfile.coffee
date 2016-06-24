gulp = require 'gulp'
gutil = require 'gulp-util'
clean = require 'gulp-clean'
mocha = require 'gulp-mocha'
cache = require 'gulp-cached'
coffee = require 'gulp-coffee'
webpack = require 'webpack-stream'
exec = require('child_process').exec
coffeelint = require 'gulp-coffeelint'
webpackConfig = require './webpack.config'

gulp.task 'clean', ->
  cache.caches = {}
  gulp.src(['.coffee/', 'lib/', 'doc/api.md', 'min/']).pipe(clean())

gulp.task 'test', ->
  gulp.src(['test/**/*-spec.coffee'], read: false)
    .pipe(mocha(reporter: 'nyan'))

gulp.task 'javascript', ->
  gulp.src('src/**/*.js')
    .pipe(cache('javascript'))
    .pipe(gulp.dest('lib/'))

gulp.task 'coffeescript', ->
  gulp.src('./src/**/*.coffee')
    .pipe(cache('coffeescript'))
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
    .pipe(coffee(bare: true).on('error', gutil.log))
    .pipe(gulp.dest('lib/'))

gulp.task 'doc', (cb) ->
  exec './node_modules/atomdoc-md/bin/atomdoc-md.js generate . -o doc -n api.md', (err, stdout, stderr) ->
    cb(err)

gulp.task 'webpack', ['javascript', 'coffeescript'], ->
  gulp.src('lib/index.js')
    .pipe(webpack(webpackConfig))
    .pipe(gulp.dest('min/'))

gulp.task 'webpack:watch', ['javascript', 'coffeescript'], ->
  config = Object.create(webpackConfig)
  config.watch = true
  config.plugins = [] # remove uglify
  gulp.src('lib/index.js')
    .pipe(webpack(config))
    .pipe(gulp.dest('min/'))

gulp.task 'prepublish', ['clean', 'test', 'doc'], ->
  gulp.start('webpack')

gulp.task 'watch', ['clean', 'test', 'doc'], ->
  gulp.watch('src/**/*', ['javascript', 'coffeescript', 'test', 'doc'])
  gulp.watch('test/**/*', ['test'])
  gulp.start('webpack:watch')

gulp.task 'default', ['watch'], ->

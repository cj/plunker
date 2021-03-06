#= require ../../services/panels
#= require ../../services/scratch
#= require ../../services/url

debounce = (func, wait, immediate) ->
  timeout = undefined
  ->
    context = @
    args = arguments
    later = ->
      timeout = null
      unless immediate then func.apply(context, args)
    if immediate and not timeout then func.apply(context, args)
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)


module = angular.module("plunker.panels")

module.run ["$http", "panels", "scratch", "url", ($http, panels, scratch, url) ->
  panels.push new class
    name: "preview"
    order: 0
    title: "Preview your work in real-time"
    icon: "icon-eye-open"
    template: """
      <div class="plnk-previewer">
        <div id="preview-ops">
          <div class="btn-toolbar">
            <div class="btn-group">
              <button id="refresh-preview" ng-click="refreshPreview()" class="btn btn-mini btn-success"><i class="icon-refresh icon-white"></i></button>
            </div>
          </div>
        </div>
        <iframe class="plnk-runner" frameborder="0" width="100%" height="100%" scrolling="auto"></iframe>
      </div>
    """
    refreshPreview: ->
      self = @
      json = { files: {} }
      
      for buffer in scratch.buffers.queue
        json.files[buffer.filename] =
          content: buffer.content
      
      self.$preview.fadeOut("")
      
      request = $http.post(url.run, json)
      
      request.then (response) ->
        self.$preview[0].contentWindow.location.replace(response.data.run_url)
        self.$preview.fadeIn(10).ready ->
          self.badge = null
          
    link: ($scope, el, attrs) ->
      self = @
      @el = el
      @$preview = $(".plnk-runner", el)
      @enabled = false
      @awaiting = false
      
      refresh = angular.bind(@, debounce(@refreshPreview, 750))
      
      $scope.scratch = scratch
      $scope.refreshPreview = refresh
      
      handleChange = ->
        if self.enabled
          self.awaiting = false
          refresh()
        else
          self.awaiting = true
          self.badge =
            class: "badge badge-important"
            title: "Click here to preview your changes"
            value: "*"        
      
      $scope.$on "buffer:change:content", handleChange
      $scope.$on "buffer:change:filename", handleChange
      $scope.$on "buffer:add", handleChange
      $scope.$on "buffer:remove", handleChange
      
    deactivate: ($scope, el, attrs) ->
      @enabled = false
      
    activate: ($scope, el, attrs) ->
      
      @enabled = true
      if @awaiting
        @refreshPreview()
        @awaiting = false
]
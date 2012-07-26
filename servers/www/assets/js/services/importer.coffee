plunkerRegex = ///
  ^
    \s*                   # Leading whitespace
    (?:plunk:)?           # Optional plunk:prefix
    ([a-zA-Z0-9]+)        # Plunk ID
    \s*                   # Trailing whitespace
  $
///i

githubRegex = ///
  ^
    \s*                   # Leading whitespace
    (?:                   # Optional protocol/hostname
      (?:https?\://)?     # Protocol
      gist\.github\.com/  # Hostname
    |
      gist\:
    )
    ([0-9]+|[0-9a-z]{20}) # Gist ID
    (?:#.+)?              # Optional anchor
    \s*                   # Trailing whitespace
  $
///i


module = angular.module("plunker.importer", ["plunker.plunks"])

module.factory "importer", [ "$q", "$http", "Plunk", ($q, $http, Plunk) ->
  import: (source) ->
    deferred = $q.defer()
    
    if matches = source.match(plunkerRegex)
      Plunk.get {id: matches[1]}, (plunk) ->
        deferred.resolve(angular.copy(plunk))
      , (error) ->
        deferred.reject("Plunk not found")
    else if matches = source.match(githubRegex)
      request = $http.jsonp("https://api.github.com/gists/#{matches[1]}?callback=JSON_CALLBACK")
      
      request.then (response) ->
        if response.data.meta.status >= 400 then deferred.reject("Gist not found")
        else
          gist = response.data.data
  
          json =
            source:
              type: "gist"
              url: gist.html_url
              title: "gist:#{gist.id}"
            files: {}
          
          json.description = json.source.description = gist.description if gist.description

          if manifest = gist.files["plunker.json"]
            try
              angular.copy(angular.fromJson(manifest.content), json)                

          for filename, file of gist.files
            unless filename == "plunker.json"
              json.files[filename] =
                filename: filename
                content: file.content 
          
          deferred.resolve(json)
    else deferred.reject("Not a recognized source")
          
    deferred.promise
]
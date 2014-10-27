#import jTester namespace
jTester = window.jTester
__require = jTester.require
__nw = __require.nw
__views = jTester.views
__config = jTester.config

#class IndexCtrl
angularapp = window.angularapp
angularapp.controller 'IndexCtrl' ,
  class IndexCtrl
    constructor : ($scope ,$modal , $timeout , $location) ->
      $scope.loading = true
      $timeout ()->
        $scope.loading = false
      , 1500

      #static class jTester.alert
      jTester.alert =
        show : (type , message , timeout)->
          timeout = timeout || 3000
          $modal.open {
            templateUrl : __views.alert
            backdrop : 'center'
            resolve : {
              message : ()->
                return message
              type : ()->
                return type
              timeout : ()->
                return timeout
            }
            controller: ($scope , $modalInstance , $timeout , message , type, timeout)->
              $scope.message = message
              $scope.type = type
              $timeout ()->
                $modalInstance.close 'dismiss'
              , timeout
          }
        success : (message , timeout)->
          @show('success' , message, timeout)
        error : (message, timeout)->
          @show('danger' , message, timeout)

      #static class jTester.file
      jTester.file =
        openFile : ($context)->
          $modal.open {
            templateUrl: __views.uploadfile
            backdrop : 'static'
            resolve :{
              context : ()->
                return $context
            }
            controller : 'UploadFileCtrl'
          }
        saveFile : ($context)->
          $modal.open {
            templateUrl: __views.savefile
            backdrop : 'static'
            resolve :{
              context : ()->
                return $context
            }
            controller: 'SaveFileCtrl'
          }

      changepath = (path)->
        $location.path path
        #invoke after path change
        $scope.$apply()

      $scope.navigate = [ 'Run' , 'HTTP']
      #all menus events
      menus = [
        {
          label : '  Downloads  '
          click : ()->
            $scope.navigate = [ 'File' , 'Downloads']
            changepath '/downloads'
        }
        {
          label : '  DevTools  '
          click : ()->
            __nw.Window.get().showDevTools()
        }
        {
          label : '  Restart  '
          click : ()->
            #Clear the HTTP cache in memory and the one on disk
            __require.nw.App.clearCache()
            jTester.restart()
        }
        {
          label : '  Quit  '
          click : ()->
            __require.nw.App.quit()
        }
        {
          label : '  HTTP  '
          click : ()->
            $scope.navigate = [ 'Run' , 'HTTP']
            changepath '/http'
        }
        {
          label : '  JSON  '
          click : ()->
            $scope.navigate = [ 'Run' , 'JSON']
            changepath '/json'
        }
        {
          label : '  SOCKET  '
          click : ()->
            $scope.navigate = [ 'Run' , 'SOCKET']
            changepath '/socket'
        }
        {
          label : '  XMPP  '
          click : ()->
            $scope.navigate = [ 'Run' , 'XMPP']
            changepath '/xmpp'
        }
        {
          label : '  Topics  '
          click : ()->
            $scope.navigate = [ 'Help' , 'Topics']
            changepath '/help'
        }
        {
          label : '  About  '
          click : ()->
            $modal.open {
              templateUrl: __views.about
              backdrop : 'center'
              controller : ($scope)->
                $scope.link = (url)->
                  if url
                    __nw.Shell.openExternal(url)

                $scope.versions = [
                  { title : "Chromium", value : process.versions['chromium'] , url : ''}
                  { title : "Node-Webkit", value : process.versions['node-webkit'] , url : 'https://github.com/rogerwang/node-webkit'}
                  { title : "Node", value : process.versions['node'] , url : 'http://nodejs.org/'}
                  { title : "ArgularJS", value : "v1.2.26" , url : 'http://angularjs.org/'}
                  { title : "Angular-ui-Bootstrap", value : "v0.11.2" , url : 'http://angular-ui.github.io/bootstrap/'}
                  { title : "bootstrap css", value : "v3.2.0" , url : 'http://getbootstrap.com/'}
                  { title : "cryptojs", value : "v3.1.2" , url : 'https://github.com/evanvosberg/crypto-js'}
                  { title : "coffee-script", value : "v1.8.0" , url : 'http://coffeescript.org/'}
                  { title : "node-uuid", value : "v1.4.1" , url : ''}
                  { title : "request", value : "v2.33.0" , url : ''}
                  { title : "simple-xmpp", value : "v0.1.92" , url : ''}
                  { title : "dateformat", value : "v1.0.8" , url : ''}
                ]
            }
        }
      ]

      #menubar config
      menubar = new __nw.Menu { type: 'menubar' }

      #file
      filemenu = new __nw.MenuItem { label : '  File  ' }
      subfilemenu = new __nw.Menu()
      for m in menus[0..3]
        subfilemenu.append new __nw.MenuItem { label : m.label , click : m.click }
      filemenu.submenu = subfilemenu

      #test
      testmenu = new __nw.MenuItem { label : '  Run  ' }
      subtestmenu = new __nw.Menu()
      for m in menus[4..7]
        subtestmenu.append new __nw.MenuItem { label : m.label , click : m.click }
      testmenu.submenu = subtestmenu

      #help
      helpmenu = new __nw.MenuItem { label : '  Help  ' }
      subhelpmenu = new __nw.Menu()
      for m in menus[8..9]
        subhelpmenu.append new __nw.MenuItem { label : m.label , click : m.click }
      helpmenu.submenu = subhelpmenu

      menubar.append filemenu
      menubar.append testmenu
      menubar.append helpmenu
      __nw.Window.get().menu = menubar


#################### class IndexCtrl ####################################

appjTester.controller 'IndexCtrl' ,
  class IndexCtrl
    constructor : ($scope , $http , $modal ,$sce , $timeout , $window) ->

      $scope.loading = true
      $timeout ()->
        $scope.loading = false
      , 1500

      $scope.menus = [
        {
          title :  "基础配置"
          click : ()->
            openOptions()
        }
        {
          title :  "全局项配置"
          click : ()->
            openItems()
        }
        {
          title :  "下载内容"
          click : ()->
            openDownloads()
        }
        {
          title :  "刷新"
          click : ()->
            $window.location.reload()
        }
      ]

      jTester.alert =
        show : (type , message , timeout)->
          timeout = timeout || 3000
          $modal.open {
            templateUrl : jTester.global.templateUrls.alert
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

      jTester.file.openFile = ($context)->
        $modal.open {
          templateUrl: jTester.global.templateUrls.file
          backdrop : 'static'
          resolve :{
            context : ()->
              return $context
          }
          controller : 'OpenFileCtrl'
        }

      jTester.file.saveFile = ($context)->
        $modal.open {
          templateUrl: jTester.global.templateUrls.savefile
          backdrop : 'static'
          resolve :{
            context : ()->
              return $context
          }
          controller: 'SaveFileCtrl'
        }

      $scope.showDevTools = ()->
        jTester.global.showDevTools()

      #read controller.js data
      testjs = jTester.global.readFileSync jTester.config.defaultTestJs
      if testjs
        eval testjs

      $scope.tabs = []
      resolve = (obj) ->
        obj ?= {}
        for ck , cv of obj
          tab =
            controller : ck
            actions : []
          for ak , av of cv
            tab.actions.push {
              action : ak
              script : av.toString()
              rows : av.toString().match(///\n///g).length + 2
              exec : ()->
                that = this
                $context =
                  $http : $http
                  $sce : $sce
                  action : that
                if that.script.length > 10
                  eval "(#{that.script})($context);"
            }
          $scope.tabs.push tab

      $scope.openAbout = ()->
        $modal.open {
          templateUrl: jTester.global.templateUrls.about
          backdrop : 'center'
          controller : ($scope)->
            $scope.versions = [
              { title : "jTester", value : "v0.1.1" }
              { title : "Chromium", value : process.versions['chromium'] }
              { title : "Node-Webkit", value : process.versions['node-webkit'] }
              { title : "Node", value : process.versions['node'] }
              { title : "ArgularJS", value : "v1.2.19" }
              { title : "Angular-UI-Bootstrap", value : "v0.11.2" }
              { title : "CryptoJS", value : "v3.1.2" }
              { title : "Bootstrap CSS", value : "v3.2.0" }
            ]
        }

      $scope.openHelp = ()->
        $modal.open {
          templateUrl: jTester.global.templateUrls.help
          backdrop : 'center'
          controller: ($scope)->

        }

      openOptions = ()->
        $modal.open {
          templateUrl: jTester.global.templateUrls.config
          backdrop : 'static'
          resolve : [
            $window : ()->
              return $window
          ]
          controller: 'ConfigCtrl'
        }

      openItems = ()->
        $modal.open {
          templateUrl: jTester.global.templateUrls.globalitem
          backdrop : 'static'
          controller: 'GlobalItemCtrl'
        }

      openDownloads = ()->
        $modalInstance = $modal.open {
          templateUrl: jTester.global.templateUrls.downloadlist
          backdrop : 'center'
          controller: 'DownlistCtrl'
        }

        $modalInstance.result.then (result)->
          if result == 'success'
            jTester.alert.success '保存成功'

      #run when page loaded
      if !jTester.config.host
        openOptions()

      #resolve test method
      resolve window.Controllers

########################## class ConfigCtrl ##############################

appjTester.controller 'ConfigCtrl' ,
  class ConfigCtrl
    constructor : ($scope , $modalInstance , $window) ->
      jTester = window.jTester
      headers = jTester.config.headers
      $scope.headers = []
      $scope.config = {
        defaultTestJs : jTester.config.defaultTestJs
        host : jTester.config.host
        defaultPath : jTester.config.defaultPath
      }

      objToArray = ()->
        $scope.headers = []
        for k , v of headers
          $scope.headers.push ({
            key : k
            value : v
          })

      objToArray()

      $scope.set = ()->
        headers[$scope.config.key]= $scope.config.value
        objToArray()
        $scope.config.key = ""
        $scope.config.value = ""

      $scope.reset = (index)->
        header = $scope.headers[index]
        $scope.config.key = header.key
        $scope.config.value = header.value

      $scope.remove = (index)->
        header = $scope.headers[index]
        delete headers[header.key]
        $scope.headers.splice index , 1

      $scope.save = ()->
        #remove last / .replace /(\/*$)/g,""
        jTester.config.host = $scope.config.host
        jTester.config.defaultPath = $scope.config.downdir || jTester.config.defaultPath
        jTester.global.saveConfig()
        $modalInstance.close 'success'

      $scope.cancel = ()->
        if !jTester.config.host
          alert '请先设置服务器地址'
        else
          $modalInstance.close 'dismiss'

      $scope.change = (file)->
        ext = jTester.global.extname file
        if ext == ".js"
          js = jTester.global.readFileSync file
          #清空上一次测试集合
          window.Controllers = undefined
          eval js
          #验证文件是否包含测试代码
          if window.Controllers
            jTester.config.defaultTestJs = file
            jTester.global.saveConfig()
            $window.location.reload()
          else
            jTester.alert.error '该脚本文件不包含 window.Controllers 对象'
        else
          jTester.alert.error '不是 javascript 文件'

########################## class GlobalItemCtrl ##############################

appjTester.controller 'GlobalItemCtrl' ,
  class GlobalItemCtrl
    constructor : ($scope , $modalInstance) ->
      jTester = window.jTester
      items = jTester.config.globalitems || {}
      $scope.items = []
      $scope.item = {}

      objToArray = ()->
        $scope.items = []
        for k , v of items
          $scope.items.push ({
            key : k
            value : v
          })

      objToArray()

      $scope.set = ()->
        items[$scope.item.key]= $scope.item.value
        objToArray()
        $scope.item.key = ""
        $scope.item.value = ""

      $scope.reset = (index)->
        item = $scope.items[index]
        $scope.item.key = item.key
        $scope.item.value = item.value

      $scope.remove = (index)->
        item = $scope.items[index]
        delete items[item.key]
        $scope.items.splice index , 1

      $scope.save = ()->
        jTester.config.globalitems = items
        jTester.global.saveConfig()
        $modalInstance.close 'success'

      $scope.cancel = ()->
        $modalInstance.close 'dismiss'

########################## class OpenFileCtrl ##############################

appjTester.controller 'OpenFileCtrl' ,
  class OpenFileCtrl
    constructor : ($scope , $modalInstance , context)->
      context.$modalInstance = $modalInstance
      $scope.files = []
      $scope.change = (file)->
        $scope.files.push file

      $scope.remove = (index)->
        $scope.files.splice index , 1

      $scope.upload = ()->
        context.params.files = $scope.files
        new jTester.http(context).upload()

      $scope.cancel = ()->
        $modalInstance.close 'dismiss'

########################## class SaveFileCtrl ##############################

appjTester.controller 'SaveFileCtrl' ,
  class SaveFileCtrl
    constructor : ($scope , $modalInstance , context)->
      context.$modalInstance = $modalInstance
      $scope.params =
        filename  : context.params.action
        defaultPath : jTester.config.defaultPath
        downlink : jTester.global.URL.resolve jTester.config.host , "/#{context.params.controller}/#{context.params.action}"

      $scope.save = ()->
        context.params.downdir = $scope.params.downdir || jTester.config.defaultPath
        new jTester.http(context).down()

      $scope.cancel = ()->
        $modalInstance.close 'dismiss'

########################## class DownlistCtrl ##############################

appjTester.controller 'DownlistCtrl' ,
  class DownlistCtrl
    constructor : ($scope , $modalInstance)->
      $scope.items = jTester.downlist

      $scope.showItemInFolder = (path)->
        if jTester.global.fileExistsSync path
          jTester.global.showItemInFolder path
        else
          alert '文件已删除'

      $scope.remove = (index)->
        $scope.items.splice index , 1
        jTester.global.saveDownlist()

      $scope.delete = (index)->
        file = $scope.items.splice index , 1
        jTester.global.saveDownlist()
        jTester.global.rmfile file[0].path

      $scope.clear = ()->
        jTester.downlist = []
        $scope.items = []
        jTester.global.saveDownlist()

      $scope.cancel = ()->
        $modalInstance.close 'dismiss'
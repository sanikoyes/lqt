--------------------------------------------------------------------------------
-- get source path of 'init.lua'
--------------------------------------------------------------------------------
local function get_source_path()
	local info = debug.getinfo(1)
	return info.source:sub(2)
end
--------------------------------------------------------------------------------
-- setup cpath/luapath
--------------------------------------------------------------------------------
local dlpath = get_source_path():gsub('init.lua', '../build/lib/?.so')
package.cpath = package.cpath .. ';' .. dlpath

local luapath = table.concat({
	arg[0]:gsub('[/\\][^/^\\]*%.lua$', '/?.lua'),
	get_source_path():gsub('init.lua', '?.lua'),
}, ';')

package.path = package.path .. ';' .. luapath
--------------------------------------------------------------------------------
-- use strict to avoid undeclared global variables access
--------------------------------------------------------------------------------
require 'strict'

local QtCore = require 'qtcore'
--------------------------------------------------------------------------------
-- Qt useful routines
--------------------------------------------------------------------------------
rawset(_G, 'SIGNAL', function(s) return '2' .. s end)
rawset(_G, 'SLOT', function (s) return '1' .. s end)
rawset(_G, 'tr', assert(QtCore.QObject.tr))

--------------------------------------------------------------------------------
-- for debug purpuse
--------------------------------------------------------------------------------
rawset(_G, 'gc', function()
	print('gc start')
	collectgarbage()
	print('gc end')
end)
--------------------------------------------------------------------------------
-- qml examples main func
--------------------------------------------------------------------------------
rawset(_G, 'qml_main', function(name, ...)
	local QtGui = require 'qtgui'
	local QtQml = require 'qtqml'
	local QtQuick = require 'qtquick'

	QtCore.QCoreApplication.setAttribute(QtCore.AA_EnableHighDpiScaling)

	local app = QtGui.QGuiApplication(1 + select('#', unpack(arg)), { arg[0], unpack(arg) })
    app.setOrganizationName('QtProject')
	app.setOrganizationDomain('qt-project.org')
    app.setApplicationName(QtCore.QFileInfo(app.applicationFilePath()):baseName())

    local view = QtQuick.QQuickView()
    if os.getenv('QT_QUICK_CORE_PROFILE') == '1' then
    	local f = view:format()
    	f:setProfile(QtGui.QSurfaceFormat.CoreProfile)
    	f:setVersion(4, 4)
    	view:setFormat(f)
    end
    if os.getenv('QT_QUICK_MULTISAMPLE') == '1' then
    	local f = view:format()
    	f:setSamples(4)
    	view:setFormat(f)
    end
	view.connect(view:engine(), SIGNAL 'quit()', app, SLOT 'quit()')
	local selector = QtQml.QQmlFileSelector.new(view:engine(), view)
	view:setSource(QtCore.QUrl(name))
	if view:status() == QtQuick.QQuickView.Error then
		return -1
	end
	view:setResizeMode(QtQuick.QQuickView.SizeRootObjectToView)
	view:show()
	return app.exec()
end)
--------------------------------------------------------------------------------
-- qt test main func
--------------------------------------------------------------------------------
rawset(_G, 'test_main', function(type, Class)
	local QtTest = require 'qttest'

	QtTest.QCOMPARE = function(actual, expected)
		local info = debug.getinfo(2)
		QtTest.qCompare(actual, expected, 'actual', 'excepted', info.short_src, info.currentline)
	end

	local Application
	if type == 'console' then
		Application = QtCore.QCoreApplication
	elseif type == 'gui' then
		local QtGui = require 'qtgui'
		Application = QtGui.QGuiApplication
	elseif type == 'widgets' then
		local QtWidgets = require 'qtwidgets'
		Application = QtWidgets.QApplication
	else
		error('invalid type ' .. tostring(type))
	end

	local app = Application.new(1, { 'qt test' })
	app.setAttribute(QtCore.AA_Use96Dpi, true)

	QtTest.setMainSourcePath(debug.getinfo(2).short_src)

	return QtTest.qExec(Class(), 1, { 'qt test' })
end)


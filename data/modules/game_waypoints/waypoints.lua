local WAYPOINTS_OPCODE = 100
local DEFAULT_IMAGE = '/images/waypoints/default'

local waypointsWindow = nil
local waypointsButton = nil
local waypointList = nil
local waypointsTabBar = nil
local descriptionLabel = nil
local allWaypoints = {}

local function clearTabs()
  -- reset currentTab before destroying to avoid selectTab trying to uncheck a dead widget
  waypointsTabBar.currentTab = nil
  local tabs = waypointsTabBar.tabs
  waypointsTabBar.tabs = {}
  for _, t in ipairs(tabs) do
    t:destroy() -- tab.onDestroy also destroys t.tabPanel
  end
end

function init()
  waypointsWindow = g_ui.displayUI('waypoints')
  waypointsWindow:hide()

  waypointList = waypointsWindow:getChildById('waypointList')
  waypointsTabBar = waypointsWindow:getChildById('waypointsTabBar')
  descriptionLabel = waypointsWindow:getChildById('descriptionPanel'):getChildById('descriptionLabel')

  waypointsTabBar.onTabChange = function(tabBar, tab)
    populateList(tab:getText())
  end

  waypointList.onChildFocusChange = function(list, child)
    if child and child.waypointData then
      descriptionLabel:setText(child.waypointData.description or '')
    end
  end

  waypointsButton = modules.client_topmenu.addRightGameToggleButton(
    'waypointsButton',
    tr('Waypoints'),
    '/images/topbuttons/bot',
    toggle,
    false,
    99998
  )

  ProtocolGame.registerExtendedOpcode(WAYPOINTS_OPCODE, onWaypointData)
  connect(g_game, { onGameEnd = onGameEnd, onGameStart = requestWaypoints })
  if g_game.isOnline() then
    requestWaypoints()
  end
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(WAYPOINTS_OPCODE)
  disconnect(g_game, { onGameEnd = onGameEnd, onGameStart = requestWaypoints })
  if waypointsButton then
    waypointsButton:destroy()
    waypointsButton = nil
  end
  if waypointsWindow then
    waypointsWindow:destroy()
    waypointsWindow = nil
  end
  waypointList = nil
  waypointsTabBar = nil
  descriptionLabel = nil
  allWaypoints = {}
end

function requestWaypoints()
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(WAYPOINTS_OPCODE, '{"action":"request"}')
  end
end

function toggle()
  if waypointsWindow:isVisible() then
    hide()
  else
    show()
  end
end

function show()
  waypointsWindow:show()
  waypointsWindow:raise()
  waypointsWindow:focus()
  waypointsButton:setOn(true)
end

function hide()
  waypointsWindow:hide()
  if waypointsButton then
    waypointsButton:setOn(false)
  end
end

function onGameEnd()
  hide()
  allWaypoints = {}
  clearTabs()
  waypointList:destroyChildren()
  descriptionLabel:setText('')
end

-- Receives opcode 100 from server with unlocked waypoints list.
function onWaypointData(protocol, opcode, buffer)
  if not waypointList then return end
  local jsonStr = buffer:sub(2)
  local ok, data = pcall(function() return json.decode(jsonStr) end)
  if not ok or type(data) ~= 'table' then return end

  allWaypoints = data

  -- always rebuild tabs from scratch to avoid duplicates on reconnect
  clearTabs()

  local categories = {}
  local seen = {}
  for _, wp in ipairs(data) do
    local cat = wp.category or 'General'
    if not seen[cat] then
      seen[cat] = true
      categories[#categories + 1] = cat
    end
  end

  for _, cat in ipairs(categories) do
    waypointsTabBar:addTab(cat)
  end
  -- first addTab auto-selects → onTabChange → populateList
end

function populateList(category)
  if not waypointList then return end
  waypointList:destroyChildren()
  if descriptionLabel then
    descriptionLabel:setText('')
  end

  for _, wp in ipairs(allWaypoints) do
    local cat = wp.category or 'General'
    if cat ~= category then goto continue end

    local item = g_ui.createWidget('WaypointItem', waypointList)
    item:setId('waypoint_' .. wp.id)
    item.waypointData = wp

    item:getChildById('name'):setText(wp.name)

    local imageWidget = item:getChildById('itemImage')
    local imagePath = (wp.image and wp.image ~= '') and ('/images/waypoints/' .. wp.image) or DEFAULT_IMAGE
    if g_resources.fileExists(imagePath .. '.png') then
      imageWidget:setImageSource(imagePath)
    else
      imageWidget:setImageSource(DEFAULT_IMAGE)
    end

    local wpId = wp.id
    item.onDoubleClick = function()
      teleportTo(wpId)
      return true
    end

    ::continue::
  end
end

function onTeleport()
  if not waypointList then return end
  local selected = waypointList:getFocusedChild()
  if not selected or not selected.waypointData then return end
  teleportTo(selected.waypointData.id)
end

function teleportTo(waypointId)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(
      WAYPOINTS_OPCODE,
      '{"action":"teleport","waypoint_id":' .. waypointId .. '}'
    )
  end
  hide()
end

--MoveUI - Dirtyredz|David McClain
package.path = package.path .. ";mods/MoveUI/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"

local MoveUI = require('MoveUI')
require ("utility")

-- namespace ScrapyardLicenses
ScrapyardLicenses = {}

local AllianceValues = {}
local PlayerValues = {}
local OverridePosition
local Title = 'ScrapyardLicenses'
local Icon = "data/textures/icons/papers.png"
local Description = "Shows all current Scrapyard Licenses, Displays Alliance Licenses if inside an Alliance Ship."
local DefaultOptions = {
  Both = false
}
local Both_OnOff

function ScrapyardLicenses.initialize()
  if onClient() then
    --Obviously
    Player():registerCallback("onPreRenderHud", "onPreRenderHud")
  else
    --Lets do some checks on startup/sector entered
    Player():registerCallback("onSectorEntered", "onSectorEntered")

    local x,y = Sector():getCoordinates()
    ScrapyardLicenses.onSectorEntered(Player().index,x,y)
  end
end

function ScrapyardLicenses.buildTab(tabbedWindow)
  local FileTab = tabbedWindow:createTab("", Icon, Title)
  local container = FileTab:createContainer(Rect(vec2(0, 0), FileTab.size));

  --split it 50/50
  local mainSplit = UIHorizontalSplitter(Rect(vec2(0, 0), FileTab.size), 0, 0, 0.5)

  --Top Message
  local TopHSplit = UIHorizontalSplitter(mainSplit.top, 0, 0, 0.3)
  local TopMessage = container:createLabel(TopHSplit.top.lower + vec2(10,10), Title, 16)
  TopMessage.centered = 1
  TopMessage.size = vec2(FileTab.size.x - 40, 20)

  local Description = container:createTextField(TopHSplit.bottom, Description)

  local OptionsSplit = UIHorizontalMultiSplitter(mainSplit.bottom, 0, 0, 1)

  local TextVSplit = UIVerticalSplitter(OptionsSplit:partition(0),0, 5,0.65)
  local name = container:createLabel(TextVSplit.left.lower, "Show Both", 16)

  --make sure variables are local to this file only
  Both_OnOff = container:createCheckBox(TextVSplit.right, "On / Off", 'onShowBoth')

  --Pass the name of the function, and the checkbox
  return {onShowBoth = Both_OnOff}
end

function ScrapyardLicenses.onShowBoth(checkbox, value)
  --setNewOptions is a function inside entity/MoveUI.lua, that sets the options to the player.
  invokeServerFunction('setNewOptions', Title, {Both = value})
end

--Executed when the Main UI Interface is opened.
function ScrapyardLicenses.onShowWindow()
  --Get the player options
  local LoadedOptions = MoveUI.GetOptions(Player(),Title,DefaultOptions)
  --Set the checkbox to match the option
  Both_OnOff.checked = LoadedOptions.Both
end

function ScrapyardLicenses.TableSize(tabl)
  local i = 0
  for x,cols in pairs(tabl) do
      for y,data in pairs(cols) do
          i = i + 1
      end
  end
  return i
end

function ScrapyardLicenses.onPreRenderHud()
    if onClient() then
        local rect = Rect(vec2(), vec2(400, 100))
        local res = getResolution();

        local DefaulPosition = vec2(res.x * 0.88, res.y * 0.21)
        rect.position = MoveUI.CheckOverride(Player(), DefaulPosition, OverridePosition, Title)

        OverridePosition, Moving = MoveUI.Enabled(Player(), rect, OverridePosition)
        if OverridePosition and not Moving then
            invokeServerFunction('setNewPosition', OverridePosition)
        end

        if MoveUI.AllowedMoving(Player()) then
          drawTextRect(Title, rect, 0, 0,ColorRGB(1,1,1), 10, 0, 0, 0)
          return
        end

        --get the licenses
        local player = Player()
        if not player then return end
        local playerShip = Sector():getEntity(player.craftIndex)
        if not playerShip then return end
        local playerAlliance = player.allianceIndex

        local InAllianceShip = false
        if playerShip then
          if player.index ~= playerShip.factionIndex then
            InAllianceShip = true
          end
        end

        ScrapyardLicenses.GetFactionValues(player.allianceIndex,player.index)
        ScrapyardLicenses.sync()

        local AllinaceLicensesSize = 0
        if playerAlliance then
          AllinaceLicensesSize = ScrapyardLicenses.TableSize(AllianceValues)
        end
        local PlayerLicensesSize = ScrapyardLicenses.TableSize(PlayerValues)


        local LoadedOptions = MoveUI.GetOptions(Player(),Title,DefaultOptions)
        local showBoth = LoadedOptions.Both

        local NumLicenses = 0
        if showBoth then --if shoiwng both factions
          NumLicenses = (PlayerLicensesSize + AllinaceLicensesSize) - 1
        elseif InAllianceShip then --only showing alliance licenses
          NumLicenses = AllinaceLicensesSize - 1
        else --show player
          NumLicenses = PlayerLicensesSize - 1
        end

        local HSplit = UIHorizontalMultiSplitter(rect, 10, 8, math.max(NumLicenses,0))

        if NumLicenses >= 0 then
          --Reset index
          local i = 0
          local ShipFactionLicenses
          local prepend = ''
          --show Alliance if in an alliance ship, otherwise show player
          if InAllianceShip then
            if showBoth then prepend = '[A] ' end
            ShipFactionLicenses = AllianceValues
          else
            if showBoth then prepend = '[P] ' end
            ShipFactionLicenses = PlayerValues
          end

          for x,cols in pairs(ShipFactionLicenses) do
              for y,duration in pairs(cols) do
                  local color = MoveUI.TimeRemainingColor(duration)
                  drawTextRect(prepend..x..' : '..y, HSplit:partition(i), -1, 0, color, 15, 0, 0, 0)
                  drawTextRect(createReadableTimeString(duration), HSplit:partition(i), 1, 0, color, 15, 0, 0, 0)

                  MoveUI.AllowClick(Player(),HSplit:partition(i),(function () GalaxyMap():show(x, y); print('Showing Galaxy:',x,y) end))
                  i = i + 1
              end
          end

          ShipFactionLicenses = nil
          if showBoth then
            --if were in an alliance ship then show player
            --otherwise if the player has an alliance show alliance
            if InAllianceShip then
              prepend = '[P] '
              ShipFactionLicenses = PlayerValues
            elseif not InAllianceShip and playerAlliance then
              prepend = '[A] '
              ShipFactionLicenses = AllianceValues
            end
            for x,cols in pairs(ShipFactionLicenses) do
                for y,duration in pairs(cols) do
                    local color = MoveUI.TimeRemainingColor(duration)
                    drawTextRect(prepend..x..' : '..y, HSplit:partition(i), -1, 0, color, 15, 0, 0, 0)
                    drawTextRect(createReadableTimeString(duration), HSplit:partition(i), 1, 0, color, 15, 0, 0, 0)

                    MoveUI.AllowClick(Player(),HSplit:partition(i),(function () GalaxyMap():show(x, y); print('Showing Galaxy:',x,y) end))
                    i = i + 1
                end
            end
          end

        end
    end
end

function ScrapyardLicenses.setNewPosition(Position)
    MoveUI.AssignPlayerOverride(Player(), Title, Position)
end

function ScrapyardLicenses.GetFactionValues(allianceIndex,playerIndex)
  if onClient() then
    invokeServerFunction('GetFactionValues',allianceIndex,playerIndex)
    return
  end

  if allianceIndex then
    local alliance = Faction(allianceIndex)
    if alliance then
      local TmpAllianceValues = alliance:getValues()
      if TmpAllianceValues['MoveUI#Licenses'] then
        AllianceValues = TmpAllianceValues['MoveUI#Licenses'] or 'return { }'
        AllianceValues = loadstring(AllianceValues)()
      end
    end
  end

  local player = Faction(playerIndex)
  if player then
    local TmpPlayerValues = player:getValues()
    if TmpPlayerValues['MoveUI#Licenses'] then
      PlayerValues = TmpPlayerValues['MoveUI#Licenses'] or 'return { }'
      PlayerValues = loadstring(PlayerValues)()
    end
  end
end

function ScrapyardLicenses.SetFactionValues(allianceIndex,allianceLicenses,playerLicenses)
  if onClient() then
    invokeServerFunction('GetFactionValues',allianceIndex,allianceLicenses,playerLicenses)
    return
  end
  if allianceIndex then
    local faction = Faction(allianceIndex)
    faction:setValue("MoveUI#Licenses", MoveUI.Serialize(allianceLicenses))
  end
  Player():setValue("MoveUI#Licenses", MoveUI.Serialize(playerLicenses))
end

function ScrapyardLicenses.sync(values)
  if onClient() then
    if values then
      AllianceValues = values.AllianceValues
      PlayerValues = values.PlayerValues
      return
    end
    invokeServerFunction('sync')
    return
  end
  invokeClientFunction(Player(callingPlayer),'sync',{AllianceValues = AllianceValues, PlayerValues = PlayerValues})
end

function ScrapyardLicenses.onSectorEntered(playerIndex,x,y)
  local player = Player()
  local playerShip = Entity(player.craftIndex)

  local ShipFaction
  if playerShip then
    ShipFaction = playerShip.factionIndex
  else
    ShipFaction = player.index
  end

  ScrapyardLicenses.GetFactionValues(player.allianceIndex, player.index)
  ScrapyardLicenses.sync()

  local x,y = Sector():getCoordinates()

  if (type(AllianceValues[x]) == "table") then
    local count = 0
    for _ in pairs( AllianceValues[x] ) do
      count = count + 1
    end
    if count == 0 then
      --Remove X table since its empty
      AllianceValues[x] = nil
    elseif (type(AllianceValues[x][y]) == "number") then
      --Delete this sectors licenses since any active scrapyards will update
      AllianceValues[x][y] = nil
      print('Removing:',x,y,'from licenses')
    end
  end

  if (type(PlayerValues[x]) == "table") then
    local count = 0
    for _ in pairs( PlayerValues[x] ) do
      count = count + 1
    end
    if count == 0 then
      --Remove X table since its empty
      PlayerValues[x] = nil
    elseif (type(PlayerValues[x][y]) == "number") then
      --Delete this sectors licenses since any active scrapyards will update
      PlayerValues[x][y] = nil
      print('Removing:',x,y,'from licenses')
    end
  end
  ScrapyardLicenses.SetFactionValues(player.allianceIndex, AllianceValues, PlayerValues)
end

return ScrapyardLicenses

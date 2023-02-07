Scrapyard.updateServerOld = Scrapyard.updateServer

include('data/scripts/lib/serialize')

local ScrapyardPlus

-- TODO: replace with the Workshop ID of MoveUI once you upload it
if ModManager():find("ScrapyardPlus") then
	ScrapyardPlus = true
    include ("serialize")
end

-- compatibility with ScrapyardPlus 2023
if ScrapyardPlus then
    -- this function runs INSTEAD OF Scrapyard.updateServer() defined below, because that function is already being shadowed by ScrapyardPlus
    function Scrapyard.updateMoveUILicenses(timeStep, scrapyardFactionIndex)
        local Data, licenses

        if Scrapyard.getData then
            --print("\ngetting Scrapyard data for faction " .. scrapyardFactionIndex .. "...")
            Data = Scrapyard.getData(scrapyardFactionIndex)
            licenses = {}
            for d in ipairs(Data) do
                --print("index: ".. d)
                --print("data: " .. serialize(Data[d]))
                --print("facId: " .. Data[d].factionIndex)
                --print("license: " .. Data[d].license)
                licenses[Data[d].factionIndex] = Data[d].license
            end

            local x,y = Sector():getCoordinates()
            for factionIndex,duration in pairs(licenses) do
                local faction = Faction(factionIndex)

                if faction.isPlayer or faction.isAlliance then
                    -- read current or init new
                    local pLicenses = Scrapyard.GetFactionLicense(factionIndex)
                    local time = round(duration - timeStep)
                    if time <= 0 then
                    time = nil
                    end
                    pLicenses[x][y] = time

                    faction:setValue("MoveUI#Licenses", serialize(pLicenses))
                end
            end
        end
    end
end

function Scrapyard.updateServer(timeStep)
    local Data, licenses

    Data = Scrapyard.secure()
    licenses = Data["licenses"]

    local x,y = Sector():getCoordinates()
    for factionIndex,duration in pairs(licenses) do
        local faction = Faction(factionIndex)

        if faction.isPlayer or faction.isAlliance then
            -- read current or init new
            local pLicenses = Scrapyard.GetFactionLicense(factionIndex)
            local time = round(duration - timeStep)
            if time <= 0 then
              time = nil
            end
            pLicenses[x][y] = time

            faction:setValue("MoveUI#Licenses", serialize(pLicenses))
        end
    end

    Scrapyard.updateServerOld(timeStep)
end

function Scrapyard.GetFactionLicense(factionIndex)

    local x,y = Sector():getCoordinates()
    local faction = Faction(factionIndex)

    local licenses
    local PlayerLicenses = faction:getValue("MoveUI#Licenses") or false
    if faction and (faction.isPlayer or faction.isAlliance) and PlayerLicenses then
        licenses = loadstring(PlayerLicenses)()
    else
        licenses = {}
    end

    -- Sanity checks / init new
    if (type(licenses) ~= "table") then
        licenses = {}
    end
    if (type(licenses[x]) ~= "table") then
        licenses[x] = {}
    end
    if (type(licenses[x][y]) ~= "table") then
        licenses[x][y] = {}
    end

    return licenses
end

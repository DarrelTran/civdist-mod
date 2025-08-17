function escapeString(str)
    if type(str) ~= "string" then
        return ""
    end

    str = string.gsub(str, "\\", "\\\\")  -- escape backslashes
    str = string.gsub(str, "\"", "\\\"")  -- escape double quotes
    str = string.gsub(str, "\b", "\\b")   -- backspace
    str = string.gsub(str, "\f", "\\f")   -- form feed
    str = string.gsub(str, "\n", "\\n")   -- newline
    str = string.gsub(str, "\r", "\\r")   -- carriage return
    str = string.gsub(str, "\t", "\\t")   -- tab
    return str
end


function JsonEncode(tbl)
    local json = "["
    for i, entry in ipairs(tbl) do

        local rawBuildings = {}
        for _, b in ipairs(entry.Buildings or {}) do
            table.insert(rawBuildings, "\"" .. escapeString(b) .. "\"")
        end
        local buildingsArray = "[" .. table.concat(rawBuildings, ",") .. "]"
        
        local rawFavored = {}
        for _, b in ipairs(entry.FavoredYields or {}) do
            table.insert(rawFavored, "\"" .. escapeString(b) .. "\"")
        end
        local favoredArray = "[" .. table.concat(rawFavored, ",") .. "]"

        local rawDisfavored = {}
        for _, b in ipairs(entry.DisfavoredYields or {}) do
            table.insert(rawDisfavored, "\"" .. escapeString(b) .. "\"")
        end
        local disfavoredArray = "[" .. table.concat(rawDisfavored, ",") .. "]"

        local e = string.format(
        "{\"X\":%d, \"Y\":%d, \"TerrainType\":\"%s\", \"FeatureType\":\"%s\", \"ResourceType\":\"%s\", \"ImprovementType\":\"%s\", \"IsHills\":%s, \"IsMountain\":%s, \"IsWater\":%s, \"IsLake\":%s, \"IsFlatlands\":%s, \"IsCity\":%s, \"IsCapital\":%s, \"OriginalOwner\":\"%s\", \"Population\":%d, \"IsWorked\":%s, \"TileCity\":\"%s\", \"CityPantheon\":\"%s\", \"FoundedReligion\":\"%s\", \"IsRiver\":%s, \"IsNEOfRiver\":%s, \"IsWOfRiver\":%s, \"IsNWOfRiver\":%s, \"RiverSWFlow\":\"%s\", \"RiverEFlow\":\"%s\", \"RiverSEFlow\":\"%s\", \"Appeal\":%d, \"Continent\":\"%s\", \"Civilization\":\"%s\", \"Leader\":\"%s\", \"CityName\":\"%s\", \"District\":\"%s\", \"Wonder\":\"%s\", \"Buildings\":%s, \"Food\":%d, \"Production\":%d, \"Gold\":%d, \"Science\":%d, \"Culture\":%d, \"Faith\":%d, \"FavoredYields\":%s, \"DisfavoredYields\":%s}",
        tonumber(entry.X),
        tonumber(entry.Y),
        tostring(entry.TerrainType),
        tostring(entry.FeatureType),
        tostring(entry.ResourceType),
        tostring(entry.ImprovementType),
        tostring(entry.IsHills),
        tostring(entry.IsMountain),
        tostring(entry.IsWater),
        tostring(entry.IsLake),
        tostring(entry.IsFlatlands),
        tostring(entry.IsCity),
        tostring(entry.IsCapital),
        tostring(entry.OriginalOwner),
        tostring(entry.Population),
        tostring(entry.IsWorked),
        tostring(entry.TileCity),
        tostring(entry.CityPantheon),
        tostring(entry.CityOwnerFoundedReligion),
        tostring(entry.IsRiver),
        tostring(entry.IsNEOfRiver), tostring(entry.IsWOfRiver), tostring(entry.IsNWOfRiver),
        tostring(entry.RiverSWFlow or "NONE"), tostring(entry.RiverEFlow or "NONE"), tostring(entry.RiverSEFlow or "NONE"),
        tonumber(entry.Appeal or 0),
        tostring(entry.ContinentType),
        tostring(entry.OwnerCiv),
        tostring(entry.OwnerLeader),
        tostring(entry.CityName),
        tostring(entry.DistrictType),
        tostring(entry.Wonder),
        buildingsArray,
        tonumber(entry.Food), tonumber(entry.Production), tonumber(entry.Gold),
        tonumber(entry.Science), tonumber(entry.Culture), tonumber(entry.Faith),
        favoredArray,
        disfavoredArray
    )

        json = json .. e
        if i < #tbl then json = json .. "," end
    end
    json = json .. "]END_JSON"
    return json 
end

function SafeLookup(str)
    if str ~= nil and type(str) == "string" then
        return Locale.Lookup(str)
    end
    return "NONE"
end

DirectionTypes = {
    "DIRECTION_NORTHEAST", -- 0
    "DIRECTION_EAST", -- 1
    "DIRECTION_SOUTHEAST", -- 2
    "DIRECTION_SOUTHWEST", -- 3
    "DIRECTION_WEST", -- 4
    "DIRECTION_NORTHWEST" -- 5
};

local cityCitizenMap = {}

function ExportMapToJSONChunked()
    print("MAP_DATA_START")

    local chunkSize = 1
    local chunk = {}
    local count = 0

    for i = 0, Map.GetPlotCount() - 1 do
        local plot = Map.GetPlotByIndex(i)

        if plot:IsCity() then
            local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
            if city then
                cityName = SafeLookup(city:GetName())

                local citizens = city:GetCitizens();

                cityCitizenMap[cityName] = citizens;
            end
        end
    end

    for i = 0, Map.GetPlotCount() - 1 do
        local plot = Map.GetPlotByIndex(i)

        local ownerID = plot:GetOwner()
        local civ = "NONE"
        local leader = "NONE"
        local cityName = "NONE"
        local districtType = "NONE"
        local buildings = {}
        local tileCityOwner = "NONE"
        local theWonder = "NONE"
        local cityPantheon = "NONE"
        local cityOwnerFoundedReligion = "NONE"
        local isWorked = false
        local citizenFavoredYield = {}
        local citizenDisfavoredYield = {}
        local thePopulation = -1; -- -1 means not the city tile
        local isCapital = false
        local continent = "NONE"
        local originalOwner = "NONE"

        if ownerID ~= -1 then
            local config = PlayerConfigurations[ownerID]
            if config then
                civ = SafeLookup(config:GetCivilizationDescription())
                leader = SafeLookup(config:GetLeaderName())
            end
        end

        if plot:IsCity() then
            local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
            if city then
                cityName = SafeLookup(city:GetName())
                pantheon = (city:GetReligion()):GetActivePantheon()
                if pantheon >= 0 then
                    cityPantheon = SafeLookup(GameInfo.Beliefs[pantheon].Name)
                end
                local cityBuildings = city:GetBuildings()
                for row in GameInfo.Buildings() do
                    if cityBuildings:HasBuilding(row.Index) and not (row.IsWonder) then
                        table.insert(buildings, SafeLookup(row.Name))
                    end
                end

                local playerID = city:GetOwner()
                local religionType = Players[playerID]:GetReligion():GetReligionTypeCreated()

                if religionType ~= -1 then
                    cityOwnerFoundedReligion = Game.GetReligion():GetName(religionType)
                end

                local citizens = city:GetCitizens();
                isWorked = citizens:IsPlotWorked(plot:GetX(), plot:GetY())

                for yield in GameInfo.Yields() do
                    if citizens:IsFavoredYield(yield.Index) then
                        table.insert(citizenFavoredYield, SafeLookup(yield.Name));
                    elseif citizens:IsDisfavoredYield(yield.Index) then
                        table.insert(citizenDisfavoredYield, SafeLookup(yield.Name));
                    end
                end

                thePopulation = city:GetPopulation();
                isCapital = city:IsOriginalCapital();
            end

            if ownerID ~= -1 then
                local config = PlayerConfigurations[city:GetOriginalOwner()]
                if config then
                    originalOwner = SafeLookup(config:GetCivilizationDescription())
                end
            end
        end

        local districtID = plot:GetDistrictType()
        if districtID ~= -1 then
            local districtInfo = GameInfo.Districts[districtID]
            if districtInfo then
                districtType = SafeLookup(districtInfo.Name)
            end
        end

        local cityTile = Cities.GetPlotPurchaseCity(plot)
        if cityTile then
            tileCityOwner = SafeLookup(cityTile:GetName())

            local cityCitizens = cityCitizenMap[tileCityOwner];
            if cityCitizens ~= nil then
                isWorked = cityCitizens:IsPlotWorked(plot:GetX(), plot:GetY())
            end
        end

        local SWFlow = plot:GetRiverSWFlowDirection()
        local EFlow = plot:GetRiverEFlowDirection()
        local SEFlow = plot:GetRiverSEFlowDirection()

        if SWFlow ~= nil and SWFlow ~= -1 then
            SWFlow = DirectionTypes[SWFlow]
        else
            SWFlow = "NONE"
        end

        if EFlow ~= nil and EFlow ~= -1 then
            EFlow = DirectionTypes[EFlow]
        else
            EFlow = "NONE"
        end

        if SEFlow ~= nil and SEFlow ~= -1 then
            SEFlow = DirectionTypes[SEFlow]
        else
            SEFlow = "NONE"
        end

        local wonderType = plot:GetWonderType()
        if wonderType ~= -1 then
            local wonderInfo = GameInfo.Buildings[wonderType]
            theWonder = SafeLookup(wonderInfo.Name)
        end

        local theContinent = plot:GetContinentType()
        if theContinent ~= -1 then
            continent = SafeLookup(GameInfo.Continents[theContinent].Description)
        end

        local plotData = 
        {
            X = plot:GetX(),
            Y = plot:GetY(),
            TerrainType = SafeLookup(GameInfo.Terrains[plot:GetTerrainType()] and GameInfo.Terrains[plot:GetTerrainType()].Name), -- tundra, grassland, ocean, etc
            FeatureType = SafeLookup(GameInfo.Features[plot:GetFeatureType()] and GameInfo.Features[plot:GetFeatureType()].Name),
            ResourceType = SafeLookup(GameInfo.Resources[plot:GetResourceType()] and GameInfo.Resources[plot:GetResourceType()].Name),
            ImprovementType = SafeLookup(GameInfo.Improvements[plot:GetImprovementType()] and GameInfo.Improvements[plot:GetImprovementType()].Name),
            IsHills = plot:IsHills(),
            IsMountain = plot:IsMountain(),
            IsWater = plot:IsWater(),
            IsLake = plot:IsLake(),
            IsFlatlands = plot:IsFlatlands(),
            IsCity = plot:IsCity(),
            Population = thePopulation,
            IsCapital = isCapital,
            OriginalOwner = originalOwner,
            IsWorked = isWorked,
            TileCity = tileCityOwner,
            CityPantheon = cityPantheon,
            CityOwnerFoundedReligion = cityOwnerFoundedReligion,
            IsRiver = plot:IsRiver(),
            IsNEOfRiver = plot:IsNEOfRiver(),
            IsWOfRiver = plot:IsWOfRiver(),
            IsNWOfRiver = plot:IsNWOfRiver(),
            RiverSWFlow = SWFlow,
            RiverEFlow = EFlow,
            RiverSEFlow = SEFlow,
            Appeal = plot:GetAppeal(),
            ContinentType = continent,
            OwnerCiv = civ,
            OwnerLeader = leader,
            CityName = cityName,
            DistrictType = districtType,
            Buildings = buildings,
            Wonder = theWonder,
            Food = plot:GetYield(0),
            Production = plot:GetYield(1),
            Gold = plot:GetYield(2),
            Science = plot:GetYield(3),
            Culture = plot:GetYield(4),
            Faith = plot:GetYield(5),
            FavoredYields = citizenFavoredYield,
            DisfavoredYields = citizenDisfavoredYield
        }

        table.insert(chunk, plotData)
        count = count + 1

        if count >= chunkSize then
            print("MAP_DATA_CHUNK:" .. JsonEncode(chunk))
            chunk = {}
            count = 0
        end
    end

    if #chunk > 0 then
        print("MAP_DATA_CHUNK:" .. JsonEncode(chunk))
    end

    print("MAP_DATA_END")
end

-- *************************************************************************************************

function Toggle(ParameterId, Value)
	if ParameterId == "ExportButton_Hide" then
		Controls.ExportButton:SetHide(Value)
		return
	end
end

function Initialize()
	local ctr = ContextPtr:LookUpControl("/InGame/TopPanel/RightContents")
	Controls.ExportButton:ChangeParent(ctr)
	Controls.ExportButton:SetToolTipString(Locale.Lookup("MEX_BUTTON_TEXT"))
	Controls.ExportButton:RegisterCallback(	Mouse.eLClick, ExportMapToJSONChunked);
	
	LuaEvents.TPT_Settings_Toggle.Add(Toggle)
end

Events.LoadScreenClose.Add(Initialize)
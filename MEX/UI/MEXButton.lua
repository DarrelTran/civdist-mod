function JsonEncode(tbl)
    local json = "["
    for i, entry in ipairs(tbl) do

        local buildingsArray = "["
        for j, b in ipairs(entry.Buildings or {}) do
            buildingsArray = buildingsArray .. "\"" .. escapeString(b) .. "\""
            if j < #entry.Buildings then
                buildingsArray = buildingsArray .. ","
            end
        end
        buildingsArray = buildingsArray .. "]"

        local e = string.format(
        "{\"X\":%d, \"Y\":%d, \"TerrainType\":\"%s\", \"FeatureType\":\"%s\", \"ResourceType\":\"%s\", \"ImprovementType\":\"%s\", \"IsHills\":%s, \"IsMountain\":%s, \"IsWater\":%s, \"IsCity\":%s, \"TileCity\":\"%s\", \"IsRiver\":%s, \"IsNEOfRiver\":%s, \"IsWOfRiver\":%s, \"IsNWOfRiver\":%s, \"RiverSWFlow\":\"%s\", \"RiverEFlow\":\"%s\", \"RiverSEFlow\":\"%s\", \"Appeal\":%d, \"Continent\":\"%s\", \"Civilization\":\"%s\", \"Leader\":\"%s\", \"CityName\":\"%s\", \"District\":\"%s\", \"Buildings\":%s, \"Food\":%d, \"Production\":%d, \"Gold\":%d, \"Science\":%d, \"Culture\":%d, \"Faith\":%d}",
        tonumber(entry.X),
        tonumber(entry.Y),
        tostring(entry.TerrainType),
        tostring(entry.FeatureType),
        tostring(entry.ResourceType),
        tostring(entry.ImprovementType),
        tostring(entry.IsHills),
        tostring(entry.IsMountain),
        tostring(entry.IsWater),
        tostring(entry.IsCity),
        tostring(entry.TileCity),
        tostring(entry.IsRiver),
        tostring(entry.IsNEOfRiver), tostring(entry.IsWOfRiver), tostring(entry.IsNWOfRiver),
        tostring(entry.RiverSWFlow or "NONE"), tostring(entry.RiverEFlow or "NONE"), tostring(entry.RiverSEFlow or "NONE"),
        tonumber(entry.Appeal or 0),
        tostring(entry.ContinentType),
        tostring(entry.OwnerCiv),
        tostring(entry.OwnerLeader),
        tostring(entry.CityName),
        tostring(entry.DistrictType),
        buildingsArray,
        tonumber(entry.Food), tonumber(entry.Production), tonumber(entry.Gold),
        tonumber(entry.Science), tonumber(entry.Culture), tonumber(entry.Faith)
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

function ExportMapToJSONChunked()
    print("MAP_DATA_START")

    local chunkSize = 3
    local chunk = {}
    local count = 0

    for i = 0, Map.GetPlotCount() - 1 do
        local plot = Map.GetPlotByIndex(i)

        local ownerID = plot:GetOwner()
        local civ = "NONE"
        local leader = "NONE"
        local cityName = "NONE"
        local districtType = "NONE"
        local buildings = {}
        local tileCityOwner = "NONE"

        if ownerID ~= -1 then
            local config = PlayerConfigurations[ownerID]
            if config then
                civ = SafeLookup(config:GetCivilizationDescription())
                leader = SafeLookup(config:GetLeaderName())
            end
        end

        -- City on tile
        if plot:IsCity() then
            local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
            if city then
                cityName = SafeLookup(city:GetName())
            end
        end

        -- District on tile
        local districtID = plot:GetDistrictType()
        if districtID ~= -1 then
            local districtInfo = GameInfo.Districts[districtID]
            if districtInfo then
                districtType = SafeLookup(districtInfo.DistrictType)
            end

            -- Try to get buildings if the district has a city context
            local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
            if city then
                local districts = city:GetDistricts()
                if districts then
                    local district = districts:FindID(plot:GetDistrictID())
                    if district and district.IsBuildingComplete then
                        for building in GameInfo.Buildings() do
                            if district:IsBuildingComplete(building.Index) then
                                table.insert(buildings, building.BuildingType)
                            end
                        end
                    end
                end
            end
        end

        local cityTile = Cities.GetPlotPurchaseCity(plot)
        if cityTile then
            tileCityOwner = SafeLookup(cityTile:GetName())
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

        local plotData = 
        {
            X = plot:GetX(),
            Y = plot:GetY(),
            TerrainType = SafeLookup(GameInfo.Terrains[plot:GetTerrainType()] and GameInfo.Terrains[plot:GetTerrainType()].Name), -- tundra, grassland, ocean, etc
            FeatureType = SafeLookup(GameInfo.Features[plot:GetFeatureType()] and GameInfo.Features[plot:GetFeatureType()].Name),
            ResourceType = SafeLookup(GameInfo.Resources[plot:GetResourceType()] and GameInfo.Resources[plot:GetResourceType()].Name),
            ImprovementType = SafeLookup(GameInfo.Improvements[improvementID] and GameInfo.Improvements[improvementID].Name),
            IsHills = plot:IsHills(),
            IsMountain = plot:IsMountain(),
            IsWater = plot:IsWater(),
            IsCity = plot:IsCity(),
            TileCity = tileCityOwner,
            IsRiver = plot:IsRiver(),
            IsNEOfRiver = plot:IsNEOfRiver(),
            IsWOfRiver = plot:IsWOfRiver(),
            IsNWOfRiver = plot:IsNWOfRiver(),
            RiverSWFlow = SWFlow,
            RiverEFlow = EFlow,
            RiverSEFlow = SEFlow,
            Appeal = plot:GetAppeal(),
            ContinentType = SafeLookup(GameInfo.Continents[plot:GetContinentType()] and GameInfo.Continents[plot:GetContinentType()].Name),
            OwnerCiv = civ,
            OwnerLeader = leader,
            CityName = cityName,
            DistrictType = districtType,
            Buildings = buildings,
            Food = plot:GetYield(0),
            Production = plot:GetYield(1),
            Gold = plot:GetYield(2),
            Science = plot:GetYield(3),
            Culture = plot:GetYield(4),
            Faith = plot:GetYield(5)
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
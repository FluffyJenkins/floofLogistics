
local equipmentCategories = {}
for _, category in pairs(data.raw['equipment-category']) do
    table.insert(equipmentCategories, category.name)
end

data.raw["equipment-grid"]["floof:grid"].equipment_categories = equipmentCategories
data.raw["battery-equipment"]["floof:logisticPort"].categories = equipmentCategories
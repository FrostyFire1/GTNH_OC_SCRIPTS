local config = {}
config.preference = {
    ["Common"]= {"Forest","Meadows"},
    ["Oily"]= {"Ocean","Primeval"},
    ["Corroded"]= {"Wintry","Resilient"},
    ["Ruby"]= {"Redstone","Diamond"},
    ["Sinister"]= {"Cultivated","Modest"},
    ["Tarnished"]= {"Marshy", "Resilient"},
    ["Lustered"]= {"Forest","Resilient"},
    ["Glittering"]= {"Majestic","Rusty"},
    ["Diamond"]= {"Certus","Coal"},
    ["Galvanized"]= {"Wintry","Resilient"},
    ["Frugal"]= {"Modest","Sinister"},
    ["Leaden"]= {"Meadows","Resilient"},
    ["Shining"]= {"Majestic","Galvanized"},
    ["Spirit"]= {"Ethereal","Aware"},
    ["Nuclear"]= {"Unstable","Rusty"},
    ["Cultivated"]= {"Common","Forest"},
    ["Arid"]= {"Meadows","Frugal"},
    ["Indium"]= {"Lead","Osmium"},
    ["Sapphire"]= {"Certus","Lapis"},
    ["Fossilised"]= {"Primeval","Growing"},
    ["Fungal"]= {"Boggy","Miry"},
    ["Scummy"]= {"Agrarian","Exotic"},
    ["Fiendish"]= {"Sinister","Cultivated"},
    ["Emerald"]= {"Olivine","Diamond"},
    ["Rusty"]= {"Meadows","Resilient"},
    ["Vengeful"]= {"Demonic","Vindictive"},
    ["Eldritch"]= {"Mystical","Cultivated"},


}
config.geneWeights = {
    ["species"] = 5,
    ["lifespan"] = 1,
    ["speed"] = 1,
    ["flowering"] = 1,
    ["flowerProvider"] = 1,
    ["fertility"] = 7,
    ["territory"] = 1,
    ["effect"] = 1,

    ["temperatureTolerance"] = 4,
    ["humidityTolerance"] = 4,
    ["nocturnal"] = 2,
    ["tolerantFlyer"] = 2,
    ["caveDwelling"] = 2,
}
config.breedWeights = {
    ["species"] = 5,
}
config.activeBonus = 1.2

config.weightSum = 0
for _,value in pairs(config.geneWeights) do
    config.weightSum = config.weightSum + value
end
config.targetSum = config.weightSum + config.weightSum * config.activeBonus - (config.geneWeights.species * (config.activeBonus - 1))

config.devConfig = {
    ["storage"] = 4,
    ["breeder"] = 5,
    ["scanner"] = 2,
    ["garbage"] = 1,
    ["output"] = 3,
}

config.port = 3001
config.robotPort = 3000
return config
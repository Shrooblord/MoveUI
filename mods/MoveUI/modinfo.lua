
meta =
{
    id = "MoveUI_2023",
    name = "MoveUI_2023",
    title = "MoveUI_2023",
    type = "mod",

    description = "Dirtyredz' excellent MoveUI mod, updated for Avorion 2.3.* in February 2023.",
    authors = {"Shrooblord", "David McClain (Dirtyredz)"},

    version = "2.2.3",
    dependencies = {
        {id = "Avorion", min = "2.3.1", max = "2.3.*"},

        {id = "1722652757", min = "1.4"},                   --AzimuthLib (config library mod)

        --[[Shrooblord]]
        --{id = "1847767864", min = "1.1.4"},               --ShrooblordMothership (library mod)
        --{id = "ShrooblordMothership", min = "1.1.4"},     --ShrooblordMothership (library mod)
    },

    serverSideOnly = false,
    clientSideOnly = false,
    saveGameAltering = true,

    contact = "avorion@shrooblord.com",
}

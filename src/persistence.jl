# Metagraphs files are simply JLD2 files.

struct MGFormat <: AbstractGraphFormat end

function loadmg(fn::AbstractString)
    @load fn g
    return g
end

function savemg(fn::AbstractString, g::AbstractMetaGraph)
    @save fn g
    return 1
end

loadgraph(fn::AbstractString, gname::String, ::MGFormat) = loadmg(fn)
savegraph(fn::AbstractString, g::AbstractMetaGraph) =  savemg(fn, g)

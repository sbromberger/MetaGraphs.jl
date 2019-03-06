# Metagraphs files are simply JLD2 files.

struct MGFormat <: AbstractGraphFormat end
struct DOTFormat <: AbstractGraphFormat end

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

"""
escapeHTML(i::String)
Returns a string with special HTML characters escaped: &, <, >, ", '
"""
function escapehtml(i::AbstractString)
    # Refer to http://stackoverflow.com/a/7382028/3822752 for spec. links
    o = replace(i, "&" =>"&amp;")
    o = replace(o, "\""=>"&quot;")
    o = replace(o, "'" =>"&#39;")
    o = replace(o, "<" =>"&lt;")
    o = replace(o, ">" =>"&gt;")
    return o
end

function savedot(io::IOStream, g::MetaDiGraph)
    write(io, "digraph G {\n")
    for p in props(g)
        write(io, "$(p[1])=$(escapehtml(string(p[2])));\n")
    end

    for v in vertices(g)
        write(io, "$v")
        if length(props(g, v)) > 0
            write(io, " [ ")
        end
        for p in props(g, v)
            key = p[1]
            write(io, "$key=\"$(escapehtml(string(p[2])))\",")
        end
        if length(props(g, v)) > 0
            write(io, "];")
        end
        write(io, "\n")
    end

    for e in edges(g)
        write(io, "$(src(e)) -> $(dst(e)) [ ")
        for p in props(g,e)
            write(io, "$(p[1])=\"$(escapehtml(string(p[2])))\", ")
        end
        write(io, "]\n")
    end
    write(io, "}\n")
end

function savegraph(fn::AbstractString, g::AbstractMetaGraph, ::DOTFormat)
    open(fn, "w") do fp 
        savedot(fp, g)
    end
end

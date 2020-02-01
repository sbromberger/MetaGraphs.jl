# Metagraphs files are simply JLD2 files.

"""
    struct MGFormat <: AbstractGraphFormat end

You can save `AbstractMetaGraph`s in a `MGFormat`, currently based on `JLD2`.

```jldoctest
julia> using MetaGraphs

julia> using LightGraphs: Edge, Graph,  loadgraph, savegraph

julia> colors = meta_graph(Graph(), AtVertex = Symbol, AtEdge = Symbol);

julia> red = push!(colors, :red); blue = push!(colors, :blue); yellow = push!(colors, :yellow);

julia> colors[Edge(red, blue)] = :purple; colors[Edge(blue, yellow)] = :green; colors[Edge(yellow, red)] = :orange;

julia> mktemp() do file, io
            savegraph(file, colors)
            loadgraph(file, "something", MGFormat()) == colors
        end
true
```
"""
struct MGFormat <: AbstractGraphFormat end
export MGFormat

"""
    struct DOTFormat <: AbstractGraphFormat end

For supported metadata formats (edge.meta. AbstractDict, NamedTuple, Nothing), you
can save `AbstractMetaGraph`s in `DOTFormat`.

```jldoctest DotFormat
julia> using MetaGraphs

julia> using LightGraphs: Edge, DiGraph, Graph, savegraph, loadgraph

julia> test1 = meta_graph(DiGraph(), AtVertex = Dict{Symbol, String}, AtEdge = Dict{Symbol, String});

julia> a = push!(test1, Dict(:name => "a")); b = push!(test1, Dict(:name => "b"));

julia> test1[Edge(a, b)] = Dict(:name => "ab");

julia> mktemp() do file, io
            savegraph(file, test1, DOTFormat())
            print(read(file, String))
        end
digraph {
    1 [name = \"a\"]
    2 [name = \"b\"]
    1 -> 2 [name = \"ab\"]
}

julia> test2 = meta_graph(Graph(), AtEdge = Dict{Symbol, Any},
            graph_meta = (sugar = true, spice = true, everything_nice = true)
        );

julia> a = push!(test2, nothing); b = push!(test2, nothing);

julia> test2[Edge(a, b)] = Dict(:name => "ab", :in_order => true);

julia> mktemp() do file, io
            savegraph(file, test2, DOTFormat(), )
            print(read(file, String))
        end
graph {
    sugar = true
    spice = true
    everything_nice = true
    1
    2
    1 -- 2 [name = "ab", in_order = true]
}
```
"""
struct DOTFormat <: AbstractGraphFormat end
export DOTFormat

function loadgraph(filename::AbstractString, ::String, ::MGFormat)
    @load filename meta
    return meta
end
function savegraph(filename::AbstractString, meta::AbstractMetaGraph)
    @save filename meta
    return 1
end

show_meta_list(io::IO, meta::Nothing) = nothing
function show_meta_list(io::IO, meta::Union{AbstractDict, NamedTuple})
    if !isempty(meta)
        print(io, " [")
        first_one = true
        for (key, value) in pairs(meta)
            if first_one
                first_one = false
            else
                print(io, ", ")
            end
            print(io, key)
            print(io, " = ")
            show(io, value)
        end
        print(io, ']')
    end
    return nothing
end

show_meta(io::IO, meta::Nothing) = nothing
function show_meta(io::IO, meta::Union{AbstractDict, NamedTuple})
    for (key, value) in pairs(meta)
        print(io, "    ")
        print(io, key)
        print(io, " = ")
        show(io, value)
        print(io, '\n')
    end
    return nothing
end

function savedot(io::IO, meta::AbstractMetaGraph)
    dash = if is_directed(meta)
        print(io, "digraph {\n")
        "->"
    else
        print(io, "graph {\n")
        "--"
    end

    show_meta(io, meta.graph_meta)

    for vertex in vertices(meta)
        print(io, "    ")
        show(io, vertex)
        show_meta_list(io, meta[vertex])
        print(io, '\n')
    end

    for edge in edges(meta)
        print(io, "    ")
        in_vertex, out_vertex = Tuple(edge)
        print(io, in_vertex)
        print(io, ' ')
        print(io, dash)
        print(io, ' ')
        show(io, out_vertex)
        show_meta_list(io, meta[edge])
        print(io, '\n')
    end
    write(io, "}\n")
    return nothing
end

function savegraph(filename::AbstractString, meta::AbstractMetaGraph, ::DOTFormat)
    open(filename, "w") do io
        savedot(io, meta)
    end
    return nothing
end

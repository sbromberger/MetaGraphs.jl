# Metagraphs files are simply JLD2 files.

"""
    struct MGFormat <: AbstractGraphFormat end

You can save `AbstractMetaGraph`s in a `MGFormat`, currently based on `JLD2`.

```jldoctest
julia> using MetaGraphs

julia> using LightGraphs: Edge, Graph,  loadgraph, savegraph

julia> test_graph = meta_graph(Graph());

julia> mktemp() do file, io
            savegraph(file, test_graph)
            loadgraph(file, "something", MGFormat()) == test_graph
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

julia> using LightGraphs

julia> test_graph = meta_graph(DiGraph(),
            AtVertex = Dict{Symbol, String},
            AtEdge = Dict{Symbol, String},
            graph_meta = (tagged = true,)
        );

julia> a = push!(test_graph, Dict(:name => "a")); b = push!(test_graph, Dict(:name => "b"));

julia> test_graph[Edge(a, b)] = Dict(:name => "ab");

julia> mktemp() do file, io
            savegraph(file, test_graph, DOTFormat())
            print(read(file, String))
        end
digraph {
    tagged = true
    1 [name = "a"]
    2 [name = "b"]
    1 -> 2 [name = "ab"]
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

function show_meta_list(io::IO, meta)
    if meta !== nothing && !isempty(meta)
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

function savedot(io::IO, meta::AbstractMetaGraph)
    dash = if is_directed(meta)
        print(io, "digraph {\n")
        "->"
    else
        print(io, "graph {\n")
        "--"
    end

    graph_meta = meta.graph_meta
    if graph_meta !== nothing
        for (key, value) in pairs(graph_meta)
            print(io, "    ")
            print(io, key)
            print(io, " = ")
            show(io, value)
            print(io, '\n')
        end
    end

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

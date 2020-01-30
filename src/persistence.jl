# Metagraphs files are simply JLD2 files.
"""
    struct NativeFormat <: AbstractGraphFormat end

You can save `MetaGraph`s in a `NativeFormat`, currently based on JLD2.

```jldoctest
julia> using MetaGraphs

julia> using LightGraphs: Edge, Graph,  loadgraph, savegraph

julia> colors = meta_graph(Graph(), AtVertex = Symbol, AtEdge = Symbol);

julia> red = push!(colors, :red); blue = push!(colors, :blue); yellow = push!(colors, :yellow);

julia> colors[Edge(red, blue)] = :purple; colors[Edge(blue, yellow)] = :green; colors[Edge(yellow, red)] = :orange;

julia> mktemp() do file, io
            savegraph(file, colors)
            loadgraph(file, "something", NativeFormat()) == colors
        end
true
```
"""
struct NativeFormat <: AbstractGraphFormat end
export NativeFormat

"""
    struct DOTFormat <: AbstractGraphFormat end

For supported meta data formats (e.g. AbstractDict, NamedTuple, Nothing), you
can save `MetaGraph`s in `DOTFormat`.

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
```

You can optionally specify graph-level metadata using the keyword `properties`.

```jldoctest DotFormat
julia> test2 = meta_graph(Graph(), AtEdge = Dict{Symbol, String});

julia> a = push!(test2, nothing); b = push!(test2, nothing);

julia> test2[Edge(a, b)] = Dict(:name => "ab");

julia> mktemp() do file, io
            savegraph(file, test2, DOTFormat(), properties = (sugar = true, spice = true, everything_nice = true))
            print(read(file, String))
        end
graph {
    sugar = true
    spice = true
    everything_nice = true
    1
    2
    1 -- 2 [name = \"ab\"]
}
```
"""
struct DOTFormat <: AbstractGraphFormat end
export DOTFormat

function loadgraph(filename::AbstractString, ::String, ::NativeFormat)
    @load filename meta
    return meta
end
function savegraph(filename::AbstractString, meta::MetaGraph)
    @save filename meta
    return 1
end

inner_dot_meta(io::IO, properties::Nothing) = nothing
function inner_dot_meta(io::IO, properties::Union{AbstractDict, NamedTuple})
    if !isempty(properties)
        print(io, " [")
        first_one = true
        for (key, value) in pairs(properties)
            if first_one
                first_one = false
            else
                print(io, ", ")
            end
            print(io, key)
            print(io, " = ")
            show(io, value)
        end
        print(io, "]")
        nothing
    end
end

outer_dot_meta(io::IO, properties::Nothing) = nothing
function outer_dot_meta(io::IO, properties::Union{AbstractDict, NamedTuple})
    for (key, value) in pairs(properties)
        print(io, "    ")
        print(io, key)
        print(io, " = ")
        show(io, value)
        print(io, '\n')
    end
    nothing
end

function savedot(io::IO, meta::MetaGraph, properties)
    inner_graph = meta.inner_graph
    vertex_meta = meta.vertex_meta
    edge_meta = meta.edge_meta

    dash =
        if is_directed(inner_graph)
            write(io, "digraph {\n")
            "->"
        else
            write(io, "graph {\n")
            "--"
        end

    outer_dot_meta(io, properties)

    for vertex in vertices(inner_graph)
        write(io, "    ")
        show(io, vertex)
        inner_dot_meta(io, vertex_meta[vertex])
        write(io, '\n')
    end

    for edge in edges(inner_graph)
        write(io, "    ")
        show(io, edge.src)
        write(io, ' ')
        write(io, dash)
        write(io, ' ')
        show(io, edge.dst)
        inner_dot_meta(io, edge_meta[edge])
        write(io, '\n')
    end
    write(io, "}\n")
end

function savegraph(filename::AbstractString, meta::MetaGraph, ::DOTFormat; properties = nothing)
    open(filename, "w") do io
        savedot(io, meta, properties)
    end
end

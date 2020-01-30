module MetaGraphs

import Base: ==, copy, getindex, delete!, haskey, push!, reverse, setindex!,
    show, zero
import LightGraphs: induced_subgraph, loadgraph, savegraph
using LightGraphs: AbstractEdge, AbstractGraph, AbstractGraphFormat, add_edge!,
    add_vertex!, Edge, edges, inneighbors, is_directed, is_ordered, nv,
    outneighbors, rem_edge!, rem_vertex!, vertices

using JLD2: @load, @save

struct MetaGraph{Vertex, InnerGraph, AtVertex, AtEdge}
    inner_graph::InnerGraph
    vertex_meta::Dict{Vertex, AtVertex}
    edge_meta::Dict{Edge{Vertex}, AtEdge}
end

function MetaGraph(inner_graph::AbstractGraph{Vertex};
    vertex_meta::Dict{Vertex, AtVertex} = Dict{Vertex, Nothing}(),
    edge_meta::Dict{Edge{Vertex}, AtEdge} = Dict{Edge{Vertex}, Nothing}()
) where {Vertex, AtVertex, AtEdge}
    MetaGraph{Vertex, typeof(inner_graph), AtVertex, AtEdge}(inner_graph, vertex_meta, edge_meta)
end

"""
    meta_graph(inner_graph::AbstractGraph{Vertex}; AtVertex = Nothing, AtEdge = Nothing)

Construct a new meta graph, where `AtVertex` is the type of the meta data at a
vertex, and `AtEdge` is the type of the meta data at an edge.

```jldoctest example
julia> using MetaGraphs

julia> using LightGraphs: Edge, Graph

julia> colors = meta_graph(Graph(), AtVertex = Symbol, AtEdge = Symbol)
MetaGraph based on a {0, 0} undirected simple Int64 graph with Symbol(s) at vertices and Symbol(s) at edges
```

Use `push!` to add a new vertex with the given metadata. `push!` will return
the vertex number of the new vertex. Note that you can associate the same
meta data with multiple vertices.

```jldoctest example
julia> red = push!(colors, :red)
1

julia> push!(colors, :blue)
2

julia> yellow = push!(colors, :yellow)
3
```

You can access and change the metadata at the vertex using indexing:

```jldoctest example
julia> colors[1] = :scarlet;

julia> colors[1]
:scarlet
```

```jldoctest example
julia> orange = Edge(red, yellow);

julia> colors[orange] = :orange;

julia> colors[orange]
:orange
```

You can also access the graph, and the meta data about the vertices and edges,
directly.

```jldoctext example
julia> nv(colors.inner_graph)
3

julia> colors.vertex_meta[2]
:blue

julia> colors.edge_meta[orange]
:orange
```

You can delete vertices and edges with `delete!`

```jldoctext example
julia> delete!(colors, orange)

julia> delete!(colors, 1)
```

Some Base functions work on meta graphs.

```jldoctest example
julia> copy(colors) == colors
true

julia> zero(colors)
MetaGraph based on a {0, 0} undirected simple Int64 graph with Symbol(s) at vertices and Symbol(s) at edges
```
"""
function meta_graph(inner_graph::AbstractGraph{Vertex}; AtVertex = Nothing, AtEdge = Nothing) where {Vertex}
    MetaGraph(inner_graph,
        vertex_meta = Dict{Vertex, AtVertex}(),
        edge_meta = Dict{Edge{Vertex}, AtEdge}()
    )
end

export meta_graph

function maybe_order_edge(graph, edge)
    if is_directed(graph)
        edge
    else
        if is_ordered(edge)
            edge
        else
            reverse(edge)
        end
    end
end

function haskey(meta::MetaGraph, edge::AbstractEdge)
    haskey(meta.edge_meta, edge)
end

function getindex(meta::MetaGraph, edge::AbstractEdge)
    meta.edge_meta[edge]
end

function setindex!(meta::MetaGraph, value, edge::AbstractEdge)
    add_edge!(meta.inner_graph, edge)
    meta.edge_meta[maybe_order_edge(meta.inner_graph, edge)] = value
    nothing
end

function delete_meta!(meta, edge::AbstractEdge)
    delete!(meta.edge_meta, maybe_order_edge(meta.inner_graph, edge))
    nothing
end

function delete!(meta::MetaGraph, edge::AbstractEdge)
    delete_meta!(meta, edge)
    rem_edge!(meta.inner_graph, edge)
    nothing
end

function getindex(meta::MetaGraph, vertex::Integer)
    meta.vertex_meta[vertex]
end

function haskey(meta::MetaGraph, vertex::Integer)
    haskey(meta.vertex_meta, vertex)
end

function setindex!(meta::MetaGraph, value, vertex::Integer)
    meta.vertex_meta[vertex] = value
    nothing
end

function delete_meta!(meta, vertex::Integer)
    inner_graph = meta.inner_graph
    vertex_meta = meta.vertex_meta
    if haskey(vertex_meta, vertex)
        delete!(vertex_meta, vertex)
    end
    for out_neighbor in outneighbors(inner_graph, vertex)
        delete_meta!(meta, Edge(vertex, out_neighbor))
    end
    for in_neighbor in inneighbors(inner_graph, vertex)
        delete_meta!(meta, Edge(in_neighbor, vertex))
    end
    nothing
end

function move_meta!(meta, old_edge::AbstractEdge, new_edge::AbstractEdge)
    inner_graph = meta.inner_graph
    edge_meta = meta.edge_meta
    if haskey(edge_meta, old_edge)
        edge_meta[maybe_order_edge(inner_graph, new_edge)] = pop!(edge_meta, old_edge)
    end
    nothing
end

function move_meta!(meta, old_vertex::Integer, new_vertex::Integer)
    inner_graph = meta.inner_graph
    vertex_meta = meta.vertex_meta
    if haskey(vertex_meta, old_vertex)
        vertex_meta[new_vertex] = pop!(vertex_meta, old_vertex)
    end
    for out_neighbor in outneighbors(inner_graph, old_vertex)
        move_meta!(meta,
            Edge(old_vertex, out_neighbor),
            Edge(new_vertex, out_neighbor)
        )
    end
    for in_neighbor in inneighbors(inner_graph, old_vertex)
        move_meta!(meta,
            Edge(in_neighbor, old_vertex),
            Edge(in_neighbor, new_vertex)
        )
    end
    nothing
end

function delete!(meta::MetaGraph, vertex::Integer)
    inner_graph = meta.inner_graph
    vertex_meta = meta.vertex_meta
    if vertex in vertices(inner_graph)
        last_vertex = nv(inner_graph)
        delete_meta!(meta, vertex)
        if vertex != last_vertex
            move_meta!(meta, last_vertex, vertex)
        end
        rem_vertex!(inner_graph, vertex)
    end
    nothing
end

function copy_meta!(old_meta, new_meta, vertex_map)
    old_vertices = old_meta.vertex_meta
    old_edges = old_meta.edge_meta
    new_vertices = new_meta.vertex_meta
    new_edges = new_meta.edge_meta
    for (new_vertex, old_vertex) in enumerate(vertex_map)
        if haskey(old_vertices, old_vertex)
            new_vertices[new_vertex] = old_vertices[old_vertex]
        end
    end
    for new_edge in edges(new_meta.inner_graph)
        old_edge = maybe_order_edge(old_meta.inner_graph, Edge(
            vertex_map[new_edge.src],
            vertex_map[new_edge.dst]
        ))
        if haskey(old_edges, old_edge)
            new_edges[new_edge] = old_edges[old_edge]
        end
    end
    nothing
end

function induced_subgraph(old_meta::MetaGraph, selected)
    old_graph = old_meta.inner_graph
    new_graph, vertex_map = induced_subgraph(old_graph, selected)
    new_meta =
        MetaGraph(new_graph,
            vertex_meta = empty(old_meta.vertex_meta),
            edge_meta = empty(old_meta.edge_meta)
        )
    copy_meta!(old_meta, new_meta, vertex_map)
    new_meta
end

function reverse_edge(graph, pair)
    maybe_order_edge(graph, reverse(pair.first)) => pair.second
end

function reverse(meta::MetaGraph)
    inner_graph = meta.inner_graph
    MetaGraph(reverse(inner_graph),
        vertex_meta = meta.vertex_meta,
        edge_meta = Dict(reverse_edge(inner_graph, pair) for pair in meta.edge_meta)
    )
end

function push!(meta::MetaGraph, value)
    inner_graph = meta.inner_graph
    add_vertex!(inner_graph)
    new_vertex = nv(inner_graph)
    meta[new_vertex] = value
    new_vertex
end

seek_vertex(meta::MetaGraph, value) =
    findfirst(isequal(value), meta.vertex_meta)

==(meta1::MetaGraph, meta2::MetaGraph) =
    meta1.inner_graph == meta2.inner_graph &&
    meta1.edge_meta == meta2.edge_meta &&
    meta2.vertex_meta == meta2.vertex_meta

copy(graph::MetaGraph) = deepcopy(graph)
zero(::MetaGraph{<:Any, InnerGraph, AtVertex, AtEdge}) where {InnerGraph, AtVertex, AtEdge} =
    meta_graph(InnerGraph(); AtVertex = AtVertex, AtEdge = AtEdge)

function show(io::IO, meta::MetaGraph{<: Any, <:Any, AtVertex, AtEdge}) where {AtVertex, AtEdge}
    print(io, "MetaGraph based on a $(meta.inner_graph) with $AtVertex(s) at vertices and $AtEdge(s) at edges")
end

include("persistence.jl")

end # module

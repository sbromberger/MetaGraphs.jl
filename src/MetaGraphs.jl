module MetaGraphs
using LightGraphs
using JLD2

import Base:
    eltype, show, ==, Pair,
    Tuple, copy, length, size,
    issubset, zero, getindex, delete!, haskey, push!, setindex!

import LightGraphs:
    AbstractGraph, src, dst, edgetype, nv,
    ne, vertices, edges, is_directed,
    add_vertex!, add_edge!, rem_vertex!, rem_edge!,
    has_vertex, has_edge, inneighbors, outneighbors,
    weights, indegree, outdegree, degree,
    induced_subgraph,
    loadgraph, savegraph, AbstractGraphFormat,
    reverse

import LightGraphs.SimpleGraphs:
    AbstractSimpleGraph, SimpleGraph, SimpleDiGraph,
    SimpleEdge, fadj, badj

export
    meta_graph,
    weight_type,
    default_weight,
    weight_function,
    filter_edges,
    filter_vertices,
    MGFormat,
    DOTFormat,
    reverse

maybe_order_edge(graph, edge) =
    if is_directed(graph)
        edge
    else
        if is_ordered(edge)
            edge
        else
            reverse(edge)
        end
    end

include("metagraph.jl")

function show(io::IO, meta::MetaGraph{<: Any, <: Any, AtVertex, AtEdge, GraphMeta, <: Any, Weight}) where {AtVertex, AtEdge, GraphMeta, Weight}
    print(io, "Meta graph based on a $(meta.inner_graph) with $AtVertex(s) at vertices, $AtEdge(s) at edges, $GraphMeta metadata, $Weight weights, and default weight $(meta.default_weight)")
end

@inline fadj(meta::MetaGraph, arguments...) =
    fadj(meta.inner_graph, arguments...)
@inline badj(meta::MetaGraph, arguments...) =
    badj(meta.inner_graph, arguments...)

eltype(meta::MetaGraph) = eltype(meta.inner_graph)
edgetype(meta::MetaGraph) = edgetype(meta.inner_graph)
nv(meta::MetaGraph) = nv(meta.inner_graph)
vertices(meta::MetaGraph) = vertices(meta.inner_graph)

ne(meta::MetaGraph) = ne(meta.inner_graph)
edges(meta::MetaGraph) = edges(meta.inner_graph)

has_vertex(meta::MetaGraph, arguments...) =
    has_vertex(meta.inner_graph, arguments...)
@inline has_edge(meta::MetaGraph, arguments...) =
    has_edge(meta.inner_graph, arguments...)

inneighbors(meta::MetaGraph, vertex::Integer) =
    inneighbors(meta.inner_graph, vertex)
outneighbors(meta::MetaGraph, vertex::Integer) = fadj(meta.inner_graph, vertex)

issubset(meta::MetaGraph, meta2::MetaGraph) =
    issubset(meta.inner_graph, meta2.inner_graph)

@inline function delete!(meta::MetaGraph, edge::Edge)
    delete!(meta.edge_meta, maybe_order_edge(meta, edge))
    return nothing
end

add_vertex!(meta::MetaGraph) = add_vertex!(meta.inner_graph)
function push!(meta::MetaGraph, value)
    add_vertex!(meta) || return false
    last_vertex = nv(meta)
    meta[last_vertex] = value
    return last_vertex
end

function move_meta!(meta::MetaGraph, vertex::Integer, last_vertex::Integer)
    if haskey(meta, vertex)
        meta[last_vertex] = pop!(meta.vertex_meta, vertex)
    end
    for neighbor in outneighbors(meta, vertex)
        move_meta!(meta, Edge(vertex, neighbor), Edge(last_vertex, neighbor))
    end
    for neighbor in inneighbors(meta, vertex)
        move_meta!(meta, Edge(neighbor, vertex), Edge(neighbor, last_vertex))
    end
    return nothing
end

function move_meta!(meta, old_edge::AbstractEdge, new_edge::AbstractEdge)
    if haskey(meta, old_edge)
        meta[maybe_order_edge(meta, new_edge)] = pop!(meta.edge_meta, old_edge)
    end
    return nothing
end

rem_vertex!(meta::MetaGraph, vertex) =
    rem_vertex!(meta.inner_graph, vertex)

function delete!(meta::MetaGraph, vertex::Integer)
    last_vertex = nv(meta)
    if vertex != last_vertex
        move_meta!(meta, last_vertex, vertex)
        return last_vertex => vertex
    else
        rem_vertex!(meta, vertex)
        return nothing
    end
end

struct MetaWeights{Weight <: Real, InnerMetaGraph} <: AbstractMatrix{Weight}
    inner_meta_graph::InnerMetaGraph
end

show(io::IO, weights::MetaWeights) = print(io, "metaweights")
show(io::IO, ::MIME"text/plain", weights::MetaWeights) = show(io, weights)

MetaWeights(meta::MetaGraph) = MetaWeights{weight_type(meta), typeof(meta)}(meta)

is_directed(::Type{<: MetaWeights{<: Any, InnerMetaGraph}}) where {InnerMetaGraph} =
    is_directed(InnerMetaGraph)

function getindex(weights::MetaWeights{Weight}, in_vertex::Integer, out_vertex::Integer)::Weight where {Weight}
    edge = maybe_order_edge(weights, Edge(in_vertex, out_vertex))
    inner_meta_graph = weights.inner_meta_graph
    if haskey(inner_meta_graph, edge)
        Weight(inner_meta_graph.weight_function(inner_meta_graph[edge]))
    else
        inner_meta_graph.default_weight
    end
end

function size(weights::MetaWeights)
    vertices = nv(weights.inner_meta_graph)
    (vertices, vertices)
end

weights(meta::MetaGraph) = MetaWeights(meta)

getindex(meta::MetaGraph, vertex::Integer) = meta.vertex_meta[vertex]
getindex(meta::MetaGraph, edge::AbstractEdge) = meta.edge_meta[edge]

haskey(meta::MetaGraph, vertex::Integer) = haskey(meta.vertex_meta, vertex)
haskey(meta::MetaGraph, edge::AbstractEdge) = haskey(meta.edge_meta, edge)

function setindex!(meta::MetaGraph, value, vertex::Integer)
    meta.vertex_meta[vertex] = value
    return nothing
end

"""
    weight_function(meta)

Return the  weight function for meta graph `meta`.

```jldoctest
julia> using MetaGraphs

julia> using LightGraphs: Graph

julia> weight_function(meta_graph(Graph(), weight_function = identity))(0)
0
```
"""
weight_function(meta::MetaGraph) = meta.weight_function

"""
    default_weight(meta)

Return the default weight for meta graph `meta`.

```jldoctest
julia> using MetaGraphs

julia> using LightGraphs: Graph

julia> default_weight(meta_graph(Graph(), default_weight = 2.0))
2.0
```
"""
default_weight(meta::MetaGraph) = meta.default_weight

"""
    filter_edges(meta, a_function)

Find edges for which `a_function` applied to the edge's metadata returns `true`.

```jldoctest
julia> using MetaGraphs

julia> using LightGraphs: Edge, Graph

julia> test = meta_graph(Graph(), AtEdge = Symbol);

julia> push!(test, nothing); push!(test, nothing); push!(test, nothing);

julia> test[Edge(1, 2)] = :a; test[Edge(2, 3)] = :b;

julia> filter_edges(test, isequal(:a))
1-element Array{LightGraphs.SimpleGraphs.SimpleEdge{Int64},1}:
 Edge 1 => 2
```
"""
filter_edges(meta::MetaGraph, a_function::Function) =
    findall(a_function, meta.edge_meta)

"""
    filter_vertices(meta, a_function)

Find vertices for which  `a_function` applied to the vertex's metadata returns
`true`.

```jldoctest
julia> using MetaGraphs

julia> using LightGraphs: Graph

julia> test = meta_graph(Graph(), AtVertex = Symbol);

julia> push!(test, :a); push!(test, :b);

julia> filter_vertices(test, isequal(:a))
1-element Array{Int64,1}:
 1
```
"""
filter_vertices(meta::MetaGraph, a_function::Function) =
    findall(a_function, meta.vertex_meta)

function copy_meta!(old_meta, new_meta, vertex_map)
    for (new_vertex, old_vertex) in enumerate(vertex_map)
        if haskey(old_meta, old_vertex)
            new_meta[new_vertex] = old_meta[old_vertex]
        end
    end
    for new_edge in edges(new_meta)
        in_vertex, out_vertex = Tuple(new_edge)
        old_edge = maybe_order_edge(old_meta,
            Edge(vertex_map[in_vertex], vertex_map[out_vertex])
        )
        if haskey(old_meta, old_edge)
            new_meta[new_edge] = old_meta[old_edge]
        end
    end
    return nothing
end

function induced_subgraph(meta::MetaGraph{Vertex}, vertices::AbstractVector{Vertex}) where {Vertex <: Integer}
    induced_graph, vertex_map =
        induced_subgraph(meta.inner_graph, vertices)
    induced_meta =
        MetaGraph(induced_graph,
            empty(meta.vertex_meta),
            empty(meta.edge_meta),
            meta.graph_meta,
            meta.weight_function,
            meta.default_weight
        )
    copy_meta!(meta, induced_meta, vertex_map)
    return induced_meta
end

# TODO - would be nice to be able to apply a function to properties. Not sure
# how this might work, but if the property is a vector, a generic way to append to
# it would be a good thing.

==(meta::MetaGraph, meta2::MetaGraph) =
    meta.inner_graph == meta2.inner_graph

copy(meta::MetaGraph) = deepcopy(meta)

include("overrides.jl")
include("persistence.jl")

end # module

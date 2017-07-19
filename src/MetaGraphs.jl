module MetaGraphs
using LightGraphs

import Base:
    eltype, show, ==, Pair, 
    Tuple, copy, length, size,
    start, next, done, issubset,
    zero, getindex

import LightGraphs:
    AbstractGraph, AbstractEdge, AbstractEdgeIter,
    src, dst, edgetype, nv,
    ne, vertices, edges, is_directed,
    add_vertex!, add_edge!, rem_vertex!, rem_edge!,
    has_vertex, has_edge, in_neighbors, out_neighbors,
    weights, indegree, outdegree, degree

import LightGraphs.SimpleGraphs:
    AbstractSimpleGraph, SimpleGraph, SimpleDiGraph,
    SimpleEdge, fadj, badj

export
    AbstractMetaGraph,
    MetaGraph,
    MetaDiGraph,
    weighttype,
    props,
    get_prop,
    set_props!,
    set_prop!,
    rem_prop!,
    has_prop,
    clear_props!,
    set_weightfield!

const PropDict = Dict{Symbol,Any}
abstract type AbstractMetaGraph <: AbstractGraph end

function show(io::IO, g::AbstractMetaGraph)
    dir = is_directed(g) ? "directed" : "undirected"
    if nv(g) == 0
        print(io, "empty $dir $(eltype(g)) metagraph with $(weighttype(g)) weights defined by :$(g.weightfield) (default weight $(g.defaultweight))")
    else
        print(io, "{$(nv(g)), $(ne(g))} $dir $(eltype(g)) metagraph with $(weighttype(g)) weights defined by :$(g.weightfield) (default weight $(g.defaultweight))")
    end
end

@inline fadj(g::AbstractMetaGraph, x...) = fadj(g.graph, x...)
@inline badj(g::AbstractMetaGraph, x...) = badj(g.graph, x...)


eltype(g::AbstractMetaGraph) = eltype(g.graph)
edgetype(g::AbstractMetaGraph) = edgetype(g.graph)
nv(g::AbstractMetaGraph) = nv(g.graph)
vertices(g::AbstractMetaGraph) = vertices(g.graph)

ne(g::AbstractMetaGraph) = ne(g.graph)
edges(g::AbstractMetaGraph) = edges(g.graph)

has_vertex(g::AbstractMetaGraph, x...) = has_vertex(g.graph, x...)
@inline has_edge(g::AbstractMetaGraph, x...) = has_edge(g.graph, x...)

in_neighbors(g::AbstractMetaGraph, v::Integer) = in_neighbors(g.graph, v)
out_neighbors(g::AbstractMetaGraph, v::Integer) = fadj(g.graph, v)

issubset(g::T, h::T) where T<:AbstractMetaGraph = issubset(g.graph, h.graph)

@inline add_edge!(g::AbstractMetaGraph, x...) = add_edge!(g.graph, x...)

@inline function rem_edge!(g::AbstractMetaGraph, x...)
    clear_props!(g, x...)
    rem_edge!(g.graph, x...)
end

add_vertex!(g::AbstractMetaGraph) = add_vertex!(g.graph)
function rem_vertex!(g::AbstractMetaGraph, v::Integer)
    clear_props!(g, v)
    rem_vertex!(g.graph, v)
end

struct MetaWeights{T<:Real} <: AbstractMatrix{T}
    n::Int
    weightfield::Symbol
    defaultweight::T
    eprops::Dict{AbstractEdge,PropDict}
end
show(io::IO, x::MetaWeights) = print(io, "metaweights")
show(io::IO, z::MIME"text/plain", x::MetaWeights) = show(io, x)

MetaWeights(g::AbstractMetaGraph) = MetaWeights{Float64}(nv(g), g.weightfield, g.defaultweight, g.eprops)

function getindex(w::MetaWeights, u::Integer, v::Integer)
    e = Edge(u, v)
    !haskey(w.eprops, e) && return w.defaultweight
    return get(w.eprops[e], w.weightfield, w.defaultweight)
end

size(d::MetaWeights) = (d.n, d.n)

weights(g::AbstractMetaGraph) = MetaWeights(g)

_hasdict(g::AbstractMetaGraph, v::Integer) = haskey(g.vprops, v)
_hasdict(g::AbstractMetaGraph, e::AbstractEdge) = haskey(g.eprops, e)

"""
    props(g)
    props(g, v)
    props(g, e)
    props(g, s, d)

Return a dictionary of all metadata from graph `g`, vertex `v`, or edge `e`
(optionally referenced by source vertex `s` and destination vertex `d`).
"""
props(g::AbstractMetaGraph) = g.gprops
props(g::AbstractMetaGraph, v::Integer) = get(g.vprops, v, PropDict())
# props for edges is dependent on directedness.
props(g::AbstractMetaGraph, u::Integer, v::Integer) = props(g, Edge(u, v))

"""
    get_prop(g, prop)
    get_prop(g, v, prop)
    get_prop(g, e, prop)
    get_prop(g, s, d, prop)

Return the property `prop` defined for graph `g`, vertex `v`, or edge `e`
(optionally referenced by source vertex `s` and destination vertex `d`).
If property is not defined, return an error.
"""
get_prop(g::AbstractMetaGraph, prop::Symbol) = props(g)[prop]
get_prop(g::AbstractMetaGraph, v::Integer, prop::Symbol) = props(g, v)[prop]
get_prop(g::AbstractMetaGraph, e::AbstractEdge, prop::Symbol) = props(g, e)[prop]

get_prop(g::AbstractMetaGraph, u::Integer, v::Integer, prop::Symbol) = get_prop(g, Edge(u, v), prop)

"""
    has_prop(g, prop)
    has_prop(g, v, prop)
    has_prop(g, e, prop)
    has_prop(g, s, d, prop)

Return true if the property `prop` is defined for graph `g`, vertex `v`, or
edge `e` (optionally referenced by source vertex `s` and destination vertex `d`).
"""
has_prop(g::AbstractMetaGraph, prop::Symbol) = haskey(g.gprops, prop)
has_prop(g::AbstractMetaGraph, v::Integer, prop::Symbol) = haskey(props(g, v), prop)
has_prop(g::AbstractMetaGraph, e::AbstractEdge, prop::Symbol) = haskey(props(g, e), prop)

has_prop(g::AbstractMetaGraph, u::Integer, v::Integer, prop::Symbol) = has_prop(g, Edge(u, v), prop)

"""
    set_props!(g, dict)
    set_props!(g, v, dict)
    set_props!(g, e, dict)
    set_props!(g, s, d, dict)

Bulk set (merge) properties contained in `dict` with graph `g`, vertex `v`, or
edge `e` (optionally referenced by source vertex `s` and destination vertex `d`).
"""
set_props!(g::AbstractMetaGraph, d::Dict) = merge!(g.gprops, d)
set_props!(g::AbstractMetaGraph, v::Integer, d::Dict) = 
    if !_hasdict(g, v)
        g.vprops[v] = d
    else
        merge!(g.vprops[v], d)
    end
# set_props!(g::AbstractMetaGraph, e::AbstractEdge, d::Dict) is dependent on directedness.

set_props!(g::AbstractMetaGraph, u::Integer, v::Integer, d::Dict) = set_props!(g, Edge(u, v), d)

"""
    set_prop!(g, prop, val)
    set_prop!(g, v, prop, val)
    set_prop!(g, e, prop, val)
    set_prop!(g, s, d, prop, val)

Set (replace) property `prop` with value `val` in graph `g`, vertex `v`, or
edge `e` (optionally referenced by source vertex `s` and destination vertex `d`).
"""
set_prop!(g::AbstractMetaGraph, prop::Symbol, val) = set_props!(g, Dict(prop => val))
set_prop!(g::AbstractMetaGraph, v::Integer, prop::Symbol, val) = set_props!(g, v, Dict(prop => val))
set_prop!(g::AbstractMetaGraph, e::AbstractEdge, prop::Symbol, val) = set_props!(g, e, Dict(prop => val))

set_prop!(g::AbstractMetaGraph, u::Integer, v::Integer, prop::Symbol, val) = set_prop!(g, Edge(u, v), prop, val)

"""
    rem_prop!(g, prop)
    rem_prop!(g, v, prop)
    rem_prop!(g, e, prop)
    rem_prop!(g, s, d, prop)

Remove property `prop` from graph `g`, vertex `v`, or edge `e`
(optionally referenced by source vertex `s` and destination vertex `d`).
If property does not exist, will not do anything.
"""

rem_prop!(g::AbstractMetaGraph, prop::Symbol) = delete!(g.gprops, prop)
rem_prop!(g::AbstractMetaGraph, v::Integer, prop::Symbol) = delete!(g.vprops[v], prop)
rem_prop!(g::AbstractMetaGraph, e::AbstractEdge, prop::Symbol) = delete!(g.eprops[e], prop)

rem_prop!(g::AbstractMetaGraph, u::Integer, v::Integer, prop::Symbol) = rem_prop!(g, Edge(u, v), prop)

"""
    clear_props!(g)
    clear_props!(g, v)
    clear_props!(g, e)
    clear_props!(g, s, d)

Remove all defined properties from graph `g`, vertex `v`, or edge `e`
(optionally referenced by source vertex `s` and destination vertex `d`).
"""
clear_props!(g::AbstractMetaGraph, v::Integer) = _hasdict(g, v) && (g.vprops[v] = PropDict())
clear_props!(g::AbstractMetaGraph, e::AbstractEdge) = _hasdict(g, e) && (g.eprops[e] = PropDict())
clear_props!(g::AbstractMetaGraph) = g.gprops = PropDict()

clear_props!(g::AbstractMetaGraph, u::Integer, v::Integer) = clear_props!(g, Edge(u, v))

"""
    set_weightfield!(g, prop)

Sets the field that contains weight information to `prop`.
"""
set_weightfield!(g::AbstractMetaGraph, prop::Symbol) = (g.weightfield = prop)

# TODO - would be nice to be able to apply a function to properties. Not sure
# how this might work, but if the property is a vector, a generic way to append to
# it would be a good thing.

==(x::AbstractMetaGraph, y::AbstractMetaGraph) = x.graph == y.graph

copy(g::T) where T <: AbstractMetaGraph = deepcopy(g)

include("metagraph.jl")
include("metadigraph.jl")
end # module

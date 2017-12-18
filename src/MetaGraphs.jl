module MetaGraphs
using LightGraphs
using JLD2
using DataFrames
import Base:
    eltype, show, ==, Pair,
    Tuple, copy, length, size,
    start, next, done, issubset,
    zero, getindex

import LightGraphs:
    AbstractGraph, src, dst, edgetype, nv,
    ne, vertices, edges, is_directed,
    add_vertex!, add_edge!, rem_vertex!, rem_edge!,
    has_vertex, has_edge, in_neighbors, out_neighbors,
    weights, indegree, outdegree, degree,
    induced_subgraph,
    loadgraph, savegraph, AbstractGraphFormat

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
    weightfield!,
    defaultweight!,
    weightfield,
    defaultweight,
    filter_edges,
    filter_vertices,
    MGFormat,
    metagraph_from_dataframe

const PropDict = Dict{Symbol,Any}
abstract type AbstractMetaGraph{T} <: AbstractGraph{T} end

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

"""
    add_edge!(g, u, v, s, val)
    add_edge!(g, u, v, d)

    Add an edge `(u, v)` to MetaGraph `g` with optional property `s` having value `val`,
    or properties given by an optional dictionary `d` mapping symbols to values.

    return true if the edge has been added, false otherwise
"""

@inline add_edge!(g::AbstractMetaGraph, x...) = add_edge!(g.graph, x...)
function add_edge!(g::AbstractMetaGraph, u::Integer, v::Integer, s::Symbol, val)
    add_edge!(g, u, v) || return false
    set_prop!(g, u, v, s, val)
    return true
end

function add_edge!(g::AbstractMetaGraph, u::Integer, v::Integer, d::Dict)
    add_edge!(g, u, v) || return false
    set_props!(g, u, v, d)
    return true
end

@inline function rem_edge!(g::AbstractMetaGraph, x...)
    clear_props!(g, x...)
    rem_edge!(g.graph, x...)
end

"""
    add_vertex!(g)
    add_vertex!(g, s, v)
    add_vertex!(g, d)

    Add a vertex to MetaGraph `g` with optional property `s` having value `v`,
    or properties given by an optional Dicitionary `d` mapping symbols to values.

    return true if the vertex has been added, false otherwise.
"""
add_vertex!(g::AbstractMetaGraph) = add_vertex!(g.graph)
function add_vertex!(g::AbstractMetaGraph,d::Dict)
    add_vertex!(g) || return false
    set_props!(g, nv(g), d)
    return true
end

function add_vertex!(g::AbstractMetaGraph, s::Symbol, v)
    add_vertex!(g) || return false
    set_prop!(g, nv(g), s, v)
    return true
end

function rem_vertex!(g::AbstractMetaGraph, v::Integer)
    lastprops = props(g, nv(g))
    clear_props!(g, v)
    delete!(g.vprops, nv(g))
    retval = rem_vertex!(g.graph, v)
    retval && set_props!(g, v, lastprops)
    return retval
end

struct MetaWeights{T<:Integer,U<:Real} <: AbstractMatrix{U}
    n::T
    weightfield::Symbol
    defaultweight::U
    eprops::Dict{SimpleEdge{T},PropDict}
end
show(io::IO, x::MetaWeights) = print(io, "metaweights")
show(io::IO, z::MIME"text/plain", x::MetaWeights) = show(io, x)

MetaWeights(g::AbstractMetaGraph) = MetaWeights{eltype(g),eltype(g.defaultweight)}(nv(g), g.weightfield, g.defaultweight, g.eprops)

function getindex(w::MetaWeights{T,U}, u::Integer, v::Integer)::U where T <: Integer where U <: Real
    e = Edge(u, v)
    !haskey(w.eprops, e) && return w.defaultweight
    return U(get(w.eprops[e], w.weightfield, w.defaultweight))
end

size(d::MetaWeights) = (d.n, d.n)

weights(g::AbstractMetaGraph) = MetaWeights(g)

_hasdict(g::AbstractMetaGraph, v::Integer) = haskey(g.vprops, v)
_hasdict(g::AbstractMetaGraph, e::SimpleEdge) = haskey(g.eprops, e)

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
get_prop(g::AbstractMetaGraph, e::SimpleEdge, prop::Symbol) = props(g, e)[prop]

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
has_prop(g::AbstractMetaGraph, e::SimpleEdge, prop::Symbol) = haskey(props(g, e), prop)

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
# set_props!(g::AbstractMetaGraph, e::SimpleEdge, d::Dict) is dependent on directedness.

set_props!(g::AbstractMetaGraph{T}, u::Integer, v::Integer, d::Dict) where T = set_props!(g, Edge(T(u), T(v)), d)

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
set_prop!(g::AbstractMetaGraph, e::SimpleEdge, prop::Symbol, val) = set_props!(g, e, Dict(prop => val))

set_prop!(g::AbstractMetaGraph{T}, u::Integer, v::Integer, prop::Symbol, val) where T = set_prop!(g, Edge(T(u), T(v)), prop, val)

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
rem_prop!(g::AbstractMetaGraph, e::SimpleEdge, prop::Symbol) = delete!(g.eprops[e], prop)

rem_prop!(g::AbstractMetaGraph{T}, u::Integer, v::Integer, prop::Symbol) where T = rem_prop!(g, Edge(T(u), T(v)), prop)

"""
    clear_props!(g)
    clear_props!(g, v)
    clear_props!(g, e)
    clear_props!(g, s, d)

Remove all defined properties from graph `g`, vertex `v`, or edge `e`
(optionally referenced by source vertex `s` and destination vertex `d`).
"""
clear_props!(g::AbstractMetaGraph, v::Integer) = _hasdict(g, v) && (g.vprops[v] = PropDict())
clear_props!(g::AbstractMetaGraph, e::SimpleEdge) = _hasdict(g, e) && (g.eprops[e] = PropDict())
clear_props!(g::AbstractMetaGraph) = g.gprops = PropDict()

clear_props!(g::AbstractMetaGraph{T}, u::Integer, v::Integer) where T = clear_props!(g, Edge(T(u), T(v)))

"""
    weightfield!(g, prop)

Set the field that contains weight information to `prop`.
"""
weightfield!(g::AbstractMetaGraph, prop::Symbol) = (g.weightfield = prop)

"""
    weightfield(g)

Return the field that contains weight information for metagraph `g`.
"""
weightfield(g::AbstractMetaGraph) = g.weightfield

"""
    defaultweight!(g, weight)

Set the default weight for metagraph `g`
"""
defaultweight!(g::AbstractMetaGraph, weight::Real) =
    g.defaultweight = weight
"""
    defaultweight(g)

Return the default weight for metagraph `g`.
"""
defaultweight(g::AbstractMetaGraph) = g.defaultweight

"""
    filter_edges(g, prop[, val])
    filter_edges(g, fn)

Return an iterator to all edges that have property `prop` defined (optionally
as `val`), or where function `fn` returns `true` only for edges that should be
included in the iterator.

`fn` should be of the form
```
fn(g::AbstractMetaGraph{T}, e::SimpleEdge{T})::Boolean
```
where `e` is replaced with the edge being evaluated.
"""
filter_edges(g::AbstractMetaGraph, fn::Function) =
    Iterators.filter(e -> fn(g, e), edges(g))

filter_edges(g::AbstractMetaGraph, prop::Symbol) =
    filter_edges(g, (g, e) -> has_prop(g, e, prop))

filter_edges(g::AbstractMetaGraph, prop::Symbol, val) =
    filter_edges(g, (g, e) -> has_prop(g, e, prop) && get_prop(g, e, prop) == val)

"""
    filter_vertices(g, prop[, val])
    filter_vertices(g, fn)

Return an iterator to all vertices that have property `prop` defined (optionally
as `val`), or where function `fn` returns `true` only for vertices that should be
included in the iterator.

`fn` should be of the form
```
fn(g::AbstractMetaGraph, v::Integer)::Boolean
```
where `v` is replaced with the vertex being evaluated.
"""
filter_vertices(g::AbstractMetaGraph, fn::Function) =
    Iterators.filter(x -> fn(g, x), vertices(g))

filter_vertices(g::AbstractMetaGraph, prop::Symbol) =
    filter_vertices(g, (g, x) -> has_prop(g, x, prop))

filter_vertices(g::AbstractMetaGraph, prop::Symbol, val) =
    filter_vertices(g, (g, x) -> has_prop(g, x, prop) && get_prop(g, x, prop) == val)

function _copy_props!(oldg::T, newg::T, vmap) where T <: AbstractMetaGraph
    for (newv, oldv) in enumerate(vmap)
        p = props(oldg, oldv)
        if !isempty(p)
            set_props!(newg, newv, p)
        end
    end
    for newe in edges(newg)
        u, v = Tuple(newe)
        olde = Edge(vmap[u], vmap[v])
        if !is_directed(oldg) && !is_ordered(olde)
            olde = reverse(olde)
        end
        p = props(oldg, olde)
        if !isempty(p)
            set_props!(newg, newe, p)
        end
    end
    if !isempty(oldg.gprops)
        set_props!(newg, oldg.gprops)
    end
    defaultweight!(newg, defaultweight(oldg))
    weightfield!(newg, weightfield(oldg))
    return nothing
end

function induced_subgraph(g::T, v::AbstractVector{U}) where T <: AbstractMetaGraph where U <: Integer
    inducedgraph, vmap = induced_subgraph(g.graph, v)
    newg = T(inducedgraph)
    _copy_props!(g, newg, vmap)
    return newg, vmap
end

function induced_subgraph(g::T, v::AbstractVector{U}) where T <: AbstractMetaGraph where U <: SimpleEdge
    inducedgraph, vmap = induced_subgraph(g.graph, v)
    newg = T(inducedgraph)
    _copy_props!(g, newg, vmap)
    return newg, vmap
end

induced_subgraph(g::T, filt::Iterators.Filter) where T <: AbstractMetaGraph =
    induced_subgraph(g, collect(filt))

# TODO - would be nice to be able to apply a function to properties. Not sure
# how this might work, but if the property is a vector, a generic way to append to
# it would be a good thing.

==(x::AbstractMetaGraph, y::AbstractMetaGraph) = x.graph == y.graph

copy(g::T) where T <: AbstractMetaGraph = deepcopy(g)

include("metagraph.jl")
include("metadigraph.jl")
include("persistence.jl")

function metagraph_from_dataframe(
    df::DataFrame,
    origin::Symbol,
    destination::Symbol,
    graph_type::Union{Type{MetaDiGraph}, Type{MetaGraph}}=MetaGraph;
    weight::Symbol=Symbol(),
    edge_attributes::Union{Vector{Symbol}, Symbol}=Vector{Symbol}())

    """
        metagraph_from_dataframe(df, origin, destination, graph_type)
        metagraph_from_dataframe(df, origin, destination, graph_type,
                                 weight, edge_addributes)

    Creates a MetaGraph from a DataFrame and stores node names as properties.

    `df` is DataFrame formatted as an edgelist
    `origin` is column symbol for origin of each edge
    `destination` is column symbol for destination of each edge
    `graph_type` is either `MetaGraph` or `MetaDiGraph`

    Will create a MetaGraph with a `name` property that stores node labels
    used in `origin` and `destination`.

    Optional keyword arguments:

    `weight` is column symbol to be used to set weight property.
    `edge_attributes` is a `Symbol` of `Vector{Symbol}` of columns whose values
    will be added as edge properties.
    """

    # Map node names to vertex IDs
    nodes = [df[origin]; df[destination]]
    nodes = unique(nodes)
    sort!(nodes)

    vertex_names = DataFrame(Dict(:name => nodes))
    vertex_names[:vertex_id] = 1:nrow(vertex_names)

    # Merge in to original
    for c in [origin, destination]
        temp = rename(vertex_names, :vertex_id => Symbol(c, :_id), :name => c)
        df = join(df, temp, on=c)
    end

    # Create Graph
    mg = graph_type(nrow(vertex_names))
    for r in eachrow(df)
        add_edge!(mg, r[Symbol(origin, :_id)], r[Symbol(destination, :_id)])
    end

    # Set vertex names
    for r in eachrow(vertex_names)
        set_prop!(mg, r[:vertex_id], :name, r[:name])
    end


    # Set edge attributes
    if typeof(edge_attributes) == Symbol
        edge_attributes = Vector{Symbol}([edge_attributes])
    end

    origin_id = Symbol(start, :_id)
    destination_id = Symbol(destination, :_id)

    for e in edge_attributes
        for r in eachrow(df)
            set_prop!(mg, Edge(r[origin_id], r[destination_id]), e, r[e])
        end
    end

    # Weight
    if weight != Symbol()
        for r in eachrow(df)
            set_prop!(mg, Edge(r[origin_id], r[destination_id]), :weight, r[weight])
        end
    end

    return mg
end

end # module

module MetaGraphs
using LightGraphs
using JLD2

import Base:
    eltype, show, ==, Pair,
    Tuple, copy, length, size,
    issubset, zero, getindex
import Random:
    randstring, seed!

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
    DOTFormat,
    set_indexing_prop!,
    reverse

const PropDict = Dict{Symbol,Any}
const MetaDict = Dict{Symbol,Dict{Any,Integer}}

abstract type AbstractMetaGraph{T} <: AbstractGraph{T} end

function show(io::IO, g::AbstractMetaGraph)
    dir = is_directed(g) ? "directed" : "undirected"
    print(io, "{$(nv(g)), $(ne(g))} $dir $(eltype(g)) metagraph with $(weighttype(g)) weights defined by :$(g.weightfield) (default weight $(g.defaultweight))")
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

inneighbors(g::AbstractMetaGraph, v::Integer) = inneighbors(g.graph, v)
outneighbors(g::AbstractMetaGraph, v::Integer) = fadj(g.graph, v)

issubset(g::T, h::T) where T <: AbstractMetaGraph = issubset(g.graph, h.graph)

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
function add_vertex!(g::AbstractMetaGraph, d::Dict)
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
    v in vertices(g) || return false
    lastv = nv(g)
    lastvprops = props(g, lastv)

    lasteoutprops = Dict(n => props(g, lastv, n) for n in outneighbors(g, lastv))
    lasteinprops = Dict(n => props(g, n, lastv) for n in inneighbors(g, lastv))
    for ind in g.indices
        if haskey(props(g,lastv),ind)
            pop!(g.metaindex[ind], get_prop(g, lastv, ind))
        end
        if haskey(props(g,v),ind)
            v != lastv && pop!(g.metaindex[ind], get_prop(g, v, ind))
        end
    end
    clear_props!(g, v)
    for n in outneighbors(g, lastv)
        clear_props!(g, lastv, n)
    end

    for n in inneighbors(g, lastv)
        clear_props!(g, n, lastv)
    end
    if v != lastv # ignore if we're removing the last vertex.
        for n in outneighbors(g, v)
            clear_props!(g, v, n)
        end
        for n in inneighbors(g, v)
            clear_props!(g, n, v)
        end
    end
    clear_props!(g, lastv)
    retval = rem_vertex!(g.graph, v)
    retval || return false
    if v != lastv # ignore if we're removing the last vertex.
        for (key, val) in lastvprops
            if key in g.indices
                set_indexing_prop!(g, v, key, val)
            else
                set_prop!(g, v, key, val)
            end
        end
        for n in outneighbors(g, v)
            set_props!(g, v, n, lasteoutprops[n])
        end

        for n in inneighbors(g, v)
            set_props!(g, n, v, lasteinprops[n])
        end
    end
    return true
end

struct MetaWeights{T <: Integer,U <: Real} <: AbstractMatrix{U}
    n::T
    weightfield::Symbol
    defaultweight::U
    eprops::Dict{SimpleEdge{T},PropDict}
    directed::Bool
end
show(io::IO, x::MetaWeights) = print(io, "metaweights")
show(io::IO, z::MIME"text/plain", x::MetaWeights) = show(io, x)

MetaWeights(g::AbstractMetaGraph) = MetaWeights{eltype(g),eltype(g.defaultweight)}(nv(g), g.weightfield, g.defaultweight, g.eprops, is_directed(g))

function getindex(w::MetaWeights{T,U}, u::Integer, v::Integer)::U where T <: Integer where U <: Real
    _e = Edge(u, v)
    e = !w.directed && !LightGraphs.is_ordered(_e) ? reverse(_e) : _e
    !haskey(w.eprops, e) && return w.defaultweight
    return U(get(w.eprops[e], w.weightfield, w.defaultweight))
end

function getindex(g::AbstractMetaGraph, prop::Symbol)
    !haskey(g.metaindex, prop) && error("':$prop' is not an index")
    return g.metaindex[prop]
end

function getindex(g::AbstractMetaGraph, indx::Any, prop::Symbol)
    haskey(g.metaindex, prop) || error("':$prop' is not an index")
    typeof(indx) <: eltype(keys(g.metaindex[prop])) || error("Index type does not match keys of metaindex '$prop'")
    !haskey(g.metaindex[prop], indx) && error("No node with prop $prop and key $indx")
    return g.metaindex[prop][indx]
end

function getindex(g::AbstractMetaGraph, indx::Integer, prop::Symbol)
    haskey(g.metaindex, prop) || error("':$prop' is not an index")
    return props(g, indx)[prop]
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
Will return false if vertex or edge does not exist.
"""
function set_props!(g::AbstractMetaGraph, d::Dict)
    merge!(g.gprops, d)
    return true
end

function set_props!(g::AbstractMetaGraph, v::Integer, d::Dict)
    if has_vertex(g, v)
        if length(intersect(keys(d), g.indices)) != 0
            error("The following properties are indexing_props and cannot be updated: $(intersect(keys(d), g.indices))")
        elseif !_hasdict(g, v)
            g.vprops[v] = d
        else
            merge!(g.vprops[v], d)
        end
        return true
    end
    return false
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
Will return false if vertex or edge does not exist, true otherwise.
"""
set_prop!(g::AbstractMetaGraph, prop::Symbol, val) = set_props!(g, Dict(prop => val))
set_prop!(g::AbstractMetaGraph, v::Integer, prop::Symbol, val) = begin
    if in(prop, g.indices)
        set_indexing_prop!(g, v, prop, val)
    else
        set_props!(g, v, Dict(prop => val))
    end
end
set_prop!(g::AbstractMetaGraph, e::SimpleEdge, prop::Symbol, val) = set_props!(g, e, Dict(prop => val))

set_prop!(g::AbstractMetaGraph{T}, u::Integer, v::Integer, prop::Symbol, val) where T = set_prop!(g, Edge(T(u), T(v)), prop, val)

"""
    rem_prop!(g, prop)
    rem_prop!(g, v, prop)
    rem_prop!(g, e, prop)
    rem_prop!(g, s, d, prop)

Remove property `prop` from graph `g`, vertex `v`, or edge `e`
(optionally referenced by source vertex `s` and destination vertex `d`).
If property, vertex, or edge does not exist, will not do anything.
"""
rem_prop!(g::AbstractMetaGraph, prop::Symbol) = delete!(g.gprops, prop)
rem_prop!(g::AbstractMetaGraph, v::Integer, prop::Symbol) = delete!(g.vprops[v], prop)
rem_prop!(g::AbstractMetaGraph, e::SimpleEdge, prop::Symbol) = delete!(g.eprops[e], prop)

rem_prop!(g::AbstractMetaGraph{T}, u::Integer, v::Integer, prop::Symbol) where T = rem_prop!(g, Edge(T(u), T(v)), prop)

"""
    default_index_value(v, prop, index_values; exclude=nothing)

Provides a default index value for a vertex if no value currently exists. The default is a string: "\$prop\$i" where `prop` is the property name and `i` is the vertex number. If some other vertex already has this name, a randomized string is generated (though the way it is generated is deterministic).
"""
function default_index_value(v::Integer, prop::Symbol, index_values::Set{Any}; exclude=nothing)
    val = string(prop) * string(v)
    if in(val, index_values) || val == exclude
        seed!(v + hash(prop))
        val = randstring()
        @warn("'$(string(prop))$v' is already in index, setting ':$prop' for vertex $v to $val")
    end
    return val
end

"""
    set_indexing_prop!(g, prop)
    set_indexing_prop!(g, v, prop, val)

Make property `prop` into an indexing property. If any values for this property
are already set, each vertex must have unique values. Optionally, set the index
`val` for vertex `v`. Any vertices without values will be set to a default
("(prop)(v)").
"""
function set_indexing_prop!(g::AbstractMetaGraph, prop::Symbol; exclude=nothing)
    in(prop, g.indices) && return g.indices
    index_values = [g.vprops[v][prop] for v in keys(g.vprops) if haskey(g.vprops[v], prop)]
    length(index_values) != length(union(index_values)) && error("Cannot make $prop an index, duplicate values detected")
    index_values = Set(index_values)

    g.metaindex[prop] = Dict{Any,Integer}()
    for v in vertices(g)
        if !haskey(g.vprops, v) || !haskey(g.vprops[v], prop)
            val = default_index_value(v, prop, index_values, exclude=exclude)
            set_prop!(g, v, prop, val)
        end
        g.metaindex[prop][g.vprops[v][prop]] = v
    end
    push!(g.indices, prop)
    return g.indices
end

function set_indexing_prop!(g::AbstractMetaGraph, v::Integer, prop::Symbol, val::Any)
    !in(prop, g.indices) && set_indexing_prop!(g, prop, exclude=val)
    (haskey(g.metaindex[prop], val) && haskey(g.vprops, v) && haskey(g.vprops[v], prop) && g.vprops[v][prop] == val) && return g.indices
    haskey(g.metaindex[prop], val) && error("':$prop' index already contains $val")

    if !haskey(g.vprops, v)
        push!(g.vprops, v=>Dict{Symbol,Any}())
    end
    if haskey(g.vprops[v], prop)
        delete!(g.metaindex[prop], g.vprops[v][prop])
    end
    g.metaindex[prop][val] = v
    g.vprops[v][prop] = val
    return g.indices
end
"""
    clear_props!(g)
    clear_props!(g, v)
    clear_props!(g, e)
    clear_props!(g, s, d)

Remove all defined properties from graph `g`, vertex `v`, or edge `e`
(optionally referenced by source vertex `s` and destination vertex `d`).
"""
clear_props!(g::AbstractMetaGraph, v::Integer) = _hasdict(g, v) && delete!(g.vprops, v)
clear_props!(g::AbstractMetaGraph, e::SimpleEdge) = _hasdict(g, e) && delete!(g.eprops, e)
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

include("metadigraph.jl")
include("metagraph.jl")
include("persistence.jl")
include("overrides.jl")
end # module

mutable struct MetaGraph{T <: Integer,U <: Real} <: AbstractMetaGraph{T}
    graph::SimpleGraph{T}
    vprops::Dict{T,PropDict}
    eprops::Dict{SimpleEdge{T},PropDict}
    gprops::PropDict
    weightfield::Symbol
    defaultweight::U
    metaindex::MetaDict
    indices::Set{Symbol}
end

function MetaGraph(x, weightfield::Symbol, defaultweight::U) where U <: Real
    T = eltype(x)
    g = SimpleGraph(x)
    vprops = Dict{T,PropDict}()
    eprops = Dict{SimpleEdge{T},PropDict}()
    gprops = PropDict()
    metaindex = MetaDict()
    idxs = Set{Symbol}()
    MetaGraph(g, vprops, eprops, gprops, weightfield, defaultweight, metaindex, idxs)
end

MetaGraph() = MetaGraph(SimpleGraph())
MetaGraph{T,U}() where T <: Integer where U <: Real = MetaGraph(SimpleGraph{T}(), one(U))
MetaGraph{T,U}(x::Integer) where T <: Integer where U <: Real = MetaGraph(T(x), :weight, U(1.0))
MetaGraph(x) = MetaGraph(x, :weight, 1.0)
MetaGraph(x, weightfield::Symbol) = MetaGraph(x, weightfield, 1.0)
MetaGraph(x, defaultweight::Real) = MetaGraph(x, :weight, defaultweight)

# converts MetaGraph{Int, Float64} to MetaGraph{UInt8, Float32}
function MetaGraph{T,U}(g::MetaGraph) where T <: Integer where U <: Real
    newg = SimpleGraph{T}(g.graph)
    return MetaGraph(newg, U(g.defaultweight))
end

function MetaGraph{T,U}(g::SimpleGraph, weightfield::Symbol=:weight, defaultweight::Real=1.0) where T <: Integer where U <: Real
    newg = SimpleGraph{T}(g)
    return MetaGraph(newg, weightfield, U(defaultweight))
end

function MetaGraph{T,U}(g::SimpleGraph, defaultweight::Real) where T <: Integer where U <: Real
    newg = SimpleGraph{T}(g)
    return MetaGraph(newg, :weight, U(defaultweight))
end

function MetaGraph(g::MetaDiGraph{T,U}) where T <: Integer where U <: Real
    return MetaGraph(Graph(g.graph), deepcopy(g.vprops), deepcopy(g.eprops), deepcopy(g.gprops), g.weightfield, g.defaultweight, deepcopy(g.metaindex), deepcopy(g.indices))
end

SimpleGraph(g::MetaGraph) = g.graph

is_directed(::Type{MetaGraph}) = false
is_directed(::Type{MetaGraph{T,U}}) where T where U = false
is_directed(g::MetaGraph) = false

weighttype(g::MetaGraph{T,U}) where T where U = U
function props(g::MetaGraph, _e::SimpleEdge)
    e = LightGraphs.is_ordered(_e) ? _e : reverse(_e)
    get(g.eprops, e, PropDict())
end

function set_props!(g::MetaGraph, _e::SimpleEdge, d::Dict)
    e = LightGraphs.is_ordered(_e) ? _e : reverse(_e)
    if has_edge(g, e)
        if !_hasdict(g, e)
            g.eprops[e] = d
        else
            merge!(g.eprops[e], d)
        end
        return true
    end
    return false
end

zero(g::MetaGraph{T,U}) where T where U = MetaGraph{T,U}(SimpleGraph{T}())

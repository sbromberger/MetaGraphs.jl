mutable struct MetaDiGraph{T<:Integer,U<:Real} <: AbstractMetaGraph
    graph::SimpleDiGraph{T}
    vprops::Dict{T,PropDict}
    eprops::Dict{SimpleEdge{T},PropDict}
    gprops::PropDict
    weightfield::Symbol
    defaultweight::U
end

function MetaDiGraph(x, weightfield::Symbol, defaultweight::U) where U <: Real
    T = eltype(x)
    g = SimpleDiGraph(x)
    vprops = Dict{T,PropDict}()
    eprops = Dict{SimpleEdge{T},PropDict}()
    gprops = PropDict()

    MetaDiGraph(g, vprops, eprops, gprops, weightfield, defaultweight)
end

MetaDiGraph() = MetaDiGraph(SimpleDiGraph())
MetaDiGraph{T,U}() where T <: Integer where U <: Real = MetaDiGraph(SimpleDiGraph{T}(), one(U))
MetaDiGraph{T,U}(x::Integer) where T <: Integer where U <: Real = MetaDiGraph(T(x), :weight, U(1.0))
MetaDiGraph(x) = MetaDiGraph(x, :weight, 1.0)
MetaDiGraph(x, weightfield::Symbol) = MetaDiGraph(x, weightfield, 1.0)
MetaDiGraph(x, defaultweight::Real) = MetaDiGraph(x, :weight, defaultweight)

# converts MetaDiGraph{Int,Float64} to MetaDiGraph{UInt8, Float32}
function (::Type{MetaDiGraph{T,U}})(g::MetaDiGraph) where T<:Integer where U<:Real
    newg = SimpleDiGraph{T}(g.graph)
    return MetaDiGraph(newg, U(g.defaultweight))
end

function (::Type{MetaDiGraph{T,U}})(g::SimpleDiGraph, weightfield::Symbol=:weight, defaultweight::Real=1.0) where T<:Integer where U<:Real
    newg = SimpleDiGraph{T}(g)
    return MetaDiGraph(newg, weightfield, U(defaultweight))
end

function (::Type{MetaDiGraph{T,U}})(g::SimpleDiGraph, defaultweight::Real) where T<:Integer where U<:Real
    newg = SimpleDiGraph{T}(g)
    return MetaDiGraph(newg, :weight, U(defaultweight))
end


SimpleDiGraph(g::MetaDiGraph) = g.graph


is_directed(::Type{MetaDiGraph}) = true
is_directed(::Type{MetaDiGraph{T,U}}) where T where U = true
is_directed(g::MetaDiGraph) = true

weighttype(g::MetaDiGraph{T,U}) where T where U = U

props(g::MetaDiGraph, e::SimpleEdge) = get(g.eprops, e, PropDict())

function set_props!(g::MetaDiGraph, e::SimpleEdge, d::Dict)
    if !_hasdict(g, e)
        g.eprops[e] = d
    else
        merge!(g.eprops[e], d)
    end
end

zero(g::MetaDiGraph{T,U}) where T where U = MetaDiGraph{T,U}(SimpleDiGraph{T}())
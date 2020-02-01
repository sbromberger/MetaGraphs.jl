struct MetaDiGraph{Vertex, InnerGraph, AtVertex, AtEdge, GraphMeta, WeightFunction, Weight} <: AbstractMetaGraph{Vertex, InnerGraph, AtVertex, AtEdge, GraphMeta, WeightFunction, Weight}
    inner_graph::InnerGraph
    vertex_meta::Dict{Vertex, AtVertex}
    edge_meta::Dict{Edge{Vertex}, AtEdge}
    graph_meta::GraphMeta
    weight_function::WeightFunction
    default_weight::Weight
end

function meta_graph(inner_graph::DiGraph{Vertex};
    AtVertex = Nothing,
    AtEdge = Nothing,
    graph_meta = nothing,
    weight_function = edge_meta -> 1.0,
    default_weight = 1.0
) where {Vertex}
    MetaDiGraph(
        inner_graph,
        Dict{Vertex, AtVertex}(),
        Dict{Edge{Vertex}, AtEdge}(),
        graph_meta,
        weight_function,
        default_weight
    )
end

SimpleDiGraph(g::MetaDiGraph) = g.inner_graph

is_directed(::Type{<: MetaDiGraph}) = true

maybe_order_edge(::MetaDiGraph, edge) = edge

function reverse(meta::MetaGraph{<: Any, <: DiGraph})
    return MetaGraph(reverse(meta.inner_graph),
        meta.vertex_meta,
        Dict(reverse(edge) => value for (edge, value) in meta.edge_meta),
        meta.graph_meta,
        meta.weight_function,
        meta.default_weight
    )
end

module MetaGraphs

import Base: getindex, delete!, haskey, push!, reverse, setindex!
import LightGraphs: induced_subgraph, vertices
using LightGraphs: AbstractEdge, AbstractGraph, add_edge!, add_vertex!, Edge, edges, inneighbors, is_directed, is_ordered, nv, outneighbors, rem_edge!, rem_vertex!

struct MetaGraph{Vertex, Graph, AtVertex, AtEdge}
    graph::Graph
    vertex_meta::Dict{Vertex, AtVertex}
    edge_meta::Dict{Edge{Vertex}, AtEdge}
end

function MetaGraph(graph::AbstractGraph{Vertex};
    vertex_meta::Dict{Vertex, AtVertex} = Dict{Vertex, Nothing}(),
    edge_meta::Dict{Edge{Vertex}, AtEdge} = Dict{Edge{Vertex}, Nothing}()
) where {Vertex, AtVertex, AtEdge}
    MetaGraph{Vertex, typeof(graph), AtVertex, AtEdge}(graph, vertex_meta, edge_meta)
end

vertices(meta::MetaGraph) = vertices(meta.graph)

function meta_graph(graph::AbstractGraph{Vertex}; AtVertex = Nothing, AtEdge = Nothing) where {Vertex}
    MetaGraph(graph,
        vertex_meta = Dict{Vertex, AtVertex}(),
        edge_meta = Dict{Edge{Vertex}, AtEdge}()
    )
end

export meta_graph

function make_edge(graph, edge)
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
    had_it = add_edge!(meta.graph, edge)
    meta.edge_meta[make_edge(meta.graph, edge)] = value
    nothing
end

function delete_meta!(meta, edge::AbstractEdge)
    edge_meta = meta.edge_meta
    fixed_edge = make_edge(meta.graph, edge)
    delete!(edge_meta, fixed_edge)
    nothing
end

function delete!(meta::MetaGraph, edge::AbstractEdge)
    delete_meta!(meta, edge)
    rem_edge!(meta.graph, edge)
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
    graph = meta.graph
    vertex_meta = meta.vertex_meta
    if haskey(vertex_meta, vertex)
        delete!(vertex_meta, vertex)
    end
    for out_neighbor in outneighbors(graph, vertex)
        delete_meta!(meta, Edge(vertex, out_neighbor))
    end
    for in_neighbor in inneighbors(graph, vertex)
        delete_meta!(meta, Edge(in_neighbor, vertex))
    end
    nothing
end

function move_meta!(meta, old_edge::AbstractEdge, new_edge::AbstractEdge)
    graph = meta.graph
    edge_meta = meta.edge_meta
    if haskey(edge_meta, old_edge)
        edge_meta[make_edge(graph, new_edge)] = pop!(edge_meta, old_edge)
    end
    nothing
end

function move_meta!(meta, old_vertex::Integer, new_vertex::Integer)
    graph = meta.graph
    vertex_meta = meta.vertex_meta
    if haskey(vertex_meta, old_vertex)
        vertex_meta[new_vertex] = pop!(vertex_meta, old_vertex)
    end
    for out_neighbor in outneighbors(graph, old_vertex)
        move_meta!(meta,
            Edge(old_vertex, out_neighbor),
            Edge(new_vertex, out_neighbor)
        )
    end
    for in_neighbor in inneighbors(graph, old_vertex)
        move_meta!(meta,
            Edge(in_neighbor, old_vertex),
            Edge(in_neighbor, new_vertex)
        )
    end
    nothing
end

function delete!(meta::MetaGraph, vertex::Integer)
    graph = meta.graph
    vertex_meta = meta.vertex_meta
    if vertex in vertices(graph)
        last_vertex = nv(graph)
        delete_meta!(meta, vertex)
        if vertex != last_vertex
            move_meta!(meta, last_vertex, vertex)
        end
        rem_vertex!(graph, vertex)
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
    for new_edge in edges(new_meta.graph)
        old_edge = make_edge(old_meta.graph, Edge(
            vertex_map[new_edge.src],
            vertex_map[new_edge.dst]
        ))
        if haskey(old_edges, old_edge)
            new_edges[new_edge] = old_edges[old_edge]
        end
    end
    nothing
end

function induced_subgraph(old_meta::MetaGraph, vertices)
    old_graph = old_meta.graph
    new_graph, vertex_map = induced_subgraph(old_graph, vertices)
    new_meta =
        MetaGraph(new_graph,
            vertex_meta = empty(old_meta.vertex_meta),
            edge_meta = empty(old_meta.edge_meta)
        )
    copy_meta!(old_meta, new_meta, vertex_map)
    new_meta
end

function reverse_edge(graph, pair)
    make_edge(graph, reverse(pair.first)) => pair.second
end

function reverse(meta::MetaGraph)
    graph = meta.graph
    MetaGraph(reverse(graph),
        vertex_meta = meta.vertex_meta,
        edge_meta = Dict(reverse_edge(graph, pair) for pair in meta.edge_meta)
    )
end

function push!(dependencies::MetaGraph, value)
    graph = dependencies.graph
    maybe = findfirst(isequal(value), dependencies.vertex_meta)
    if maybe === nothing
        add_vertex!(graph)
        new_vertex = nv(graph)
        dependencies[new_vertex] = value
        new_vertex
    else
        maybe
    end
end

end # module

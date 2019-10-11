module MetaGraphs

import Base: push!, delete!, reverse
import LightGraphs: induced_subgraph
using LightGraphs: AbstractEdge, AbstractGraph, add_edge!, add_vertex!, edges, inneighbors, is_directed, is_ordered, nv, outneighbors, rem_edge!, rem_vertex!, SimpleEdge, vertices

export MetaGraph, meta_graph

struct MetaGraph{Vertex, Graph, AtVertex, AtEdge}
    graph::Graph
    vertex_meta::Dict{Vertex, AtVertex}
    edge_meta::Dict{SimpleEdge{Vertex}, AtEdge}
end

function MetaGraph(graph::AbstractGraph{Vertex};
    vertex_meta::Dict{Vertex, AtVertex} = Dict{Vertex, Nothing}(),
    edge_meta::Dict{SimpleEdge{Vertex}, AtEdge} = Dict{SimpleEdge{Vertex}, Nothing}()
) where {Vertex, AtVertex, AtEdge}
    MetaGraph{Vertex, typeof(graph), AtVertex, AtEdge}(graph, vertex_meta, edge_meta)
end

function meta_graph(graph::AbstractGraph{Vertex}; AtVertex = Nothing, AtEdge = Nothing) where {Vertex}
    MetaGraph(graph,
        vertex_meta = Dict{Vertex, AtVertex}(),
        edge_meta = Dict{SimpleEdge{Vertex}, AtEdge}()
    )
end

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

"""
    push!(meta::MetaGraph, value)
    push!(meta::MetaGraph, edge, value)

    Add a vertex or an `edge` with metadata `value`. Return true if added, false
    otherwise
"""
function push!(meta::MetaGraph, edge, value)
    had_it = add_edge!(meta.graph, edge)
    if had_it
        meta.edge_meta[make_edge(meta.graph, edge)] = value
    end
    had_it
end

function delete_meta!(meta, edge::AbstractEdge)
    edge_meta = meta.edge_meta
    fixed_edge = make_edge(meta.graph, edge)
    if haskey(edge_meta, fixed_edge)
        delete!(edge_meta, fixed_edge)
    end
end

function delete!(meta::MetaGraph, edge::AbstractEdge)
    graph = meta.graph
    delete_meta!(meta, edge)
    rem_edge!(graph, edge)
end

function push!(meta::MetaGraph, value)
    graph = meta.graph
    had_it = add_vertex!(graph)
    if had_it
        meta.vertex_meta[nv(graph)] = value
    end
    had_it
end

function delete_meta!(meta, vertex::Integer)
    graph = meta.graph
    vertex_meta = meta.vertex_meta
    if haskey(vertex_meta, vertex)
        delete!(vertex_meta, vertex)
    end
    for out_neighbor in outneighbors(graph, vertex)
        delete_meta!(meta, SimpleEdge(vertex, out_neighbor))
    end
    for in_neighbor in inneighbors(graph, vertex)
        delete_meta!(meta, SimpleEdge(in_neighbor, vertex))
    end
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
            SimpleEdge(old_vertex, out_neighbor),
            SimpleEdge(new_vertex, out_neighbor)
        )
    end
    for in_neighbor in inneighbors(graph, old_vertex)
        move_meta!(meta,
            SimpleEdge(in_neighbor, old_vertex),
            SimpleEdge(in_neighbor, new_vertex)
        )
    end
    nothing
end

function delete!(meta::MetaGraph, vertex::Integer)
    graph = meta.graph
    vertex_meta = meta.vertex_meta
    had_it = vertex in vertices(graph)
    if had_it
        last_vertex = nv(graph)
        delete_meta!(meta, vertex)
        if vertex != last_vertex
            move_meta!(meta, last_vertex, vertex)
        end
        rem_vertex!(graph, vertex)
    end
    had_it
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
        old_edge = make_edge(old_meta.graph, SimpleEdge(
            vertex_map[new_edge.src],
            vertex_map[new_edge.dst]
        ))
        if haskey(old_edges, old_edge)
            new_edges[new_edge] = old_edges[old_edge]
        end
    end
    nothing
end

function induced_subgraph(old_meta::MetaGraph, vertex_meta)
    old_graph = old_meta.graph
    new_graph, vertex_map = induced_subgraph(old_graph, vertex_meta)
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

end # module

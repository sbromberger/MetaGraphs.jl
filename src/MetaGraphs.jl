module MetaGraphs

import Base: push!, delete!, reverse
import LightGraphs: induced_subgraph
using LightGraphs: AbstractEdge, AbstractGraph, add_edge!, add_vertex!, edges, inneighbors, is_directed, is_ordered, nv, outneighbors, rem_edge!, rem_vertex!, Edge, vertices

export MetaGraph, meta_graph

struct MetaGraph{Vertex, Graph, AtVertex, AtEdge}
    graph::Graph
    vertices::Dict{Vertex, AtVertex}
    edges::Dict{Edge{Vertex}, AtEdge}
end

function MetaGraph(graph::AbstractGraph{Vertex};
    vertices::Dict{Vertex, AtVertex} = Dict{Vertex, Nothing}(),
    edges::Dict{Edge{Vertex}, AtEdge} = Dict{Edge{Vertex}, Nothing}()
) where {Vertex, AtVertex, AtEdge}
    MetaGraph{Vertex, typeof(graph), AtVertex, AtEdge}(graph, vertices, edges)
end

function meta_graph(graph::AbstractGraph{Vertex}; AtVertex = Nothing, AtEdge = Nothing) where {Vertex}
    MetaGraph(graph,
        vertices = Dict{Vertex, AtVertex}(),
        edges = Dict{Edge{Vertex}, AtEdge}()
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
        meta.edges[make_edge(meta.graph, edge)] = value
    end
    had_it
end

function delete_meta!(meta, edge::AbstractEdge)
    edges = meta.edges
    fixed_edge = make_edge(meta.graph, edge)
    if haskey(edges, fixed_edge)
        delete!(edges, fixed_edge)
    end
end

function delete!(meta::MetaGraph, edge::AbstractEdge)
    graph = meta.graph
    edges = meta.edges
    delete_meta!(meta, edge)
    rem_edge!(graph, edge)
end

function push!(meta::MetaGraph, value)
    graph = meta.graph
    had_it = add_vertex!(graph)
    if had_it
        meta.vertices[nv(graph)] = value
    end
    had_it
end

function delete_meta!(meta, vertex::Integer)
    the_vertices = meta.vertices
    if haskey(the_vertices, vertex)
        delete!(the_vertices, vertex)
    end
end

function move!(meta, old_edge, new_edge)
    graph = meta.graph
    edges = meta.edges
    if haskey(edges, old_edge)
        edges[make_edge(graph, new_edge)] = pop!(edges, old_edge)
    end
end

function delete!(meta::MetaGraph, vertex::Integer)
    graph = meta.graph
    the_vertices = meta.vertices
    had_it = vertex in vertices(graph)
    if had_it
        last_vertex = nv(graph)
        delete_meta!(meta, vertex)
        for out_neighbor in outneighbors(graph, vertex)
            delete_meta!(meta, Edge(vertex, out_neighbor))
        end
        for in_neighbor in inneighbors(graph, vertex)
            delete_meta!(meta, Edge(in_neighbor, vertex))
        end
        if vertex != last_vertex
            # when we remove a vertex, the former last vertex will be reassigned in its place
            # so we need to move the metadata for the last vertex to the new vertex
            if haskey(the_vertices, last_vertex)
                the_vertices[vertex] = pop!(the_vertices, last_vertex)
            end
            for out_neighbor in outneighbors(graph, last_vertex)
                move!(meta,
                    Edge(last_vertex, out_neighbor),
                    Edge(vertex, out_neighbor)
                )
            end
            for in_neighbor in inneighbors(graph, last_vertex)
                move!(meta,
                    Edge(in_neighbor, last_vertex),
                    Edge(in_neighbor, vertex)
                )
            end
        end
        rem_vertex!(graph, vertex)
    end
    had_it
end

function induced_subgraph(old_meta::MetaGraph, vertices)
    old_graph = old_meta.graph
    new_graph, vertex_map = induced_subgraph(old_graph, vertices)
    old_vertices = old_meta.vertices
    old_edges = old_meta.edges
    new_vertices = empty(old_vertices)
    new_edges = empty(old_edges)
    for (new_vertex, old_vertex) in enumerate(vertex_map)
        if haskey(old_vertices, old_vertex)
            new_vertices[new_vertex] = old_vertices[old_vertex]
        end
    end
    for new_edge in edges(new_graph)
        old_edge = make_edge(old_graph, SimpleEdge(
            vertex_map[new_edge.src],
            vertex_map[new_edge.dst]
        ))
        if haskey(old_edges, old_edge)
            new_edges[new_edge] = old_edges[old_edge]
        end
    end
    MetaGraph(new_graph, vertices = new_vertices, edges = new_edges)
end

function reverse_edge(graph, pair)
    make_edge(graph, reverse(pair.first)) => pair.second
end

function reverse(meta::MetaGraph)
    graph = meta.graph
    MetaGraph(reverse(graph),
        vertices = meta.vertices,
        edges = Dict(reverse_edge(graph, pair) for pair in meta.edges)
    )
end

end # module

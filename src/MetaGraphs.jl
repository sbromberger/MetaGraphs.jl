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

function delete!(meta::MetaGraph, edge::AbstractEdge)
    graph = meta.graph
    delete!(meta.edges, make_edge(graph, edge))
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

function delete!(meta::MetaGraph, vertex::Integer)
    graph = meta.graph
    the_vertices = meta.vertices
    edges = meta.edges
    had_it = vertex in vertices(graph)
    if had_it
        last_vertex = nv(graph)
        delete!(the_vertices, vertex)
        for out_neighbor in outneighbors(graph, vertex)
            delete!(edges, Edge(vertex, out_neighbor))
        end
        for in_neighbor in inneighbors(graph, vertex)
            delete!(edges, Edge(in_neighbor, vertex))
        end
        if vertex != last_vertex
            # when we remove a vertex, the former last vertex will be reassigned in its place
            # so we need to move the metadata for the last vertex to the new vertex
            the_vertices[vertex] = pop!(the_vertices, last_vertex)
            for out_neighbor in outneighbors(graph, last_vertex)
                old_edge = Edge(last_vertex, out_neighbor)
                if haskey(edges, old_edge)
                    edges[make_edge(graph, Edge(vertex, out_neighbor))] =
                        pop!(edges, old_edge)
                end
            end
            for in_neighbor in inneighbors(graph, last_vertex)
                old_edge = Edge(in_neighbor, last_vertex)
                if haskey(edges, old_edge)
                    edges[make_edge(graph, Edge(in_neighbor, vertex))] =
                        pop!(edges, old_edge)
                end
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
        new_vertices[new_vertex] = old_vertices[old_vertex]
    end
    for new_edge in edges(new_graph)
        new_edges[new_edge] = old_edges[
            make_edge(old_graph, SimpleEdge(
                vertex_map[new_edge.src],
                vertex_map[new_edge.dst]
            ))
        ]
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

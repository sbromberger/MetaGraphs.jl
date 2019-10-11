using Test
using MetaGraphs
using LightGraphs: SimpleEdge, DiGraph, Graph, path_graph, path_digraph

@testset "MetaGraphs" begin
    meta = meta_graph(Graph(), AtVertex = String, AtEdge = String)
    push!(meta, "1")
    @test meta.vertices[nv(meta.graph)] == "1"
    push!(meta, "2")
    @test meta.vertices[nv(meta.graph)] == "2"
    push!(meta, SimpleEdge(1, 2), "1-2")
    @test meta.edges[SimpleEdge(1, 2)] == "1-2"
    delete!(meta, SimpleEdge(1, 2))
    @test !haskey(meta.edges, SimpleEdge(1, 2))
    push!(meta, "3")
    push!(meta, SimpleEdge(1, 3), "1-3")
    test = induced_subgraph(meta, [1, 3])
    @test test.vertices[1] == "1"
    @test test.vertices[2] == "3"
    @test test.edges[SimpleEdge(1, 2)] == "1-3"
    delete!(meta, 2)
    @test meta.vertices[1] == "1"
    @test meta.vertices[2] == "3"
    delete!(meta, 2)
    @test nv(meta.graph) == 1
    @test meta.vertices[1] == "1"

    directed = meta_graph(DiGraph(), AtVertex = String, AtEdge = String)
    push!(directed, "1")
    @test directed.vertices[nv(directed.graph)] == "1"
    push!(directed, "2")
    @test directed.vertices[nv(directed.graph)] == "2"
    push!(directed, SimpleEdge(1, 2), "1-2")
    reversed = reverse(directed)
    @test reversed.edges[SimpleEdge(2, 1)] == "1-2"
end

using Test
using MetaGraphs
using LightGraphs: DiGraph, Edge, Graph, induced_subgraph, nv, path_digraph, path_graph

@testset "MetaGraphs" begin
    meta = meta_graph(Graph(), AtVertex = String, AtEdge = String)
    push!(meta, "1")
    @test meta[1] == "1"
    @test push!(meta, "1") == 1
    @test push!(meta, "2") == 2
    @test meta[2] == "2"
    meta[Edge(1, 2)] = "1-2"
    @test meta[Edge(1, 2)] == "1-2"
    delete!(meta, Edge(1, 2))
    @test_throws KeyError meta[Edge(1, 2)]
    push!(meta, "3")
    meta[Edge(1, 3)] = "1-3"
    test = induced_subgraph(meta, [1, 3])
    @test test[1] == "1"
    @test test[2] == "3"
    @test test[Edge(1, 2)] == "1-3"
    delete!(meta, 2)
    @test meta[1] == "1"
    @test meta[2] == "3"
    delete!(meta, 2)
    @test nv(meta.graph) == 1
    @test meta[1] == "1"

    directed = meta_graph(DiGraph(), AtVertex = String, AtEdge = String)
    push!(directed, "1")
    @test directed[1] == "1"
    push!(directed, "2")
    @test directed[2] == "2"
    directed[Edge(1, 2)] = "1-2"
    reversed = reverse(directed)
    @test reversed[Edge(2, 1)] == "1-2"
end

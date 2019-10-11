using Test
using MetaGraphs
using LightGraphs: DiGraph, Graph, induced_subgraph, nv, path_digraph, path_graph, SimpleEdge

@testset "MetaGraphs" begin
    meta = meta_graph(Graph(), AtVertex = String, AtEdge = String)
    push!(meta, "1")
    @test meta.vertex_meta[nv(meta.graph)] == "1"
    push!(meta, "2")
    @test meta.vertex_meta[nv(meta.graph)] == "2"
    push!(meta, SimpleEdge(1, 2), "1-2")
    @test meta.edge_meta[SimpleEdge(1, 2)] == "1-2"
    delete!(meta, SimpleEdge(1, 2))
    @test !haskey(meta.edge_meta, SimpleEdge(1, 2))
    push!(meta, "3")
    push!(meta, SimpleEdge(1, 3), "1-3")
    test = induced_subgraph(meta, [1, 3])
    @test test.vertex_meta[1] == "1"
    @test test.vertex_meta[2] == "3"
    @test test.edge_meta[SimpleEdge(1, 2)] == "1-3"
    delete!(meta, 2)
    @test meta.vertex_meta[1] == "1"
    @test meta.vertex_meta[2] == "3"
    delete!(meta, 2)
    @test nv(meta.graph) == 1
    @test meta.vertex_meta[1] == "1"

    directed = meta_graph(DiGraph(), AtVertex = String, AtEdge = String)
    push!(directed, "1")
    @test directed.vertex_meta[nv(directed.graph)] == "1"
    push!(directed, "2")
    @test directed.vertex_meta[nv(directed.graph)] == "2"
    push!(directed, SimpleEdge(1, 2), "1-2")
    reversed = reverse(directed)
    @test reversed.edge_meta[SimpleEdge(2, 1)] == "1-2"
end

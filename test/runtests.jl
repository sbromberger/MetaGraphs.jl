using MetaGraphs
using LightGraphs
using LightGraphs.SimpleGraphs: fadj, badj
import Documenter: doctest
import Test: @testset, @test

doctest(MetaGraphs)

rock_paper_scissors = meta_graph(DiGraph(), AtVertex = Symbol, AtEdge = Symbol)
rock = push!(rock_paper_scissors, :rock)
paper = push!(rock_paper_scissors, :paper)
scissors = push!(rock_paper_scissors, :scissors)

rock_paper_scissors[Edge(rock, scissors)] = :rock_beats_scissors
rock_paper_scissors[Edge(scissors, paper)] = :scissors_beats_paper
rock_paper_scissors[Edge(paper, rock)] = :paper_beats_rock

rock_paper = induced_subgraph(rock_paper_scissors, [1, 2])

@testset "Miscellaneous" begin
    @test haskey(reverse(rock_paper_scissors), Edge(scissors, rock))
    @test nv(rock_paper) == 2
    @test ne(rock_paper) == 1
    @test haskey(rock_paper, Edge(paper, rock))
    @test SimpleGraph(meta_graph(Graph())) isa SimpleGraph
end

rock_paper_scissors_copy = copy(rock_paper_scissors)

@testset "Inheritance" begin
    @test rock_paper_scissors_copy == rock_paper_scissors
    @test nv(zero(rock_paper_scissors)) == 0
    @test ne(rock_paper_scissors) == 3
    @test fadj(rock_paper_scissors, rock) == [scissors]
    @test badj(rock_paper_scissors, rock) == [paper]
    @test typeof(rock) == eltype(rock_paper_scissors)
    @test edgetype(rock_paper_scissors) == Edge{Int}
    @test vertices(rock_paper_scissors) == Base.OneTo(3)
    @test weight_type(rock_paper_scissors) == Float64
    @test has_edge(rock_paper_scissors, Edge(rock, scissors))
    @test has_vertex(rock_paper_scissors, rock)
    @test issubset(rock_paper, rock_paper_scissors)
    @test SimpleDiGraph(rock_paper_scissors) isa SimpleDiGraph
    @test is_directed(rock_paper_scissors)
end

@testset "Double check deletion" begin
    delete!(rock_paper_scissors, rock)
    @test ne(rock_paper_scissors) == 1
    @test filter_edges(rock_paper_scissors, isequal(:scissors_beats_paper)) == [Edge(1, 2)]
    delete!(rock_paper_scissors_copy, paper)
    @test ne(rock_paper_scissors_copy) == 1
    @test filter_edges(rock_paper_scissors_copy, isequal(:rock_beats_scissors)) == [Edge(1, 2)]
    rem_edge!(rock_paper_scissors, Edge(1, 2))
    @test ne(rock_paper_scissors) == 0
    rem_vertex!(rock_paper_scissors, 2)
    @test nv(rock_paper_scissors) == 1
end

weighted_graph = meta_graph(DiGraph(), AtEdge = Float64, weight_function = identity)
push!(weighted_graph, nothing)
push!(weighted_graph, nothing)
push!(weighted_graph, nothing)
weighted_graph[Edge(1, 2)] = 1
weighted_graph[Edge(2, 3)] = 2
graph_weights = weights(weighted_graph)

@testset "Weights" begin
    @test string(graph_weights) == "metaweights"
    @test graph_weights[rock, paper] == 1.0
    @test size(graph_weights) == (3, 3)
end

undirected = meta_graph(Graph(),
    AtVertex = Nothing,
    AtEdge = Nothing
)
push!(undirected, nothing)
push!(undirected, nothing)
undirected[Edge(2, 1)] = nothing

@test !is_directed(undirected)
@test mktemp() do file, io
    savegraph(file, undirected, DOTFormat())
    read(file, String)
end == """
graph {
    1
    2
    1 -- 2
}
"""

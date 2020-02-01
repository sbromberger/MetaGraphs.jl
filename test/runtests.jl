using MetaGraphs
using LightGraphs
using LightGraphs.SimpleGraphs: fadj, badj
import Documenter: doctest
import Test: @testset, @test

doctest(MetaGraphs)

test = meta_graph(DiGraph(), AtVertex = Symbol, AtEdge = Symbol)
rock = push!(test, :rock)
scissors = push!(test, :scissors)
paper = push!(test, :paper)

test[Edge(rock, scissors)] = :rock_beats_scissors
test[Edge(scissors, paper)] = :scissors_beats_paper
test[Edge(paper, rock)] = :paper_beats_rock

test2 = induced_subgraph(test, [1, 2])

@testset "Miscellaneous" begin
    @test haskey(reverse(test), Edge(scissors, rock))
    @test nv(test2) == 2
    @test ne(test2) == 1
    @test haskey(test2, Edge(rock, scissors))
end

@testset "Inheritance" begin
    @test copy(test) == test
    @test nv(zero(test)) == 0
    @test ne(test) == 3
    @test fadj(test, rock) == [scissors]
    @test badj(test, rock) == [paper]
    @test typeof(rock) == eltype(test)
    @test edgetype(test) == Edge{Int}
    @test vertices(test) == Base.OneTo(3)
    @test weight_type(test) == Float64
    @test has_edge(test, Edge(rock, scissors))
    @test has_vertex(test, rock)
    @test issubset(test2, test)
    @test SimpleDiGraph(test) isa SimpleDiGraph
end

test2 = copy(test)

@testset "Double check deletion" begin
    delete!(test, rock)
    @test ne(test) == 1
    @test filter_edges(test, isequal(:scissors_beats_paper)) == [Edge(2, 1)]
    delete!(test2, scissors)
    @test ne(test2) == 1
    @test filter_edges(test2, isequal(:paper_beats_rock)) == [Edge(2, 1)]
    rem_edge!(test, Edge(2, 1))
    @test ne(test) == 0
    rem_vertex!(test, 2)
    @test nv(test) == 1
end

test = meta_graph(DiGraph(), AtVertex = Symbol, AtEdge = Float64, weight_function = identity)
rock = push!(test, :rock)
scissors = push!(test, :scissors)
paper = push!(test, :paper)

test[Edge(rock, scissors)] = 1
test[Edge(scissors, paper)] = 2
w = weights(test)

@testset "Weights" begin
    @test string(w) == "metaweights"
    @test w[rock, paper] == 1.0
    @test size(w) == (3, 3)
end

test = meta_graph(Graph())
@test SimpleGraph(test) isa SimpleGraph

using MetaGraphs
using LightGraphs
using LightGraphs.SimpleGraphs: fadj, badj
import Documenter: doctest
import Test: @testset, @test

doctest(MetaGraphs)

test = meta_graph(DiGraph(), AtVertex = Symbol)
rock = push!(test, :rock)
scissors = push!(test, :scissors)
paper = push!(test, :paper)

test[Edge(rock, scissors)] = nothing
test[Edge(scissors, paper)] = nothing
test[Edge(paper, rock)] = nothing

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
end

test2 = induced_subgraph(test, [1, 2])

@testset "Miscellaneous" begin
    @test haskey(reverse(test), Edge(scissors, rock))
    @test nv(test2) == 2
    @test ne(test2) == 1
    @test haskey(test2, Edge(rock, scissors))
end

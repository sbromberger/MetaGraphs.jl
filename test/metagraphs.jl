using MetaGraphs
import LightGraphs: SimpleGraphs
import Base64:
        stringmime


@testset "MetaGraphs" begin

    # constructors
    @test @inferred(MetaGraph()) == MetaGraph(SimpleGraph())
    @test @inferred(MetaDiGraph()) == MetaDiGraph(SimpleDiGraph())

    @test !is_directed(MetaGraph)
    @test is_directed(MetaDiGraph)

    adjmx1 = [0 1 0; 1 0 1; 0 1 0] # SimpleGraph
    adjmx2 = [0 1 0; 1 0 1; 1 1 0] # SimpleDiGraph
    gx = PathGraph(4)
    dgx = PathDiGraph(4)

    mg = MetaGraph()
    @test add_vertex!(mg, :color, "red") && get_prop(mg, nv(mg), :color) == "red"
    @test add_vertex!(mg, Dict(:color => "red", :prop2 => "prop2")) && props(mg, nv(mg)) == Dict(:color => "red", :prop2 => "prop2")
    @test add_edge!(mg, 1, 2, :color, "blue") && get_prop(mg, 1, 2, :color) ==  "blue"
    @test add_vertex!(mg) && add_edge!(mg, 1, 3, Dict(:color => "red", :prop2 => "prop2")) && props(mg, 1, 3) == Dict(:color => "red", :prop2 => "prop2")

    for g in testgraphs(gx)
        mg = MetaGraph(g)
        g2 = SimpleGraph(mg)
        @test g2 == mg.graph

        @test eltype(@inferred(MetaGraph{UInt8,Float16}(mg))) == UInt8
        @test weighttype(@inferred(MetaGraph{UInt8,Float16}(mg))) == Float16

        @test @inferred(MetaGraphs.fadj(mg, 2)) == LightGraphs.SimpleGraphs.fadj(g, 2)
        @test @inferred(MetaGraphs.badj(mg, 2)) == LightGraphs.SimpleGraphs.badj(g, 2)

        @test @inferred(edgetype(mg)) == edgetype(mg.graph)

        @test @inferred(eltype(mg)) == eltype(g)
        @test @inferred(eltype(MetaGraph(g, 2.0))) == eltype(g)
        @test @inferred(eltype(MetaGraph(g, :cost))) == eltype(g)
        @test @inferred(eltype(MetaGraph(g, :cost, 2.0))) == eltype(g)
        @test @inferred(eltype(MetaGraph{UInt8,Float16}(g))) == UInt8
        @test @inferred(eltype(MetaGraph{UInt8,Float16}(g, :cost))) == UInt8
        @test @inferred(eltype(MetaGraph{UInt8,Float16}(g, 4))) == UInt8
        @test @inferred(ne(mg)) == 3
        @test @inferred(nv(mg)) == 4
        @test @inferred(!is_directed(mg))

        @test @inferred(vertices(mg)) == 1:4
        @test Edge(2, 3) in edges(mg)
        @test @inferred(outneighbors(mg, 2)) == inneighbors(mg, 2) == neighbors(mg, 2)
        @test @inferred(has_edge(mg, 2, 3))
        @test @inferred(has_edge(mg, 3, 2))

        mgc = copy(mg)
        @test @inferred(add_edge!(mgc, 4 => 1)) && mgc == MetaGraph(CycleGraph(4))
        @test @inferred(has_edge(mgc, 4 => 1)) && has_edge(mgc, 0x04 => 0x01)
        mgc = copy(mg)
        @test @inferred(add_edge!(mgc, (4, 1))) && mgc == MetaGraph(CycleGraph(4))
        @test @inferred(has_edge(mgc, (4, 1))) && has_edge(mgc, (0x04, 0x01))
        mgc = copy(mg)
        @test add_edge!(mgc, 4, 1) && mgc == MetaGraph(CycleGraph(4))

        @test @inferred(add_vertex!(mgc))   # out of order, but we want it for issubset
        @test @inferred(mg ⊆ mgc)
        @test @inferred(has_vertex(mgc, 5))
        @test @inferred(rem_edge!(mgc, 1, 2)) && @inferred(!has_edge(mgc, 1, 2))

        mga = @inferred(copy(mg))
        @test @inferred(rem_vertex!(mga, 2)) && ne(mga) == 1
        @test @inferred(!rem_vertex!(mga, 10))

        @test @inferred(zero(mg)) == MetaGraph{eltype(mg),weighttype(mg)}()
        @test @inferred(eltype(mg)) == eltype(outneighbors(mg, 1)) == eltype(nv(mg))
        T = @inferred(eltype(mg))
        U = @inferred(weighttype(mg))
        @test @inferred(nv(MetaGraph{T,U}(6))) == 6

    end

    for g in testdigraphs(dgx)
        mg = MetaDiGraph(g)
        g2 = SimpleDiGraph(mg)
        @test g2 == mg.graph

        @test eltype(@inferred(MetaDiGraph{UInt8,Float16}(mg))) == UInt8
        @test weighttype(@inferred(MetaDiGraph{UInt8,Float16}(mg))) == Float16

        @test @inferred(MetaGraphs.fadj(mg, 2)) == LightGraphs.SimpleGraphs.fadj(g, 2)
        @test @inferred(MetaGraphs.badj(mg, 2)) == LightGraphs.SimpleGraphs.badj(g, 2)

        @test @inferred(edgetype(mg)) == edgetype(mg.graph)

        @test @inferred(eltype(mg)) == eltype(g)
        @test @inferred(eltype(MetaDiGraph(g, 2.0))) == eltype(g)
        @test @inferred(eltype(MetaDiGraph(g, :cost))) == eltype(g)
        @test @inferred(eltype(MetaDiGraph(g, :cost, 2.0))) == eltype(g)
        @test @inferred(eltype(MetaDiGraph{UInt8,Float16}(g))) == UInt8
        @test @inferred(eltype(MetaDiGraph{UInt8,Float16}(g, :cost))) == UInt8
        @test @inferred(eltype(MetaDiGraph{UInt8,Float16}(g, 4))) == UInt8

        @test @inferred(ne(mg)) == 3
        @test @inferred(nv(mg)) == 4
        @test @inferred(is_directed(mg))

        @test @inferred(vertices(mg)) == 1:4
        @test Edge(2, 3) in edges(mg)
        @test @inferred(outneighbors(mg, 2)) == [3]
        @test @inferred(inneighbors(mg, 2)) == [1]
        @test @inferred(has_edge(mg, 2, 3))
        @test @inferred(!has_edge(mg, 3, 2))

        mgc = copy(mg)
        @test @inferred(add_edge!(mgc, 4 => 1)) && mgc == MetaDiGraph(CycleDiGraph(4))
        @test @inferred(has_edge(mgc, 4 => 1)) && has_edge(mgc, 0x04 => 0x01)
        mgc = copy(mg)
        @test @inferred(add_edge!(mgc, (4, 1))) && mgc == MetaDiGraph(CycleDiGraph(4))
        @test @inferred(has_edge(mgc, (4, 1))) && has_edge(mgc, (0x04, 0x01))
        mgc = copy(mg)
        @test add_edge!(mgc, 4, 1) && mgc == MetaDiGraph(CycleDiGraph(4))

        @test @inferred(add_vertex!(mgc))   # out of order, but we want it for issubset
        @test @inferred(mg ⊆ mgc)
        @test @inferred(has_vertex(mgc, 5))
        @test @inferred(rem_edge!(mgc, 1, 2)) && @inferred(!has_edge(mgc, 1, 2))

        mga = @inferred(copy(mg))
        @test @inferred(rem_vertex!(mga, 2)) && ne(mga) == 1
        @test @inferred(!rem_vertex!(mga, 10))

        @test @inferred(zero(mg)) == MetaDiGraph{eltype(mg),weighttype(mg)}()
        @test @inferred(eltype(mg)) == eltype(outneighbors(mg, 1)) == eltype(nv(mg))
        T = @inferred(eltype(mg))
        U = @inferred(weighttype(mg))
        @test @inferred(nv(MetaDiGraph{T,U}(6))) == 6
    end

    for gbig in [SimpleGraph(0xff), SimpleDiGraph(0xff)]
        mg = MetaGraph(gbig)
        @test @inferred(!add_vertex!(mg))    # overflow
        @test @inferred(add_vertices!(mg, 10)) < 10
    end

    gx = SimpleGraph()
    for g in testgraphs(gx)
        mg = MetaGraph(g)
        T = eltype(mg)
        U = weighttype(mg)
        @test sprint(show, mg) == "{0, 0} undirected $T metagraph with $U weights defined by :$(mg.weightfield) (default weight $(mg.defaultweight))"
        @test @inferred(add_vertices!(mg, 5)) == 5
        @test sprint(show, mg) == "{5, 0} undirected $T metagraph with $U weights defined by :$(mg.weightfield) (default weight $(mg.defaultweight))"
    end
    gx = SimpleDiGraph()
    for g in testdigraphs(gx)
        mg = MetaDiGraph(g)
        T = eltype(mg)
        U = weighttype(mg)
        @test sprint(show, mg) == "{0, 0} directed $T metagraph with $U weights defined by :$(mg.weightfield) (default weight $(mg.defaultweight))"
        @test @inferred(add_vertices!(mg, 5)) == 5
        @test sprint(show, mg) == "{5, 0} directed $T metagraph with $U weights defined by :$(mg.weightfield) (default weight $(mg.defaultweight))"
    end

    mg = MetaGraph(CompleteGraph(3), 3.0)
    @test enumerate_paths(dijkstra_shortest_paths(mg, 1), 3) == [1, 3]
    @test set_prop!(mg, 1, 2, :weight, 0.2)
    @test !set_prop!(mg, 1000, 2, :weight, 0.2) # nonexistent edge
    @test set_prop!(mg, 2, 3, :weight, 1)
    @test enumerate_paths(dijkstra_shortest_paths(mg, 1), 3) == [1, 2, 3]

    # issue #60
    mg60 = MetaGraph(2)
    add_edge!(mg60, 1, 2)
    set_prop!(mg60, 2, 1, :weight, 7.0)
    @test get_prop(mg60, 1, 2, :weight) == 7.0
    @test get_prop(mg60, 2, 1, :weight) == 7.0
    @test weights(mg60)[1, 2] == 7.0
    @test weights(mg60)[2, 1] == 7.0
    mdg60 = MetaDiGraph(2)
    add_edge!(mdg60, 1, 2)
    add_edge!(mdg60, 2, 1)
    set_prop!(mdg60, 2, 1, :weight, 7.0)
    @test get_prop(mdg60, 2, 1, :weight) == 7.0
    @test weights(mdg60)[1, 2] == 1.0
    @test weights(mdg60)[2, 1] == 7.0

    @test set_prop!(mg, 1, :color, "blue")
    @test set_prop!(mg, 1, :color, "blue")
    @test !set_prop!(mg, 1000, :color, "blue") # nonexistent vertex
    @test set_prop!(mg, 1, :id, 0x5)
    @test set_prop!(mg, 1, :id, 0x5)
    @test set_prop!(mg, :name, "test graph")
    @test set_prop!(mg, :name, "test graph")


    @test length(props(mg)) == 1
    @test length(props(mg, 1)) == 2
    @test length(props(mg, 1, 2)) == 1

    @test get_prop(mg, :name) == "test graph"
    @test get_prop(mg, 1, :color) == "blue"
    @test get_prop(mg, 1, 2, :weight) == 0.2

    set_prop!(mg, :del, 0x2)
    set_prop!(mg, 1, :del, 0x2)
    set_prop!(mg, 1, 2, :del, 0x2)

    rem_prop!(mg, :del)
    rem_prop!(mg, 1, :del)
    rem_prop!(mg, 1, 2, :del)
    @test_throws KeyError get_prop(mg, 1, :del)
    @test get_prop(mg, 1, :id) == 0x5
    clear_props!(mg)
    @test length(props(mg)) == 0
    clear_props!(mg, 1)
    @test length(props(mg, 1)) == 0
    clear_props!(mg, 1, 2)
    @test length(props(mg, 1, 2)) == 0

    # metagraph constructor from metadigraph
    mdg = MetaDiGraph(PathDiGraph(4), 3.0)
    set_prop!(mdg, 1, 2, :name, 12)
    set_prop!(mdg, 2, 3, :name, 23)
    set_prop!(mdg, 3, 4, :name, 34)
    set_indexing_prop!(mdg, 1, :foo, "v1")
    set_indexing_prop!(mdg, 2, :foo, "v2")
    set_indexing_prop!(mdg, 3, :foo, "v3")
    set_indexing_prop!(mdg, 4, :foo, "v4")

    dg = MetaGraph(mdg)
    set_prop!(mdg, 1, 2, :name, 99)
    @test get_prop(mdg, 1, 2, :name) == 99
    @test get_prop(dg, 1, 2, :name) == 12

    set_indexing_prop!(mdg, 1, :foo, "99")
    @test get_prop(mdg, 1, :foo) == "99"
    @test get_prop(dg, 1, :foo) == "v1"
    add_vertex!(mdg)
    @test nv(mdg) == nv(dg) + 1
    add_edge!(mdg, 1, 3)
    @test !has_edge(dg, 1, 3)
    defaultweight!(mdg, 11.11)
    @test defaultweight(dg) == 3.0

    mg = MetaDiGraph(PathDiGraph(3), 3.0)
    add_edge!(mg, 1, 3)
    @test enumerate_paths(dijkstra_shortest_paths(mg, 1), 3) == [1, 3]
    @test set_prop!(mg, 1, 2, :weight, 0.2)
    @test !set_prop!(mg, 1000, 2, :weight, 0.2) # nonexistent edge
    @test set_prop!(mg, 2, 3, :weight, 1)
    @test enumerate_paths(dijkstra_shortest_paths(mg, 1), 3) == [1, 2, 3]

    @test set_prop!(mg, 1, :color, "blue")
    @test !set_prop!(mg, 1000, :color, "blue") # nonexistent vertex
    @test set_prop!(mg, 1, :id, 0x5)
    @test set_prop!(mg, :name, "test graph")


    @test length(props(mg)) == 1
    @test length(props(mg, 1)) == 2
    @test length(props(mg, 1, 2)) == 1

    @test get_prop(mg, :name) == "test graph"
    @test get_prop(mg, 1, :color) == "blue"
    @test get_prop(mg, 1, 2, :weight) == 0.2

    set_prop!(mg, :del, 0x2)
    set_prop!(mg, 1, :del, 0x2)
    set_prop!(mg, 1, 2, :del, 0x2)

    @test has_prop(mg, :del)
    @test has_prop(mg, 1, :del)
    @test has_prop(mg, 1, 2, :del)
    rem_prop!(mg, :del)
    rem_prop!(mg, 1, :del)
    rem_prop!(mg, 1, 2, :del)
    @test !has_prop(mg, :del)
    @test !has_prop(mg, 1, :del)
    @test !has_prop(mg, 1, 2, :del)
    @test_throws KeyError get_prop(mg, 1, :del)
    @test get_prop(mg, 1, :id) == 0x5
    clear_props!(mg)
    @test length(props(mg)) == 0
    clear_props!(mg, 1)
    @test length(props(mg, 1)) == 0
    clear_props!(mg, 1, 2)
    @test length(props(mg, 1, 2)) == 0

    mg = MetaGraph(CompleteGraph(3), 3.0)
    mw = MetaGraphs.MetaWeights(mg)
    @test mw[1, 2] == 3.0
    @test sprint(show, mw) == stringmime("text/plain", mw) == "metaweights"
    @test size(mw) == (3, 3)
    set_prop!(mg, 1, 2, :weight, 0.2)
    set_prop!(mg, 2, 3, :weight, 1)
    @test weightfield!(mg, :cost) == :cost
    @test enumerate_paths(dijkstra_shortest_paths(mg, 1), 3) == [1, 3]
    @test weightfield!(mg, :weight) == :weight
    @test enumerate_paths(dijkstra_shortest_paths(mg, 1), 3) == [1, 2, 3]

    @test set_props!(mg, 1, 2,  Dict(:color => :blue, :action => "knows"))
    @test length(props(mg, 1, 2)) == 3
    @test rem_edge!(mg, 1, 2)
    @test length(props(mg, 1, 2)) == 0
    @test set_props!(mg, Dict(:name => "testgraph", :type => "undirected"))
    @test length(props(mg)) == 2

    mg = MetaGraph(CompleteGraph(3), 3.0)
    set_prop!(mg, 1, :color, "blue")
    set_prop!(mg, 1, :id, 40)
    set_prop!(mg, 2, :color, "red")
    set_prop!(mg, 2, :id, 80)
    set_prop!(mg, 3, :color, "blue")
    set_prop!(mg, 1, 2, :weight, 0.2)
    set_prop!(mg, 2, 3, :weight, 0.6)
    set_prop!(mg, :name, "test metagraph")

    @test length(collect(filter_edges(mg, :weight))) == 2
    @test length(collect(filter_edges(mg, :weight, 0.2))) == 1
    @test length(collect(filter_vertices(mg, :color))) == 3
    @test length(collect(filter_vertices(mg, :color, "blue"))) == 2

    fv1 = filter_vertices(mg, :id)
    fv2 = filter_vertices(mg, :color, "blue")
    fe1 = filter_edges(mg, :weight)
    fe2 = filter_edges(mg, :weight, 0.6)

    i = mg[fv1]
    @test nv(i) == 2 && ne(i) == 1
    @test has_prop(i, 1, :id)
    @test has_prop(i, 2, :id)

    i = mg[fv2]
    @test nv(i) == 2 && ne(i) == 1
    @test get_prop(i, 1, :color) == "blue"
    @test get_prop(i, 2, :color) == "blue"

    i = mg[fe1]
    @test nv(i) == 3 && ne(i) == 2
    @test sum(get_prop(i, e, :weight) for e in edges(i)) == 0.8

    i = mg[fe2]
    @test nv(i) == 2 && ne(i) == 1
    @test get_prop(i, 1, :color) == "red"
    @test get_prop(i, 2, :color) == "blue"
    @test get_prop(i, 1, 2, :weight) == 0.6


    # test for #15
    mga = MetaGraph(Graph(5))
    for v in vertices(mga)
        set_prop!(mga, v, :name, string(v))
    end
    set_indexing_prop!(mga,:name)
    @test get_prop(mga, 1, :name) == "1"
    @test get_prop(mga, 5, :name) == "5"
    @test rem_vertex!(mga, 1)
    @test get_prop(mga, 1, :name) == "5"
    @test mga["5",:name] == 1
    @test isempty(props(mga, 5))

    # test for #22
    mga = MetaGraph(PathGraph(4))
    set_prop!(mga, 1, 2, :name, "1, 2")
    set_prop!(mga, 2, 3, :name, "2, 3")
    set_prop!(mga, 3, 4, :name, "3, 4")
    @test rem_vertex!(mga, 2)
    @test nv(mga) == 3
    @test ne(mga) == 1
    @test length(mga.eprops) == 1  # should only be edge 2=>3
    @test props(mga, 2, 3)[:name] == "3, 4"

    # test for #72 - Multiple indicies that are not all used
    let
        test_graph = x-> begin
            g=MetaGraph()
            set_indexing_prop!(g,:IndexA)
            set_indexing_prop!(g,:IndexB)
            add_vertex!(g,:IndexA,"A")
            x && add_vertex!(g,:IndexA,"B")
            x && set_indexing_prop!(g,nv(g),:IndexB,"B")
            add_vertex!(g,:IndexB,"C")
            g
        end
        mga=test_graph(true)
        rem_vertex!(mga,2)
        @test mga==test_graph(false)
    end

    mga = MetaDiGraph(PathDiGraph(4))
    set_prop!(mga, 1, 2, :name, "1, 2")
    set_prop!(mga, 2, 3, :name, "2, 3")
    set_prop!(mga, 3, 4, :name, "3, 4")
    @test rem_vertex!(mga, 2)
    @test nv(mga) == 3
    @test ne(mga) == 1
    @test length(mga.eprops) == 1 # should only be edge 3=>2
    @test props(mga, 3, 2)[:name] == "3, 4"

    # test for #32
    mga = MetaGraph(PathGraph(4))
    for j in 1:4
        set_prop!(mga, j, :prop, "node$j")
    end
    set_indexing_prop!(mga, :prop)
    add_vertex!(mga)
    set_indexing_prop!(mga, nv(mga), :prop, "node5")
    @test mga["node5", :prop] == 5
    @test get_prop(mga, 5, :prop) == "node5"

    # test for #33
    mga = MetaGraph(PathGraph(4))
    set_prop!(mga, 1, 2, :name, "1, 2")
    set_prop!(mga, 2, 3, :name, "2, 3")
    set_prop!(mga, 3, 4, :name, "3, 4")
    set_prop!(mga, 3, :v, 3)
    set_prop!(mga, 4, :v, 4)
    @test rem_vertex!(mga, nv(mga))
    @test has_prop(mga, 2, 3, :name)
    @test !has_prop(mga, 3, 4, :name)
    @test !has_prop(mga, 4, :v)
    @test has_prop(mga, 3, :v)

    # test for setting indexed props with set_prop!
    mga = MetaGraph(PathGraph(4))
    for j in 1:3
        set_indexing_prop!(mga, j, :prop, "node$j")
    end
    add_vertex!(mga)
    set_prop!(mga, nv(mga), :prop, "node5")
    set_prop!(mga, 1, :prop, "newnode1")
    @test get_prop(mga, 4, :prop) == "prop4"
    @test mga["node5", :prop] == 5
    @test get_prop(mga, 5, :prop) == "node5"
    @test get_prop(mga, 1, :prop) == "newnode1"


end

@testset "MetaIndexing" begin
    G = MetaGraph(100)
    dG = MetaDiGraph(100)

    for i in 1:100
        set_prop!(G, i, :name, "gnode_$i")
        set_prop!(dG, i, :name, "dgnode_$i")
    end

    for i in 1:100
        set_prop!(G, i, :not_unique, "$(i % 5)")
        set_prop!(dG, i, :not_unique, "$(i % 5)")
    end

    @test set_indexing_prop!(G, :name) == Set{Symbol}([:name])
    @test set_indexing_prop!(dG, :name) == Set{Symbol}([:name])
    @test_throws ErrorException set_indexing_prop!(G, :not_unique)
    @test_throws ErrorException set_indexing_prop!(dG, :not_unique)

    @test G["gnode_3", :name] == 3
    @test dG["dgnode_99", :name] == 99

    @test_throws ErrorException set_indexing_prop!(G, 4, :name, "gnode_3")
    @test_throws ErrorException set_indexing_prop!(dG, 4, :name, "dgnode_3")
    @test_throws ErrorException set_prop!(G, 4, :name, "gnode_3")
    @test_throws ErrorException set_prop!(dG, 4, :name, "dgnode_3")
    @test_throws ErrorException set_props!(G, 5, Dict(:name => "name", :other_name => "something"))
    @test_throws ErrorException set_props!(dG, 5, Dict(:name => "name", :other_name => "something"))

    @info("Ignore \"'foo1' is already in index\" warnings")
    set_indexing_prop!(G, 50, :name, "another name")
    set_indexing_prop!(G, 50, :name, "another name")

    set_indexing_prop!(G, 43, :foo, "foo1")
    set_indexing_prop!(dG, 43, :foo, "foo1")
    @test G[1, :foo] != "foo1"
    @test dG[1, :foo] != "foo1"

    set_indexing_prop!(G, 42, :foo, "bar")
    set_indexing_prop!(dG, 42, :foo, "bar")

    @test G["foo10", :foo] == 10
    @test G[12, :foo] == "foo12"
    @test G["bar", :foo] == 42
    @test G[42, :foo] == "bar"
    @test isa(G[:foo], Dict{Any,Integer})
    @test isa(dG[:foo], Dict{Any,Integer})


    @test dG["foo30", :foo] == 30
    @test dG[79, :foo] == "foo79"
    @test dG["bar", :foo] == 42
    @test dG[42, :foo] == "bar"

    @test_throws ErrorException G[:not_a_key]
    @test_throws ErrorException dG[:not_a_key]
end

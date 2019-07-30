@testset "Overrides" begin
    g=MetaDiGraph(StarDiGraph(4), 8)

    set_indexing_prop!(g,:nodelabel)
    foreach(v->set_indexing_prop!(g,v,:nodelabel,"Vertex $v"),vertices(g))
    foreach(e->set_prop!(g,e,:edgelabel,"Edge ($(e.src),$(e.dst))") ,edges(g))

    h=reverse(g)

    for v in 1:3
        @test get_prop(g, v, :nodelabel) == get_prop(h, v, :nodelabel)
    end

    for sd in 2:4
        @test get_prop(g, 1, sd, :edgelabel) == get_prop(h, sd, 1, :edgelabel) 
    end

    @test weightfield(h) == weightfield(g) == :weight
    @test defaultweight(h) == defaultweight(g) == 8

end

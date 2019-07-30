@testset "Persistence" begin
    (f, fio) = mktemp()
    close(fio)

    gx = PathGraph(5)
    for g in testgraphs(gx)
        mg = MetaGraph(g)
        set_prop!(mg, 1, 2, :weight, 0.2)
        set_prop!(mg, 2, 3, :color, :red)
        set_prop!(mg, 1, :name, "Alice")
        set_prop!(mg, 2, :name, "Bob")
        set_prop!(mg, :type, "My MetaGraph")
    
        @test savegraph(f, mg) == 1
        g2 = loadgraph(f, MGFormat())
        @test mg == g2
    end

    gx = PathDiGraph(5)
    for g in testdigraphs(gx)
        mg = MetaDiGraph(g)
        set_prop!(mg, 1, 2, :weight, 0.2)
        set_prop!(mg, 2, 3, :color, :red)
        set_prop!(mg, 1, :name, "Alice")
        set_prop!(mg, 2, :name, "Bob")
        set_prop!(mg, :type, "My MetaGraph")

        @test savegraph(f, mg) == 1
        g2 = loadgraph(f, MGFormat())
        @test mg == g2        
    end
    rm(f)
end

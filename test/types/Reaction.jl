@testset "Reaction" begin
    m1 = Metabolite("m1")
    m1.formula = "C2H3"
    m2 = Metabolite("m2")
    m2.formula = "H3C2"
    m3 = Metabolite("m3")
    m4 = Metabolite("m4")
    m5 = Metabolite("m5")
    m6 = Metabolite("m6")
    m7 = Metabolite("m7")
    m8 = Metabolite("m8")
    m9 = Metabolite("m9")
    m10 = Metabolite("m10")
    m11 = Metabolite("m11")
    m12 = Metabolite("m12")

    g1 = Gene("g1")
    g2 = Gene("g2")
    g3 = Gene("g3")

    r1 = Reaction(id = "r1")
    r1.metabolites = Dict(m1.id => -1.0, m2.id => 1.0)
    r1.lower_bound = -100.0
    r1.upper_bound = 100.0
    r1.gene_associations = [
        Isozyme(gene_product_stoichiometry = Dict("g1" => 1, "g2" => 1)),
        Isozyme(gene_product_stoichiometry = Dict("g3" => 1)),
    ]
    r1.subsystem = "glycolysis"
    r1.notes = Dict("notes" => ["blah", "blah"])
    r1.annotations = Dict("sboterm" => ["sbo"], "biocyc" => ["ads", "asds"])

    @test all(
        contains.(
            sprint(show, MIME("text/plain"), r1),
            ["r1", "100.0", "g1 && g2", "glycolysis", "blah", "biocyc", "g3"],
        ),
    )

    r2 = ReactionBackward("r2", Dict(m1.id => -2.0, m4.id => 1.0))
    @test r2.lower_bound == -1000.0 && r2.upper_bound == 0.0

    r3 = ReactionForward("r3", Dict(m3.id => -1.0, m4.id => 1.0))
    @test r3.lower_bound == 0.0 && r3.upper_bound == 1000.0

    r4 = ReactionBidirectional("r4", Dict(m3.id => -1.0, m4.id => 1.0))
    r4.annotations = Dict("sboterm" => ["sbo"], "biocyc" => ["ads", "asds"])
    @test r4.lower_bound == -1000.0 && r4.upper_bound == 1000.0

    rd = OrderedDict(r.id => r for r in [r1, r2, r3, r4])
    @test issetequal(["r1", "r4"], ambiguously_identified_items(annotation_index(rd)))

    id = check_duplicate_reaction(r4, rd)
    @test id == "r3"

    r5 = ReactionBidirectional("r5", Dict(m3.id => -11.0, m4.id => 1.0))
    id = check_duplicate_reaction(r5, rd)
    @test id == "r3"

    r5 = ReactionBidirectional("r5", Dict(m3.id => -11.0, m4.id => 1.0))
    id = check_duplicate_reaction(r5, rd; only_metabolites = false)
    @test isnothing(id)

    r5 = ReactionBidirectional("r5", Dict(m3.id => -1.0, m4.id => 1.0))
    id = check_duplicate_reaction(r5, rd; only_metabolites = false)
    @test id == "r3"
end

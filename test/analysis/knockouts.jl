@testset "single_knockout" begin
    m = ObjectModel()
    add_metabolite!(m, Metabolite("A"))
    add_metabolite!(m, Metabolite("B"))

    add_gene!(m, Gene("g1"))
    add_gene!(m, Gene("g2"))
    add_reaction!(
        m,
        Reaction(
            "v1",
            metabolites = Dict("A" => -1.0, "B" => 1.0),
            gene_associations = [Isozyme(["g1"])],
        ),
    )
    add_reaction!(
        m,
        Reaction(
            "v2",
            metabolites = Dict("A" => -1.0, "B" => 1.0),
            gene_associations = [Isozyme(["g1", "g2"])],
        ),
    )
    add_reaction!(
        m,
        Reaction(
            "v3",
            metabolites = Dict("A" => -1.0, "B" => 1.0),
            gene_associations = [Isozyme(["g1"]), Isozyme(["g2"])],
        ),
    )
    add_reaction!(
        m,
        Reaction(
            "v4",
            metabolites = Dict("A" => -1.0, "B" => 1.0),
            gene_associations = [Isozyme(["g1", "g2"]), Isozyme(["g2"])],
        ),
    )

    opt_model = make_optimization_model(m, Tulip.Optimizer)
    knockout("g1")(m, opt_model)

    # Knockout should remove v1
    @test normalized_rhs(opt_model[:lbs][1]) == 0
    @test normalized_rhs(opt_model[:ubs][1]) == 0

    # Knockout should remove [g1, g2] (AND) and thus remove reaction
    @test normalized_rhs(opt_model[:lbs][2]) == 0
    @test normalized_rhs(opt_model[:ubs][2]) == 0

    # Knockout should remove [g1], but keep reaction (OR)
    @test normalized_rhs(opt_model[:lbs][3]) == 1000
    @test normalized_rhs(opt_model[:ubs][3]) == 1000

    # Knockout should remove [g1, g2] (AND), but keep reaction (OR)
    @test normalized_rhs(opt_model[:lbs][4]) == 1000
    @test normalized_rhs(opt_model[:ubs][4]) == 1000
end

@testset "multiple_knockouts" begin
    m = ObjectModel()
    add_metabolite!(m, Metabolite("A"))
    add_metabolite!(m, Metabolite("B"))
    add_gene!(m, Gene("g1"))
    add_gene!(m, Gene("g2"))
    add_gene!(m, Gene("g3"))
    add_reaction!(
        m,
        Reaction(
            "v1",
            metabolites = Dict("A" => -1.0, "B" => 1.0),
            gene_associations = [Isozyme(["g1"]), Isozyme(["g3"])],
        ),
    )
    add_reaction!(
        m,
        Reaction(
            "v2",
            metabolites = Dict("A" => -1.0, "B" => 1.0),
            gene_associations = [Isozyme(["g1", "g2"]), Isozyme(["g3"])],
        ),
    )
    add_reaction!(
        m,
        Reaction(
            "v3",
            metabolites = Dict("A" => -1.0, "B" => 1.0),
            gene_associations = [Isozyme(x) for x in [["g1"], ["g2"], ["g3"]]],
        ),
    )

    opt_model = make_optimization_model(m, Tulip.Optimizer)
    knockout(["g1", "g3"])(m, opt_model)

    # Reaction 1 should be knocked out, because both
    # gene1 and gene 3 are knocked out
    @test normalized_rhs(opt_model[:lbs][1]) == 0
    @test normalized_rhs(opt_model[:ubs][1]) == 0

    # Reaction 2 should be knocked out, because both
    # [g1, g2] is an AND relationship
    @test normalized_rhs(opt_model[:lbs][1]) == 0
    @test normalized_rhs(opt_model[:ubs][1]) == 0

    # Reaction 3 should stay, because gene2 is still
    # available (the arrays have an OR relationship)
    @test normalized_rhs(opt_model[:lbs][3]) == 1000
    @test normalized_rhs(opt_model[:ubs][3]) == 1000
end

@testset "Knockouts on realistic models" begin
    for model in [
        load_model(ObjectModel, model_paths["e_coli_core.json"]), #test on standardModel
        load_model(model_paths["e_coli_core.json"]), #then on JSONModel with the same contents
    ]

        sol =
            flux_balance_analysis(
                model,
                Tulip.Optimizer;
                modifications = [
                    change_objective("BIOMASS_Ecoli_core_w_GAM"),
                    change_constraint("EX_glc__D_e"; lower_bound = -12, upper_bound = -12),
                    change_sense(MAX_SENSE),
                    change_optimizer_attribute("IPM_IterationsLimit", 110),
                    knockout(["b0978", "b0734"]), # knockouts out cytbd
                ],
            ) |> values_dict
        @test isapprox(
            sol["BIOMASS_Ecoli_core_w_GAM"],
            0.2725811189335953,
            atol = TEST_TOLERANCE,
        )

        sol =
            flux_balance_analysis(
                model,
                Tulip.Optimizer;
                modifications = [
                    change_objective("BIOMASS_Ecoli_core_w_GAM"),
                    change_constraint("EX_glc__D_e"; lower_bound = -12, upper_bound = -12),
                    change_sense(MAX_SENSE),
                    change_optimizer_attribute("IPM_IterationsLimit", 110),
                    knockout("b2779"), # knockouts out enolase
                ],
            ) |> values_dict
        @test isapprox(sol["BIOMASS_Ecoli_core_w_GAM"], 0.0, atol = TEST_TOLERANCE)
    end
end

@testset "CommunityModel: structure" begin

    m1 = ObjectModel()
    add_metabolites!(
        m1,
        [Metabolite("A"), Metabolite("B"), Metabolite("Ae"), Metabolite("Be")],
    )
    add_genes!(m1, [Gene("g1"), Gene("g2"), Gene("g3"), Gene("g4")])
    add_reactions!(
        m1,
        [
            ReactionBidirectional("EX_A", Dict("Ae" => -1)),
            ReactionBidirectional("r1", Dict("Ae" => -1, "A" => 1)),
            ReactionForward("r2", Dict("A" => -1, "B" => 1)), # bm1
            ReactionForward("r3", Dict("B" => -1, "Be" => 1)),
            ReactionForward("EX_B", Dict("Be" => -1)),
        ],
    )

    m2 = ObjectModel()
    add_metabolites!(
        m2,
        [Metabolite("Ae"), Metabolite("A"), Metabolite("C"), Metabolite("Ce")],
    )
    add_genes!(m2, [Gene("g1"), Gene("g2"), Gene("g3"), Gene("g4")])
    add_reactions!(
        m2,
        [
            ReactionForward("r3", Dict("C" => -1, "Ce" => 1)),
            ReactionForward("EX_C", Dict("Ce" => -1)),
            ReactionBidirectional("EX_A", Dict("Ae" => -1)),
            ReactionBidirectional("r1", Dict("Ae" => -1, "A" => 1)),
            ReactionForward("r2", Dict("A" => -1, "C" => 1)), #bm2
        ],
    )

    cm1 = CommunityMember(
        id = "m1",
        model = m1,
        exchange_reaction_ids = ["EX_A", "EX_B"],
        biomass_reaction_id = "r2",
    )
    @test contains(sprint(show, MIME("text/plain"), cm1), "community member")

    cm2 = CommunityMember(
        id = "m2",
        model = m2,
        exchange_reaction_ids = ["EX_A", "EX_C"],
        biomass_reaction_id = "r2",
    )

    cm = CommunityModel(
        members = [cm1, cm2],
        abundances = [0.2, 0.8],
        environmental_links = [
            EnvironmentalLink("EX_A", "Ae", -10.0, 10.0)
            EnvironmentalLink("EX_B", "Be", -20.0, 20.0)
            EnvironmentalLink("EX_C", "Ce", -30, 30)
        ],
    )
    @test contains(sprint(show, MIME("text/plain"), cm), "community model")

    @test issetequal(
        variables(cm),
        [
            "m1#EX_A"
            "m1#r1"
            "m1#r2"
            "m1#r3"
            "m1#EX_B"
            "m2#r3"
            "m2#EX_C"
            "m2#EX_A"
            "m2#r1"
            "m2#r2"
            "EX_A"
            "EX_C"
            "EX_B"
        ],
    )

    @test issetequal(
        metabolites(cm),
        [
            "m1#A"
            "m1#B"
            "m1#Ae"
            "m1#Be"
            "m2#Ae"
            "m2#A"
            "m2#C"
            "m2#Ce"
            "ENV_Ae"
            "ENV_Be"
            "ENV_Ce"
        ],
    )

    @test issetequal(
        genes(cm),
        [
            "m1#g1"
            "m1#g2"
            "m1#g3"
            "m1#g4"
            "m2#g1"
            "m2#g2"
            "m2#g3"
            "m2#g4"
        ],
    )

    @test n_variables(cm) == 13
    @test n_metabolites(cm) == 11
    @test n_genes(cm) == 8

    @test all(
        stoichiometry(cm) .== [
            0.0 1.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
            0.0 0.0 1.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
            -1.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
            0.0 0.0 0.0 1.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
            0.0 0.0 0.0 0.0 0.0 0.0 0.0 -1.0 -1.0 0.0 0.0 0.0 0.0
            0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0 -1.0 0.0 0.0 0.0
            0.0 0.0 0.0 0.0 0.0 -1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0
            0.0 0.0 0.0 0.0 0.0 1.0 -1.0 0.0 0.0 0.0 0.0 0.0 0.0
            0.2 0.0 0.0 0.0 0.0 0.0 0.0 0.8 0.0 0.0 -1.0 0.0 0.0
            0.0 0.0 0.0 0.0 0.2 0.0 0.0 0.0 0.0 0.0 0.0 -0.2 0.0
            0.0 0.0 0.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 0.0 0.0 -0.8
        ],
    )

    lbs, ubs = bounds(cm)
    @test all(lbs .== [
        -1000.0
        -1000.0
        0.0
        0.0
        0.0
        0.0
        0.0
        -1000.0
        -1000.0
        0.0
        -10.0
        -20.0
        -30.0
    ])
    @test all(
        ubs .== [
            1000.0
            1000.0
            1000.0
            1000.0
            1000.0
            1000.0
            1000.0
            1000.0
            1000.0
            1000.0
            10.0
            20.0
            30.0
        ],
    )

    @test all(objective(cm) .== [
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
        0.0
    ])

    @test n_coupling_constraints(cm) == 0
    @test isempty(coupling(cm))
    @test all(isempty.(coupling_bounds(cm)))
end

@testset "EqualGrowthCommunityModel: e coli core" begin

    ecoli = load_model(ObjectModel, model_paths["e_coli_core.json"])
    ecoli.reactions["EX_glc__D_e"].lower_bound = -1000
    ex_rxns = COBREXA.Utils.find_exchange_reaction_ids(ecoli)

    cm1 = CommunityMember(
        id = "ecoli1",
        model = ecoli,
        exchange_reaction_ids = ex_rxns,
        biomass_reaction_id = "BIOMASS_Ecoli_core_w_GAM",
    )
    cm2 = CommunityMember(
        id = "ecoli2",
        model = ecoli,
        exchange_reaction_ids = ex_rxns,
        biomass_reaction_id = "BIOMASS_Ecoli_core_w_GAM",
    )

    ex_rxns = COBREXA.Utils.find_exchange_reaction_ids(ecoli)
    ex_mids = [first(keys(reaction_stoichiometry(ecoli, rid))) for rid in ex_rxns]
    ex_lbs = [ecoli.reactions[rid].lower_bound for rid in ex_rxns]
    ex_ubs = [ecoli.reactions[rid].upper_bound for rid in ex_rxns]

    a1 = 0.1 # abundance species 1
    a2 = 0.8 # abundance species 2

    cm = CommunityModel(
        members = [cm1, cm2],
        abundances = [a1, a2],
        environmental_links = [
            EnvironmentalLink(rid, mid, lb, ub) for
            (rid, mid, lb, ub) in zip(ex_rxns, ex_mids, ex_lbs, ex_ubs)
        ],
    )
    a1 = 0.2
    change_abundances!(cm, [a1, 0.8])
    @test cm.abundances[1] == 0.2

    @test_throws DomainError cm |> with_changed_abundances([0.1, 0.2])

    @test_throws DomainError cm |> with_changed_environmental_bound(
        "abc";
        lower_bound = -10,
        upper_bound = 10,
    )

    cm3 =
        cm |>
        with_changed_environmental_bound("EX_glc__D_e"; lower_bound = -10, upper_bound = 10)
    change_environmental_bound!(cm3, "EX_ac_e"; upper_bound = 100)

    @test cm3.environmental_links[1].upper_bound == 100
    @test cm3.environmental_links[9].lower_bound == -10

    eqcm = cm3 |> with_equal_growth_objective()
    d = flux_balance_analysis(eqcm, Tulip.Optimizer) |> values_dict

    @test isapprox(
        d[eqcm.community_objective_id],
        0.8739215069521299,
        atol = TEST_TOLERANCE,
    )

    # test if growth rates are the same
    @test isapprox(
        d["ecoli1#BIOMASS_Ecoli_core_w_GAM"],
        d[eqcm.community_objective_id],
        atol = TEST_TOLERANCE,
    )

    @test isapprox(
        d["ecoli2#BIOMASS_Ecoli_core_w_GAM"],
        d[eqcm.community_objective_id],
        atol = TEST_TOLERANCE,
    )

    @test isapprox(
        d["EX_glc__D_e"],
        a1 * d["ecoli1#EX_glc__D_e"] + a2 * d["ecoli2#EX_glc__D_e"],
        atol = TEST_TOLERANCE,
    )

    # test if model can be converted to another type
    om = convert(ObjectModel, cm)
    @test n_variables(om) == n_variables(cm)
end

@testset "EqualGrowthCommunityModel: enzyme constrained e coli" begin
    ecoli = load_model(ObjectModel, model_paths["e_coli_core.json"])

    # add molar masses to gene products
    for gid in genes(ecoli)
        ecoli.genes[gid].product_molar_mass = get(ecoli_core_gene_product_masses, gid, 0.0)
        ecoli.genes[gid].product_upper_bound = 10.0
    end
    ecoli.genes["s0001"] = Gene(id = "s0001"; product_molar_mass = 0.0)
    ecoli.genes["s0001"].product_upper_bound = 10.0

    # update isozymes with kinetic information
    for rid in reactions(ecoli)
        if haskey(ecoli_core_reaction_kcats, rid) # if has kcat, then has grr
            newisozymes = Isozyme[]
            for (i, grr) in enumerate(reaction_gene_associations(ecoli, rid))
                push!(
                    newisozymes,
                    Isozyme(
                        gene_product_stoichiometry = Dict(grr .=> fill(1.0, size(grr))),
                        kcat_forward = ecoli_core_reaction_kcats[rid][i][1],
                        kcat_backward = ecoli_core_reaction_kcats[rid][i][2],
                    ),
                )
            end
            ecoli.reactions[rid].gene_associations = newisozymes
        else
            ecoli.reactions[rid].gene_associations = nothing
        end
    end

    ex_rxns = COBREXA.Utils.find_exchange_reaction_ids(ecoli)

    gm =
        ecoli |>
        with_changed_bound("EX_glc__D_e"; lower_bound = -1000.0, upper_bound = 0) |>
        with_enzyme_constraints(total_gene_product_mass_bound = 100.0)

    cm1 = CommunityMember(
        id = "ecoli1",
        model = gm,
        exchange_reaction_ids = ex_rxns,
        biomass_reaction_id = "BIOMASS_Ecoli_core_w_GAM",
    )
    cm2 = CommunityMember(
        id = "ecoli2",
        model = gm,
        exchange_reaction_ids = ex_rxns,
        biomass_reaction_id = "BIOMASS_Ecoli_core_w_GAM",
    )

    a1 = 0.2 # abundance species 1
    a2 = 0.8 # abundance species 2

    ex_mids = [first(keys(reaction_stoichiometry(ecoli, rid))) for rid in ex_rxns]
    ex_lbs = [ecoli.reactions[rid].lower_bound for rid in ex_rxns]
    ex_ubs = [ecoli.reactions[rid].upper_bound for rid in ex_rxns]

    cm = CommunityModel(
        members = [cm1, cm2],
        abundances = [a1, a2],
        environmental_links = [
            EnvironmentalLink(rid, mid, lb, ub) for
            (rid, mid, lb, ub) in zip(ex_rxns, ex_mids, ex_lbs, ex_ubs)
        ],
    )

    eqgr =
        cm |>
        with_changed_environmental_bound("EX_glc__D_e"; lower_bound = -1000.0) |>
        with_equal_growth_objective()

    res = flux_balance_analysis(
        eqgr,
        Tulip.Optimizer;
        modifications = [modify_optimizer_attribute("IPM_IterationsLimit", 2000)],
    )

    f_d = values_dict(:reaction, res)

    @test isapprox(
        f_d[eqgr.community_objective_id],
        0.9210836692534606,
        atol = TEST_TOLERANCE,
    )

    # test convenience operators
    f_env = values_dict(:environmental_reaction, res)
    @test f_env["EX_o2_e"] == f_d["EX_o2_e"] # this should(?) be non-variable

    @test values_community_member_dict(res, cm1)["EX_glc__D_e"] == f_d["ecoli1#EX_glc__D_e"]

    @test values_community_member_dict(:enzyme, res, cm2)["b4301"] == values_dict(res)["ecoli2#b4301"]*gene_product_molar_mass(cm2.model.inner, "b4301") 
end

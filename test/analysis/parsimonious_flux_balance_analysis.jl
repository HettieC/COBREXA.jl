@testset "Parsimonious flux balance analysis with ObjectModel" begin
    model = test_toyModel()

    d =
        parsimonious_flux_balance_analysis(
            model,
            Tulip.Optimizer;
            modifications = [
                modify_constraint("EX_m1(e)", lower_bound = -10.0),
                modify_optimizer_attribute("IPM_IterationsLimit", 500),
            ],
            qp_modifications = [modify_optimizer(Clarabel.Optimizer), silence],
        ) |> values_dict

    # The used optimizer doesn't really converge to the same answer everytime
    # here, we therefore tolerate a wide range of results.
    @test isapprox(d["biomass1"], 10.0, atol = QP_TEST_TOLERANCE)

    sol =
        model |>
        with_changed_bound("biomass1", lower_bound = 10.0) |>
        with_parsimonious_solution(:reaction) |>
        flux_balance_analysis(Clarabel.Optimizer)

    @test isapprox(
        values_dict(:reaction, model, sol)["biomass1"],
        10.0,
        atol = QP_TEST_TOLERANCE,
    )
end

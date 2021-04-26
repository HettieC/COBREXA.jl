
"""
    save_mat_model(model::MetabolicModel, file_name::String; model_name::String="model")

Save a [`MATModel`](@ref) in `model` to a MATLAB file `file_name` in a format
compatible with other MATLAB-based COBRA software.

In case the `model` is not `MATModel`, it will be converted automatically.

`model_name` is the identifier name for the whole model written to the MATLAB
file; defaults to just "model".
"""
function save_mat_model(model::MetabolicModel, file_path::String; model_name = "model")
    m = (typeof(model) == MATModel ? model : convert(MATModel, model)).mat
    matwrite(file_path, Dict(model_name => m))
end

#TODO this needs to get merged into convert function StdModel->MATModel
function _write_model(model::StandardModel, ::Type{MFile}, file_location::String)
    # Some information is lost here, e.g. notes and some annotations.
    S = stoichiometry(model)
    b = balance(model)
    lbs, ubs = bounds(model)

    mdict = Dict(
        "c" => [r.objective_coefficient for r in model.reactions],
        "modelName" => model.id,
        "mets" => [m.id for m in model.metabolites],
        "subSystems" => [r.subsystem for r in model.reactions],
        "b" => Vector(b),
        "metFormulas" => [m.formula for m in model.metabolites],
        "ub" => Vector(ubs),
        "rxnNames" => [r.name for r in model.reactions],
        "description" => model.id,
        "genes" => [g.id for g in model.genes],
        "grRules" => [_unparse_grr(r.grr) for r in model.reactions],
        "S" => Matrix(S),
        "metNames" => [m.name for m in model.metabolites],
        "lb" => Vector(lbs),
        "metCharge" => [m.charge for m in model.metabolites],
        "rxns" => [r.id for r in model.reactions],
        "rxnKEGGID" => [
            join(get(r.annotation, "kegg.reaction", [""]), "; ") for r in model.reactions
        ],
        "rxnECNumbers" =>
            [join(get(r.annotation, "ec-code", [""]), "; ") for r in model.reactions],
        "rxnBiGGID" => [
            join(get(r.annotation, "bigg.reaction", [""]), "; ") for r in model.reactions
        ],
        "rxnSBOTerms" => [get(r.annotation, "sbo", "") for r in model.reactions],
        "metBiGGID" => [
            join(get(m.annotation, "bigg.metabolite", [""]), "; ") for
            m in model.metabolites
        ],
        "metSBOTerms" => [get(m.annotation, "sbo", "") for m in model.metabolites],
        "metKEGGID" => [
            join(get(m.annotation, "kegg.compound", [""]), "; ") for m in model.metabolites
        ],
        "metMetaNetXID" => [
            join(get(m.annotation, "metanetx.chemical", [""]), "; ") for
            m in model.metabolites
        ],
        "metChEBIID" =>
            [join(get(m.annotation, "chebi", [""]), "; ") for m in model.metabolites],
    )

    matwrite(file_location, Dict("model" => mdict))
end

"""
Write a model into a MAT (Matlab) format

NB: Does NOT export general inequality constraints (eg coupling)

See also: `MAT.jl`
"""
function _write_model(model::CoreModel, ::Type{MFile}, file_path::String)
    var_name = "model" # maybe make a field for this in the model?
    matwrite(file_path, Dict(var_name => _convert_to_m_exportable_dict(model)))
end

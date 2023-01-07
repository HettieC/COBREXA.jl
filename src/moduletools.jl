"""
    module ModuleTools

Internal helpers for simplifying the work with COBREXA submodules.

# Exports
$(EXPORTS)
"""
module ModuleTools
macro inc(path...)
    esc(:(include(joinpath(@__DIR__, $(joinpath(String.(path)...) * ".jl")))))
end

macro inc_dir(path...)
    dir = joinpath(@__DIR__, String.(path)...)
    files = filter(endswith(".jl"), readdir(dir; join = true))
    esc(Expr(:block, (:(include($f)) for f in files)...))
end

macro dse()
    :(using DocStringExtensions)
end
@dse

macro inject(mod, code)
    esc(:(Base.eval($mod, $(Expr(:quote, code)))))
end

# export everything from the local namespace that seems exportable
# (inspired by JuMP.jl, thanks!)
macro export_locals()
    quote
        for sym in names(@__MODULE__; all = true, imported = true)
            sym in [Symbol(@__MODULE__), :eval, :include] && continue
            startswith(string(sym), ['_', '#']) && continue
            sym == :Internal && continue
            @eval export $(Expr(:$, :sym))
        end
    end
end

@export_locals
end

"""
@using_all()

A convenience macro that brings the names of all the COBREXA modules into scope.

When calling `COBREXA.@using_all` the following code gets injected:
```
using COBREXA.Types,
    COBREXA.Accessors,
    COBREXA.Analysis,
    COBREXA.Analysis.Modifications,
    COBREXA.Reconstruction,
    COBREXA.Reconstruction.Modifications,
    COBREXA.Utils,
    COBREXA.IO,
    COBREXA.Solver
```
"""
macro using_all()    
    quote
        using COBREXA.Types,
            COBREXA.Accessors,
            COBREXA.Analysis,
            COBREXA.Analysis.Modifications,
            COBREXA.Reconstruction,
            COBREXA.Reconstruction.Modifications,
            COBREXA.Utils,
            COBREXA.IO,
            COBREXA.Solver
    end
end
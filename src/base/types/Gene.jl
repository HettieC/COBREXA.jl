"""
$(TYPEDEF)

# Fields
$(TYPEDFIELDS)
"""
mutable struct Gene
    id::String
    name::Maybe{String}
    notes::Notes
    annotations::Annotations

    Gene(id::String = ""; name = nothing, notes = Notes(), annotations = Annotations()) =
        new(id, name, notes, annotations)
end

"""
Gene(
    id::AbstractString; 
    name = nothing, 
    notes = Notes(), 
    annotations = Annotations(),
)

A convenient constructor for a `Gene`.
"""
Gene(id::AbstractString; name = nothing, notes = Notes(), annotations = Annotations()) =
    Gene(String(id), name, notes, annotations)

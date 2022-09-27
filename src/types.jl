
# make the module for types and load basic abstract types
module Types
using ..ModuleTools
@dse
using SparseArrays, OrderedCollections
using HDF5, SBML, JSON, MAT, Serialization #for the storable types
@inc_dir types abstract
@export_locals
end

# the specialized module for accessors
module Accessors
using ..ModuleTools
@dse
using ..Types
using ..Internal.Macros
@inc_dir types accessors
@export_locals
end

# the modules depend on each other so we have to inject the stuff like this
@inject Types begin
    using ..Accessors

    using ..Internal.Macros
    using ..Log.Internal: @io_log
    @inc_dir types
    @inc_dir types models
    @inc_dir types wrappers

    @export_locals
end

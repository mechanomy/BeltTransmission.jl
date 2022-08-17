
using Test
using Unitful, Unitful.DefaultSymbols
using Plots
using UUIDs
pyplot()
close("all")
# gr()

import Geometry2D
using BeltTransmission

# println(Main.varinfo(@__MODULE__, r"^((?!\#).)*$"; all=true, imported=true, recursive=true)) #regex to remove #eval, #addA entities, not sure what the # 


include("testBeltSegment.jl")
include("testSegmentFree.jl")
include("testPulley.jl")

include("testPulleyPlain.jl")

include("testSynchronous.jl")

include("testSynchronousBeltTable.jl")

include("testPlotsRecipes.jl")

include("testBeltSystem.jl")

include("testOptimizer.jl")

# # also run all examples to detect errors..
# include("../exes/BeltDesign.jl")
# include("../exes/BeltDesign.jl")
# include("../exes/BeltDesign.jl")

# close("all")
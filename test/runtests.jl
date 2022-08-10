
using Test
using Unitful, Unitful.DefaultSymbols
using Plots
using UUIDs
pyplot()
close("all")
# gr()

import Geometry2D
using BeltTransmission

include("testBeltSegment.jl")
include("testSegmentFree.jl")
include("testPulley.jl")

include("testPulleyPlain.jl")

include("testSynchronous.jl")

include("testSynchronousBeltTable.jl")

include("testPlotsRecipes.jl")


# also run all examples to detect errors..
include("../exes/BeltDesign.jl")

# close("all")
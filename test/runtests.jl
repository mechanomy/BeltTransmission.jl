
# using Pkg
# Pkg.activate( normpath(joinpath(@__DIR__, "..")) ) #activate this package

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

close("all")
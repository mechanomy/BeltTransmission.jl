
# using Pkg
# Pkg.activate( normpath(joinpath(@__DIR__, "..")) ) #activate this package

using Test
using Unitful, Unitful.DefaultSymbols
using Plots
# pyplot()
# close("all")
gr()


# Both Geometry2D and BeltTransmission export a method distance(), leading to a collision even though they are differentiated by type, as https://discourse.julialang.org/t/two-modules-with-the-same-exported-function-name-but-different-signature/15231/13
# using Geometry2D #don't really need this here, so import instead
import Geometry2D
using BeltTransmission


include("testBeltSegment.jl")
include("testPulley.jl")
include("testPulleyPlain.jl")
include("testPulleyTiming.jl")

close("all")
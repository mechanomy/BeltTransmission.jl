
using Pkg
Pkg.activate( normpath(joinpath(@__DIR__, "..")) ) #activate this package
using BeltTransmission

BeltTransmission.testPulley()
BeltTransmission.testBeltSegment()



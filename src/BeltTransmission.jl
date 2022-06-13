"""Geometric modeling of 2D closed belt transmissions"""
module BeltTransmission
using Unitful, Unitful.DefaultSymbols
using KeywordDispatch

using PyPlot #can use matplotlib arguments directly
using BPlot
using Printf
using StaticArrays #for defined-length arrays: SVector{3,T}
using Utility
using Geometry2D

using Test


# include("../src/Pulley2D.jl")
include("Pulley2D.jl")
include("BeltSegment.jl")

# using Reexport
# @reexport using Pulley2D
# @reexport using BeltSegment


end # BeltTransmission

# BeltTransmission.Pulley2D.dev()
# function dev()
    # @unit deg "deg" Degree 360/2*pi false
#   ctr = Geometry2D.Point(1u"mm", 3u"mm")
#   axx = Geometry2D.UnitVector(1,0,0)
#   # constructLiteral = Pulley(ctr, 10u"mm", axx, 90u"deg", 270u"deg" )
#   # constructLiteral = Pulley(ctr, 10u"mm", axx, 90u"degree", 270u"degree" )
#   # constructLiteral = BeltTransmission.Pulley2D.Pulley(ctr, 10u"mm", axx, 90deg, 270deg )
#   constructLiteral = BeltTransmission.Pulley2D.Pulley(ctr, 10u"mm", axx, 1u"rad", 2u"rad" )
#   print(constructLiteral)
#   # plot(constructLiteral)
#   # constructLiteral.plot()
# end
# dev()

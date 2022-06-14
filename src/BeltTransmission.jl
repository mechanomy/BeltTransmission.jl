"""Geometric modeling of 2D closed belt transmissions"""
module BeltTransmission
using Unitful, Unitful.DefaultSymbols
using KeywordDispatch

using BPlot
using Printf
using StaticArrays #for defined-length arrays: SVector{3,T}
using Utility
using Geometry2D
using LinearAlgebra:normalize, cross, dot

using Test
using RecipesBase
# using PyPlot #can use matplotlib arguments directly
using Plots
pyplot()
close("all")

include("Pulley2D.jl")
include("BeltSegment.jl")

end # BeltTransmission


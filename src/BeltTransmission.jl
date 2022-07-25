"""Geometric modeling of 2D closed belt transmissions"""
module BeltTransmission

  using Unitful, Unitful.DefaultSymbols
  using KeywordDispatch

  using DocStringExtensions 

  # using BPlot
  using Printf
  using StaticArrays #for defined-length arrays: SVector{3,T}
  using Utility
  using Geometry2D
  using LinearAlgebra:normalize, cross, dot

  using RecipesBase
  include("Pulley.jl")
  include("BeltSegment.jl")

end # BeltTransmission


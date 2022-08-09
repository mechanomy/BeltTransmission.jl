"""
Geometric modeling of 2D closed belt transmissions.

This module models closed belt transmissions with either:
* Plain pulleys with flat belting
* Timing pulleys and timing belts

With the general concept of a 'belt' entailing a continuous element, flat and timing belts add properties that affect which method may be called.
For instance, a flat belt may have an arbitrary length, limited only by fabrication, while toothed belts are defined to have an integer number of teeth.
Likewise, calculations involving tooth pitch are nonsensical if applied to flat or V belts.
The module uses Julia's type system to differentiate between these belt types.

Timing and plain pulleys are specializaitons of AbstractPulley, permitting functions that need only the pulley location, rotation axis, or pitch diameter to accept any argument that maps to AbstractPulley, while allowing those needing tooth properties to specify arguments of TimingPulley type.

Calculations are perfomed on the pulley or belt pitch line.

Exports methods:
$(EXPORTS)

"""
module BeltTransmission

  using Unitful, Unitful.DefaultSymbols
  # @derived_dimension Radian dimension(u"rad")
  # @derived_dimension Degree dimension(u"°")
  # @unit rev "rev" Revolution (2*π)u"rad" false
  # # @derived_dimension Pitch dimension(u"mm/1") #per what in Unitful? Number?
  # Angle{T} = Union{Quantity{T,NoDims,Radian}, Quantity{T,NoDims,Degree}} where T 

  using KeywordDispatch

  using DocStringExtensions 

  using Printf
  using StaticArrays #for defined-length arrays: SVector{3,T}
  using Utility
  using Geometry2D
  using LinearAlgebra:normalize, cross, dot
  using UUIDs

  using RecipesBase

  include("Pulley.jl")

  include("BeltSegment.jl")
  include("SegmentFree.jl")
  # include("SegmentEngaged.jl")

  #specific belt/pulley types
  include("PulleyPlain.jl") #INCLUDE ORDER MATTERS! Must introduce PlainPulley before using it in BS, though this should go away with Abstract types.

  include("PulleySynchronous.jl")
  include("BeltSynchronous.jl")


  struct BeltTrans
    pulleys::Vector{T} where T<:AbstractPulley
    segments::Vector{T} where T<:AbstractSegment
    belt::AbstractBelt
  end
  # calcLength(BT)
  # calcRatios(BT)
  # calcPowerLimits(BT)

end # BeltTransmission


export BeltSystem, calculateRatios, calculateLength

# abstract type AbstractVectorPulley <: Vector{AbstractPulley} end # invalid subtyping
# abstract type AbstractVectorPulley <: Vector{T} where T<:AbstractPulley end
# abstract type AbstractVectorPulley <: AbstractArray{AbstractPulley} end 
# abstract type AbstractVectorPulley <: AbstractArray{T} where T<:AbstractPulley end 
# abstract type AbstractVectorPulley <: AbstractArray{<:AbstractPulley} end 

AbstractVectorPulley = AbstractArray{<:AbstractPulley} 


"""
  A BeltSystem is an ordered set of `pulleys` connected by `segments` of some `belt`.
  $TYPEDFIELDS
"""
struct BeltSystem
  pulleys::Vector{AbstractPulley}
  segments::Vector{AbstractSegment}
  belt::AbstractBelt
end

"""
  $TYPEDSIGNATURES
  Construct a new BeltSystem, creating segments from `pulleys` and `belt`.
"""
BeltSystem(pulleys::Vector{AbstractPulley}, belt::AbstractBelt ) = BeltSystem(pulleys, route2Segments(pulleys), belt )
# calcPowerLimits(BT)

@testitem "BeltSystem constructors" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100), MilliMeter(100)), axis=uk, nGrooves=62, beltPitch=MilliMeter(2), name="1A" )
  pB = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100), MilliMeter(100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="2B" )
  pC = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100),MilliMeter(-100)), axis=uk, nGrooves=80, beltPitch=MilliMeter(2), name="3C" )
  pD = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100),MilliMeter(-100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="4D" )
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(0), MilliMeter(0), MilliMeter(14)), axis=-uk, name="5E") # -uk axis engages the backside of the belt
  pRoute = [pA, pB, pC, pD, pE]
  pSolved = calculateRouteAngles(pRoute)

  belt = SynchronousBelt(pitch=MilliMeter(2), length=MilliMeter(54), width=MilliMeter(6), profile="gt2")

  @test typeof(BeltSystem(pSolved, belt)) <: BeltSystem
end

"""
  $TYPEDSIGNATURES
  Calculate the transmission ratio matrix between all pulleys, returning a matrix of ratios.
  Pulleys are numbered according to their order in `bs`, with the ratio as in [calculateRatio](#BeltTransmission.calculateRatio).
"""
function calculateRatios( bs::BeltSystem )
  return calculateRatios( bs.pulleys )
end

@testitem "calculateRatios" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100), MilliMeter(100)), axis=uk, nGrooves=62, beltPitch=MilliMeter(2), name="1A" )
  pB = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100), MilliMeter(100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="2B" )
  pC = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100),MilliMeter(-100)), axis=uk, nGrooves=80, beltPitch=MilliMeter(2), name="3C" )
  pD = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100),MilliMeter(-100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="4D" )
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(0), MilliMeter(0), MilliMeter(14)), axis=-uk, name="5E") # -uk axis engages the backside of the belt
  pRoute = [pA, pB, pC, pD, pE]
  pSolved = calculateRouteAngles(pRoute)

  belt = SynchronousBelt(pitch=MilliMeter(2), length=MilliMeter(54), width=MilliMeter(6), profile="gt2")

  bs = BeltSystem(pSolved, belt)
  rats = calculateRatios( bs )
  @test rats[1,1] ≈ 1
  @test rats[1,2] ≈ calculateRatio(pA, pB)
  @test rats[2,1] ≈ calculateRatio(pB, pA)
end

"""
  $TYPEDSIGNATURES
  Pass-through to [calculateBeltLength](#BeltTransmission.calculateBeltLength).
"""
function calculateLength( bs::BeltSystem )
  return calculateBeltLength( bs.pulleys )
end

@testitem "calculateLength" begin
  using Geometry2D, UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100), MilliMeter(100)), axis=uk, nGrooves=62, beltPitch=MilliMeter(2), name="1A" )
  pB = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100), MilliMeter(100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="2B" )
  pC = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100),MilliMeter(-100)), axis=uk, nGrooves=80, beltPitch=MilliMeter(2), name="3C" )
  pD = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100),MilliMeter(-100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="4D" )
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(0), MilliMeter(0), MilliMeter(14)), axis=-uk, name="5E") # -uk axis engages the backside of the belt
  pRoute = [pA, pB, pC, pD, pE]
  pSolved = calculateRouteAngles(pRoute)

  belt = SynchronousBelt(pitch=MilliMeter(2), length=MilliMeter(54), width=MilliMeter(6), profile="gt2")

  bs = BeltSystem(pSolved, belt)
  @test calculateLength(bs) ≈ calculateBeltLength(pSolved)
end

# """
#   $TYPEDSIGNATURES
#   Given a belt system, find the pulley position(s) that satisfy the given belt length.
#   It does this through a linear optmization whose objective is to minimze the error between the given belt's length and the [calculateBeltLength()](#BeltTransmission.calculateBeltLength).
#   Since pulleys can each move in <x,y>, the 

#   `which` is an index or array to the pulley(s) that may be moved; by default all pulleys may be moved and the algorithm minimizes the total pulley movement.
#   The pulleys in the `belt` system need to be placed in approximate locations in order to determine the belt routing.
#   That is even if their positions are not final some position must be given when creating the pulleys to permit the belt length to be accurately calculated.
#   Pulleys are constrained from overlap

#   In a two-belt system this problem devolves to calculating the center distance between two pulleys:
#   '''@example
    
#   '''

#   In larger systems, 
# """
# function calculateCenterDistance( bs::BeltSystem, which::Integer )
# # function calculateCenterDistance( a::AbstractPulley, b::AbstractPulley, belt::AbstractBelt )
# end

@recipe(PlotPulleySystem, pulleyVector) do scene 
  Theme()
  Attributes(
    colorBeltFree=:cyan,
    colorBeltPulley=:magenta,
    colormapBelt=nothing, # use solid colorBeltFree and colorBeltPulley, else use this colormap for both
    colorPulley="#4050ff99",
    widthBelt=3,
  )
end
function Makie.plot!(pps::PlotPulleySystem)
  psys = pps[:pulleyVector][] # extract the PulleyVector from the pps, [] to unroll the observable
  nr = length(psys)

  # plot each pulley and create FreeSegments between arrive/departs
  # plot segments first, 'behind' pulleys
  for ir in 1:nr
    if isnothing(pps[:colormapBelt][])
      plotfreesegment!(pps, FreeSegment( depart=psys[ir], arrive=psys[Utility.iNext(ir,nr)]), color=pps[:colorBeltFree][], linewidth=pps[:widthBelt][] )
    else
      plotfreesegment!(pps, FreeSegment( depart=psys[ir], arrive=psys[Utility.iNext(ir,nr)]), colormap=pps[:colormapBelt][], linewidth=pps[:widthBelt][] )
    end
  end

  #plot pulleys
  for ir in 1:nr
    if isnothing(pps[:colormapBelt][])
      plotpulley!(pps, psys[ir], color=pps[:colorBeltPulley][], linewidth=pps[:widthBelt][], colorPulley=pps[:colorPulley][])
    else
      plotpulley!(pps, psys[ir], colormap=pps[:colormapBelt][], linewidth=pps[:widthBelt][], colorPulley=pps[:colorPulley][])
    end
  end

  return pps
end

@testitem "plotPulleySystem Recipe" begin
  using UnitTypes, Geometry2D
  using CairoMakie, MakieCore
  ppa = PlainPulley(Geometry2D.Circle(MilliMeter(0),MilliMeter(0), MilliMeter(4)), Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyA") 
  ppb = PlainPulley(Geometry2D.Circle(MilliMeter(10),MilliMeter(10), MilliMeter(6)), -Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyB") 
  spa = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(20),MilliMeter(40)), axis=Geometry2D.uk, nGrooves=22, beltPitch=MilliMeter(2), arrive=Radian(1), depart=Radian(4), name="SyncPulleyA" )
  spb = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(0),MilliMeter(40)), axis=Geometry2D.uk, nGrooves=12, beltPitch=MilliMeter(2), arrive=Radian(1), depart=Radian(4), name="SyncPulleyB" )

  route = [ppa, ppb, spa, spb]
  solved = calculateRouteAngles(route)
  
  fig = Figure(backgroundcolor="#bbb", size=(1000,1000))
  axs = Axis(fig[1,1], xlabel="X", ylabel="Y", aspect=DataAspect())
  p = plotpulleysystem!(axs,solved, colorBeltFree=:red, colorBeltPulley=:green, colorPulley=:orange, widthBelt=4)
  # display(fig)
  @test typeof(p) <: MakieCore.Plot

  # plotpulleysystem!(axs,solved, colormapBelt=:jet, colorPulley=:orange, widthBelt=8)
end
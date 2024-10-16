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

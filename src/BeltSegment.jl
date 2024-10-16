# A belt segment is some section of a belt, delineated by lines of contact with pulleys
# A free belt segment is a free section of belt beginning and ending at a pulley tangent point.  It is assumed straight and loaded only in tension. 
# An engaged belt segment is nominally in contact with some pulley

export AbstractSegment, AbstractBelt, printRoute
abstract type AbstractSegment end

abstract type AbstractBelt end

"""
    printRoute(route::Vector{AbstractPulley})
  Prints the Pulleys and total belt length for the given `route`.
"""
function printRoute(route::Vector{T}) where T<:AbstractPulley
  for r in route #r is pulleys
    println(pulley2String(r))
  end
end
@testitem "printRoute" begin
  using Geometry2D
  using UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]

  solved = calculateRouteAngles(route)
  printRoute(solved)
  @test true # how to test console print?
end


"""
    printSegments(segments::Vector{FreeSegment})
  Prints the Segments, and total belt length for the given `route`.
"""
function printSegments(segments::Vector{T}) where T<:AbstractSegment
  for s in segments
    println(toStringPoints(s))
  end
  # lTotal = calculateBeltLength(segments)
  # println("total belt length = $lTotal") #No knowledge of the belt pitch, so can't list the correct belt
end
@testitem "printSegments" begin
  using Geometry2D
  using UnitTypes
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(10)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  route = [pA, pB, pC, pD, pE]

  solved = calculateRouteAngles(route)
  printSegments( route2Segments( solved ) )
  @test true
end


# function calculateFreeLengths(segments::Vector{T}) where T<:AbstractSegment
# end
# function calculateTransmissionRatios(segments::Vector{T}) where T<:AbstractSegment
# end
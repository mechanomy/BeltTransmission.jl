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

@recipe(PlotFreeSegment, segment) do scene
  Theme()
  Attributes(
    widthBelt=3,
    colorBelt=:cyan,
    # label=toStringShort(segment) # segment not found?...
  )
end
function Makie.plot!(pfs::PlotFreeSegment)
  seg = pfs[:segment][] # extract the segment from the pfs, [] to unroll the observable

  pd = getDeparturePoint( seg )
  pa = getArrivalPoint( seg )
  xs = LinRange( toBaseFloat(pd.x), toBaseFloat(pa.x), 100 )
  ys = LinRange( toBaseFloat(pd.y), toBaseFloat(pa.y), 100 )
  lines!(pfs, xs,ys, color=pfs[:colorBelt][], linewidth=pfs[:widthBelt][])#, label=pfs[:label][])
  return pfs
end

@testitem "plotFreeSegment Recipe" begin
  using UnitTypes, Geometry2D
  using CairoMakie, MakieCore
  ppa = PlainPulley(Geometry2D.Circle(MilliMeter(0),MilliMeter(0), MilliMeter(4)), Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyA") 
  ppb = PlainPulley(Geometry2D.Circle(MilliMeter(10),MilliMeter(10), MilliMeter(6)), -Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyB") 
  spc = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(20),MilliMeter(40)), axis=Geometry2D.uk, nGrooves=22, beltPitch=MilliMeter(2), arrive=Radian(1), depart=Radian(4), name="SyncPulleyA" )
  
  segab = FreeSegment(depart=ppa, arrive=ppb)
  segac = FreeSegment(depart=ppa, arrive=spc)
  segbc = FreeSegment(depart=ppb, arrive=spc)

  fig = Figure(backgroundcolor="#bbb", size=(1000,1000))
  axs = Axis(fig[1,1], xlabel="X", ylabel="Y", aspect=DataAspect())
  p = plotfreesegment!(axs, segab, colorBelt=:red, widthBelt=3)
  p = plotfreesegment!(axs, segbc, colorBelt=:green, widthBelt=8)
  p = plotfreesegment!(axs, segac, colorBelt=:yellow, widthBelt=10)
  # display(fig)

  @test typeof(p) <: MakieCore.Plot
end

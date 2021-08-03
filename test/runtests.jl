
using Test
using Unitful
using Geometry2D
include("../src/BeltTransmission.jl")

# test rationale:
# - test against changes in Geometry2D?
function testPulley()
  ctr = Geometry2D.Point(3u"mm",5u"mm")
  ref = BeltTransmission.Pulley2D.Pulley( Geometry2D.Point(3u"mm",5u"mm"), 3u"mm", Geometry2D.UnitVector([0,0,1]) )
  pul = BeltTransmission.Pulley2D.Pulley(center=ctr, radius=3u"mm", axis=Geometry2D.UnitVector([0,0,1]))
  # pulley = Pulley2D.Pulley( point, radius, axis, angle0, angle0 )
  # pulley = Pulley2D.Pulley( center=point, radius=radius, axis=axis )
  # pulley = Pulley2D.Pulley( )
  # pulley = Pulley2D.Pulley( xmm=3.3, ymm=4.4, radiusmm=5.5 )
  # pulley = Pulley2D.Pulley( x=3u"mm", y=4u"mm", radius=5u"mm" )
  # println(pulley) #does work
  return ref.radius == pul.radius
end

function testCalcWrapped()
  pa = BeltTransmission.Pulley2D.Pulley(center=ctr, radius=3u"mm", axis=Geometry2D.UnitVector([0,0,1]), aArrive=90u"deg", aDepart=180u"deg")

  return pa.calcWrappedLength()==90u"deg"
end

@testset "test Pulley2D" begin
  @test testPulley()
  @test testCalcWrapped()
end




# test rationale:
# - test against changes in Pulley2D, Geometry2D?
# - test that the belt routing is 'correct'
function testBeltSegment()
  # println("BeltSegment.test()")
  # close("all")
  # println(Base.loaded_modules)

  uk = Geometry2D.UnitVector([0,0,1])
  pA = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",0u"mm"), radius=62u"mm", axis=uk)
  pB = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(146u"mm",80u"mm"), radius=43u"mm", axis=uk)
  pC = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(46u"mm",180u"mm"), radius=43u"mm", axis=uk)
  pD = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",100u"mm"), radius=4u"mm", axis=-uk) # axis is outside, rotates negatively, solves correctly

  # angles = findTangents(a=pA, b=pB, plotResult=true)

  #convention: pulleys listed in 'positive' belt rotation order
  route = [pA, pB, pC, pD]
  solved = BeltTransmission.BeltSegment.calculateSegments(route, false)
  belt = BeltTransmission.BeltSegment.routeToBeltSystem(solved)
  BeltTransmission.BeltSegment.printBeltSystem(belt)
  # plotBeltSystem(belt)
  return true
end

@testset "test BeltSegment" begin
  @test testBeltSegment()
end
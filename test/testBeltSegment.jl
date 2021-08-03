using Test
using Unitful
using Geometry2D

include("../src/BeltSegment.jl")
# test rationale:
# - test against changes in Pulley2D, Geometry2D?
# - test that the belt routing is 'correct'
function testBeltSegment()
  # println("BeltSegment.test()")
  # close("all")
  # println(Base.loaded_modules)

  uk = Geometry2D.UnitVector([0,0,1])
  pA = Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",0u"mm"), radius=62u"mm", axis=uk)
  pB = Pulley2D.Pulley( center=Geometry2D.Point(146u"mm",80u"mm"), radius=43u"mm", axis=uk)
  pC = Pulley2D.Pulley( center=Geometry2D.Point(46u"mm",180u"mm"), radius=43u"mm", axis=uk)
  pD = Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",100u"mm"), radius=4u"mm", axis=-uk) # axis is outside, rotates negatively, solves correctly

  # angles = findTangents(a=pA, b=pB, plotResult=true)

  #convention: pulleys listed in 'positive' belt rotation order
  route = [pA, pB, pC, pD]
  solved = BeltSegment.calculateSegments(route, false)
  belt = BeltSegment.routeToBeltSystem(solved)
  BeltSegment.printBeltSystem(belt)
  # plotBeltSystem(belt)
  return true
end

@testset "test BeltSegment" begin
  @test testBeltSegment()
end
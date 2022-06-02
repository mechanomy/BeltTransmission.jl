
using Test
using Unitful, Unitful.DefaultSymbols
using Geometry2D

using BeltTransmission
# include("../src/BeltTransmission.jl")

# test rationale:
# - check that Geometry2D is handling Point units
# - check that radius is entered correctly
@testset "Pulley2D unit handling" begin
  uk = Geometry2D.uk

  actr = Geometry2D.Point(3000u"mm",5000u"mm")
  arad = 4000u"mm"
  apul  = BeltTransmission.Pulley2D.Pulley(actr, arad, uk, "A" )

  bctr = Geometry2D.Point(3u"m",5u"m")
  brad = 4000u"mm"
  bpul  = BeltTransmission.Pulley2D.Pulley(bctr, brad, uk, "B" )

  cctr = Geometry2D.Point(3u"m",5u"m")
  crad = 4u"m"
  cpul  = BeltTransmission.Pulley2D.Pulley(cctr, crad, uk, "C" )


  #despite different units, these three pulleys should overlap
  BeltTransmission.Pulley2D.plotPulley( apul, colorPulley="red", colorBelt="none")
  BeltTransmission.Pulley2D.plotPulley( bpul, colorPulley="blue", colorBelt="none")
  BeltTransmission.Pulley2D.plotPulley( cpul, colorPulley="cyan", colorBelt="none")
  
  @test apul.center.x == bpul.center.x 
  @test apul.radius == cpul.radius; # this isn't a great test, 
end


# test rationale:
# - test for constructor consistiency
# - test against changes in Geometry2D?
@testset "Pulley2D constructors" begin
  ctr = Geometry2D.Point(3u"mm",5u"mm")
  uk = Geometry2D.uk
  rad = 4u"mm"
  aa = 1u"rad"
  ad = 2u"rad"
  stc = BeltTransmission.Pulley2D.Pulley(ctr, rad, uk, aa, ad, "struct" )
  cran = BeltTransmission.Pulley2D.Pulley(ctr, rad, uk, "cran" )
  cra  = BeltTransmission.Pulley2D.Pulley(ctr, rad, uk )
  crn  = BeltTransmission.Pulley2D.Pulley(ctr, rad, "crn" )
  cr   = BeltTransmission.Pulley2D.Pulley(ctr, rad )
  key  = BeltTransmission.Pulley2D.PulleyKw(center=ctr, radius=rad, axis=uk, name="key" )

  # println(pulley) #does work
  @test stc.center == ctr
  @test stc.center == cran.center
  @test stc.center == cra.center
  @test stc.center == crn.center
  @test stc.center == cr.center
  @test stc.center == key.center
  @test stc.radius == rad
  @test stc.radius == cran.radius
  @test stc.radius == cra.radius
  @test stc.radius == crn.radius
  @test stc.radius == cr.radius
  @test stc.radius == key.radius
  @test stc.axis == uk
  @test stc.axis == cran.axis
  @test stc.axis == cra.axis
  @test stc.axis == crn.axis
  @test stc.axis == cr.axis
  @test stc.axis == key.axis
  @test stc.name == "struct"
  @test cran.name == "cran"
  @test cra.name == ""
  @test crn.name == "crn"
  @test cr.name == ""
  @test key.name == "key"
end

# function testCalcWrapped()
#   pa = BeltTransmission.Pulley2D.Pulley(ctr, 3u"mm", Geometry2D.uk, 90u"°", 180u"°", "pa")
#   return pa.calcWrappedLength()==90u"°"
# end




# test rationale:
# - test against changes in Pulley2D, Geometry2D?
# - test that the belt routing is 'correct'
@testset "BeltSegment test" begin
  # println("BeltSegment.test()")
  close("all")
  # println(Base.loaded_modules)

  uk = Geometry2D.UnitVector([0,0,1])
  pA = BeltTransmission.Pulley2D.PulleyKw( center=Geometry2D.Point(0u"mm",0u"mm"), radius=62u"mm", axis=uk, name="pA")
  pB = BeltTransmission.Pulley2D.PulleyKw( center=Geometry2D.Point(146u"mm",80u"mm"), radius=43u"mm", axis=uk, name="pB") #positive-going zero cross
  pC = BeltTransmission.Pulley2D.PulleyKw( center=Geometry2D.Point(40u"mm",180u"mm"), radius=43u"mm", axis=uk, name="pC")
  pD = BeltTransmission.Pulley2D.PulleyKw( center=Geometry2D.Point(0u"mm",100u"mm"), radius=14u"mm", axis=-uk, name="pD") #negative-going zero cross 
  pE = BeltTransmission.Pulley2D.PulleyKw( center=Geometry2D.Point(100u"mm",0u"mm"), radius=14u"mm", axis=-uk, name="pE") #negative-going


  # angles = findTangents(a=pA, b=pB, plotResult=true)

  #convention: pulleys listed in 'positive' belt rotation order
  route = [pA, pE, pB, pC, pD]
  solved = BeltTransmission.BeltSegment.calculateSegments(route, false)
  belt = BeltTransmission.BeltSegment.routeToBeltSystem(solved)
  length = BeltTransmission.BeltSegment.calculateBeltLength(belt)
  BeltTransmission.BeltSegment.printBeltSystem(belt)
  BeltTransmission.BeltSegment.plotBeltSystem(belt)

  # print(solved)

  # lA = BeltTransmission.Pulley2D.calculateWrappedLength(solved[1])
  # lE = BeltTransmission.Pulley2D.calculateWrappedLength(solved[2])
  # lB = BeltTransmission.Pulley2D.calculateWrappedLength(solved[3])
  # lC = BeltTransmission.Pulley2D.calculateWrappedLength(solved[4])
  # lD = BeltTransmission.Pulley2D.calculateWrappedLength(solved[5])
  # print("wrappedA: ", lA, "\n")
  # print("wrappedB: ", lB, "\n")
  # print("wrappedC: ", lC, "\n")
  # print("wrappedD: ", lD, "\n")
  # print("wrappedE: ", lE, "\n")

  @test length ≈ 0.8395731136345521u"m"
end
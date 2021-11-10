
using Test
using Unitful
using Geometry2D
include("../src/BeltTransmission.jl")

# test rationale:
# - test for constructor consistiency
# - test against changes in Geometry2D?
function testPulley()
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
  ret = true
  ret &= stc.center == ctr
  ret &= stc.center == cran.center
  ret &= stc.center == cra.center
  ret &= stc.center == crn.center
  ret &= stc.center == cr.center
  ret &= stc.center == key.center
  ret &= stc.radius == rad
  ret &= stc.radius == cran.radius
  ret &= stc.radius == cra.radius
  ret &= stc.radius == crn.radius
  ret &= stc.radius == cr.radius
  ret &= stc.radius == key.radius
  ret &= stc.axis == uk
  ret &= stc.axis == cran.axis
  ret &= stc.axis == cra.axis
  ret &= stc.axis == crn.axis
  ret &= stc.axis == cr.axis
  ret &= stc.axis == key.axis
  ret &= stc.name == "struct"
  ret &= cran.name == "cran"
  ret &= cra.name == ""
  ret &= crn.name == "crn"
  ret &= cr.name == ""
  ret &= key.name == "key"
  return ret
end

# function testCalcWrapped()
#   pa = BeltTransmission.Pulley2D.Pulley(ctr, 3u"mm", Geometry2D.uk, 90u"°", 180u"°", "pa")
#   return pa.calcWrappedLength()==90u"°"
# end

@testset "test Pulley2D" begin
  @test testPulley()
  # @test testCalcWrapped()
end




# test rationale:
# - test against changes in Pulley2D, Geometry2D?
# - test that the belt routing is 'correct'
function testBeltSegment()
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

  return length ≈ 0.8395731136345521u"m"
end
@testset "test BeltSegment" begin
  @test testBeltSegment()
end
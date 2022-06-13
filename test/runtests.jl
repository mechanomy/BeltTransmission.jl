
using Pkg
Pkg.activate( normpath(joinpath(@__DIR__, "..")) ) #activate this package
using Test
using Unitful, Unitful.DefaultSymbols
using Geometry2D

using BeltTransmission

  # tdir = tempdir()
  # bpath = joinpath(tdir, "generateBeltTable.csv") 

@testset "Test Pulley2D constructors" begin
  ctr = Geometry2D.Point(3u"mm",5u"mm")
  uk = Geometry2D.UnitVector([0,0,1])
  rad = 4u"mm"
  aa = 1u"rad"
  ad = 2u"rad"

  @test typeof( BeltTransmission.Pulley2D.Pulley(ctr, rad, uk, aa, ad, "struct" ) ) <: BeltTransmission.Pulley2D.Pulley
  @test typeof( BeltTransmission.Pulley2D.Pulley(ctr, rad, uk, "cran" ) ) <: BeltTransmission.Pulley2D.Pulley
  @test typeof( BeltTransmission.Pulley2D.Pulley(ctr, rad, uk ) ) <: BeltTransmission.Pulley2D.Pulley
  @test typeof( BeltTransmission.Pulley2D.Pulley(ctr, rad, "crn" ) ) <: BeltTransmission.Pulley2D.Pulley
  @test typeof( BeltTransmission.Pulley2D.Pulley(ctr, rad ) ) <: BeltTransmission.Pulley2D.Pulley
  @test typeof( BeltTransmission.Pulley2D.Pulley(center=ctr, radius=rad, axis=uk, name="key" ) ) <: BeltTransmission.Pulley2D.Pulley
end


# todo: include/use SynchronousBelt as needed

# todo: switch to plots.jl so that we are backend independent? What is the cost of this?
# todo: make tests for each function


# @testset "calcWrappedLength" begin
#   pa = BeltTransmission.Pulley2D.Pulley(Geometry2D.Point(0mm, 0mm), 3u"mm", Geometry2D.uk, 90u"°", 180u"°", "pa")
#   @test pa.calculateWrappedLength()==90u"°"
# end


@testset "Test BeltSegment constructors" begin
  uk = Geometry2D.UnitVector([0,0,1])
  pA = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",0u"mm"), radius=62u"mm", axis=uk, name="pA")
  pB = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(100u"mm",100u"mm"), radius=43u"mm", axis=uk, name="pB") #positive-going zero cross
  bs = BeltTransmission.BeltSegment.Segment( arrive=pA.center, depart=pB.center )
  @test Geometry2D.isapprox(bs.length, 141.421mm, rtol=1e-3)
end



# # test rationale:
# # - test against changes in Pulley2D, Geometry2D?
# # - test that the belt routing is 'correct'
# @testset "BeltSegment test" begin
#   # println("BeltSegment.test()")
#   close("all")
#   # println(Base.loaded_modules)

#   uk = Geometry2D.UnitVector([0,0,1])
#   pA = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",0u"mm"), radius=62u"mm", axis=uk, name="pA")
#   pB = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(146u"mm",80u"mm"), radius=43u"mm", axis=uk, name="pB") #positive-going zero cross
#   pC = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(40u"mm",180u"mm"), radius=43u"mm", axis=uk, name="pC")
#   pD = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(0u"mm",100u"mm"), radius=14u"mm", axis=-uk, name="pD") #negative-going zero cross 
#   pE = BeltTransmission.Pulley2D.Pulley( center=Geometry2D.Point(100u"mm",0u"mm"), radius=14u"mm", axis=-uk, name="pE") #negative-going

#   # angles = findTangents(a=pA, b=pB, plotResult=true)

#   #convention: pulleys listed in 'positive' belt rotation order
#   route = [pA, pE, pB, pC, pD]
#   solved = BeltTransmission.BeltSegment.calculateSegments(route, false)
#   belt = BeltTransmission.BeltSegment.routeToBeltSystem(solved)
#   length = BeltTransmission.BeltSegment.calculateBeltLength(belt)
#   BeltTransmission.BeltSegment.printBeltSystem(belt)
#   BeltTransmission.BeltSegment.plotBeltSystem(belt)

#   # print(solved)

#   # lA = BeltTransmission.Pulley2D.calculateWrappedLength(solved[1])
#   # lE = BeltTransmission.Pulley2D.calculateWrappedLength(solved[2])
#   # lB = BeltTransmission.Pulley2D.calculateWrappedLength(solved[3])
#   # lC = BeltTransmission.Pulley2D.calculateWrappedLength(solved[4])
#   # lD = BeltTransmission.Pulley2D.calculateWrappedLength(solved[5])
#   # print("wrappedA: ", lA, "\n")
#   # print("wrappedB: ", lB, "\n")
#   # print("wrappedC: ", lC, "\n")
#   # print("wrappedD: ", lD, "\n")
#   # print("wrappedE: ", lE, "\n")

#   @test length ≈ 0.8395731136345521u"m"
# end
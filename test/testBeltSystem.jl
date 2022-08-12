
uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = SynchronousPulley( center=Geometry2D.Point( 100mm, 100mm), axis=uk, nGrooves=62, beltPitch=2mm, name="1A" )
pB = SynchronousPulley( center=Geometry2D.Point(-100mm, 100mm), axis=uk, nGrooves=30, beltPitch=2mm, name="2B" )
pC = SynchronousPulley( center=Geometry2D.Point(-100mm,-100mm), axis=uk, nGrooves=80, beltPitch=2mm, name="3C" )
pD = SynchronousPulley( center=Geometry2D.Point( 100mm,-100mm), axis=uk, nGrooves=30, beltPitch=2mm, name="4D" )
pE = PlainPulley( pitch=Geometry2D.Circle(   0u"mm",   0u"mm", 14u"mm"), axis=-uk, name="5E") # -uk axis engages the backside of the belt
pRoute = [pA, pB, pC, pD, pE]
pSolved = calculateRouteAngles(pRoute)

belt = SynchronousBelt(pitch=2mm, length=54mm, width=6mm, profile="gt2")

@testset "BeltSystem constructors" begin
  @test typeof(BeltSystem(pSolved, belt)) <: BeltSystem
end

@testset "calculateRatios" begin
  bs = BeltSystem(pSolved, belt)
  rats = calculateRatios( bs )
  @test rats[1,1] ≈ 1
  @test rats[1,2] ≈ calculateRatio(pA, pB)
  @test rats[2,1] ≈ calculateRatio(pB, pA)
end


@testset "calculateLength" begin
  bs = BeltSystem(pSolved, belt)
  @test calculateLength(bs) ≈ calculateBeltLength(pSolved)
end
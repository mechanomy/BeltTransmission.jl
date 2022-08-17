# all of these should succeed for all pulley types...for p in [pulleys array]: ?

# test cos domain error from overlapping or unfeasible belt routings?

@testset "calculateWrappedAngle" begin
  cir = Geometry2D.Circle(3u"mm",5u"mm", 4u"mm" )
  pa = PlainPulley(cir, Geometry2D.uk, 1u"rad", 2u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == 1u"rad"

  pa = PlainPulley(cir, Geometry2D.uk, 1u"rad", 0u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == (2*π-1)u"rad" #from arrive to depart

  pa = PlainPulley(cir, Geometry2D.uk, 0u"rad", 7u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == 7u"rad" 
end

@testset "calculateWrappedLength" begin
  cir = Geometry2D.Circle(3u"mm",5u"mm", 4u"mm" )
  pa = PlainPulley(cir, Geometry2D.uk, 1u"rad", 2u"rad", "struct" ) 
  @test calculateWrappedLength( pa ) == 4u"mm"

  @test typeof(pa) <: AbstractPulley
  @test pitchLength(pa) ≈ 2*π*4mm
end

@testset "pulley2Circle" begin #not a useful test
  pa = PlainPulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 2u"rad", "pulley") 
  circle = pulley2Circle( pa )
  @test typeof(circle) <: Geometry2D.Circle
  @test circle.center.x == 0mm
  @test circle.center.y == 0mm
  @test circle.radius == 4mm
end

@testset "calculateWrappedLength" begin
  pa = PlainPulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 2u"rad", "pulley") 
  @test typeof( pulley2String(pa) ) <: String #this can't break...but still want to exercise the function
end


@testset "calculateRatio" begin
  uk = Geometry2D.uk
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 15u"mm"), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( 80u"mm",-200u"mm", 14u"mm"), axis=-uk, name="E") 
  solved = calculateRouteAngles([pA,pB,pC,pD,pE])
  @test calculateRatio(pA, pB) < 1 # vbelt = wA*rA = wB*rB; wB = wA * rA/rB = wA * 1+
  @test calculateRatio(pA, pB) ≈ pA.pitch.radius/pB.pitch.radius
  @test calculateRatio(pA, pC) ≈ pA.pitch.radius/pC.pitch.radius
  @test calculateRatio(pA, pE) ≈ -pA.pitch.radius/pE.pitch.radius # A and E rotate oppositely
end

@testset "calculateRatios" begin
  uk = Geometry2D.uk
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 15u"mm"), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( 80u"mm",-200u"mm", 14u"mm"), axis=-uk, name="E") 

  solved = calculateRouteAngles([pA,pB,pC,pD,pE])
  rats = calculateRatios( solved )
  @test rats[1,1] ≈ 1
  @test rats[1,2] ≈ calculateRatio(pA, pB)
  @test rats[2,1] ≈ calculateRatio(pB, pA)
end


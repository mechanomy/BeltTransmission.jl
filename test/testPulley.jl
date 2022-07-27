

@testset "calculateWrappedAngle" begin
  cir = Geometry2D.Circle(3u"mm",5u"mm", 4u"mm" )
  pa = PlainPulley(cir, uk, 1u"rad", 2u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == 1u"rad"

  pa = PlainPulley(cir, uk, 1u"rad", 0u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == (2*π-1)u"rad" #from arrive to aDepart

  pa = PlainPulley(cir, uk, 0u"rad", 7u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == 7u"rad" 
end

@testset "calculateWrappedLength" begin
  cir = Geometry2D.Circle(3u"mm",5u"mm", 4u"mm" )
  pa = PlainPulley(cir, uk, 1u"rad", 2u"rad", "struct" ) 
  @test calculateWrappedLength( pa ) == 4u"mm"
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




@testset "plotPulley" begin
  pyplot()
  pa = PlainPulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 4u"rad", "pulleyA") 
  pb = PlainPulley(Geometry2D.Circle(10mm,0mm, 4mm), -Geometry2D.uk, 1u"rad", 4u"rad", "pulleyB") 
  p = plot(pa, reuse=false)
  p = plot!(pb)
  display(p);

  @test true
end



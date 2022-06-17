@testset "Test constructors" begin
  ctr = Geometry2D.Point(3u"mm",5u"mm")
  uk = Geometry2D.UnitVector([0,0,1])
  rad = 4u"mm"
  aa = 1u"rad"
  ad = 2u"rad"

  @test typeof( Pulley(Geometry2D.Circle(ctr, rad), uk, aa, ad, "struct" ) ) <: Pulley
  @test typeof( Pulley(ctr, rad, uk, "cran" ) ) <: Pulley
  @test typeof( Pulley(ctr, rad, uk ) ) <: Pulley
  @test typeof( Pulley(ctr, rad, "crn" ) ) <: Pulley
  @test typeof( Pulley(ctr, rad, "name" )) <: Pulley
  @test typeof( Pulley(center=ctr, radius=rad, axis=uk, name="key" ) ) <: Pulley
  @test typeof( Pulley(circle=Geometry2D.Circle(ctr, rad), axis=uk, name="circle key" ) ) <: Pulley
end

@testset "pulley2String" begin
  p = Pulley(Geometry2D.Circle(1mm, 2mm, 3mm), Geometry2D.uk, 1u"rad", 2u"rad", "struct" ) 
  @test pulley2String(p) == "pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
end

@testset "calculateWrappedAngle" begin
  cir = Geometry2D.Circle(3u"mm",5u"mm", 4u"mm" )
  pa = Pulley(cir, uk, 1u"rad", 2u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == 1u"rad"

  pa = Pulley(cir, uk, 1u"rad", 0u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == (2*π-1)u"rad" #from aArrive to aDepart

  pa = Pulley(cir, uk, 0u"rad", 7u"rad", "struct" ) 
  @test calculateWrappedAngle( pa ) == 7u"rad" 
end

@testset "calculateWrappedLength" begin
  cir = Geometry2D.Circle(3u"mm",5u"mm", 4u"mm" )
  pa = Pulley(cir, uk, 1u"rad", 2u"rad", "struct" ) 
  @test calculateWrappedLength( pa ) == 4u"mm"
end

@testset "pulley2Circle" begin #not a useful test
  pa = Pulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 2u"rad", "pulley") 
  circle = pulley2Circle( pa )
  @test typeof(circle) <: Geometry2D.Circle
  @test circle.center.x == 0mm
  @test circle.center.y == 0mm
  @test circle.radius == 4mm
end

@testset "calculateWrappedLength" begin
  pa = Pulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 2u"rad", "pulley") 
  @test typeof( pulley2String(pa) ) <: String #this can't break...but still want to exercise the function
end

@testset "plotPulley" begin
  pyplot()
  pa = Pulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 4u"rad", "pulleyA") 
  pb = Pulley(Geometry2D.Circle(10mm,0mm, 4mm), -Geometry2D.uk, 1u"rad", 4u"rad", "pulleyB") 
  p = plot(pa, reuse=false)
  p = plot!(pb)
  display(p);

  @test true
end



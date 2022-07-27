
@testset "Test constructors" begin
  ctr = Geometry2D.Point(3u"mm",5u"mm")
  uk = Geometry2D.UnitVector([0,0,1])
  rad = 4u"mm"
  aa = 1u"rad"
  ad = 2u"rad"

  @test typeof( PlainPulley(Geometry2D.Circle(ctr, rad), uk, aa, ad, "struct" ) ) <: AbstractPulley
  @test typeof( PlainPulley(Geometry2D.Circle(ctr, rad), uk, aa, ad, "struct" ) ) <: PlainPulley
  @test typeof( PlainPulley(ctr, rad, uk, "cran" ) ) <: PlainPulley
  @test typeof( PlainPulley(ctr, rad, uk ) ) <: PlainPulley
  @test typeof( PlainPulley(ctr, rad, "crn" ) ) <: PlainPulley
  @test typeof( PlainPulley(ctr, rad, "name" )) <: PlainPulley
  @test typeof( PlainPulley(center=ctr, radius=rad, axis=uk, name="key" ) ) <: PlainPulley
  @test typeof( PlainPulley(circle=Geometry2D.Circle(ctr, rad), axis=uk, name="circle key" ) ) <: PlainPulley
end

@testset "pulley2String" begin
  p = PlainPulley(Geometry2D.Circle(1mm, 2mm, 3mm), Geometry2D.uk, 1u"rad", 2u"rad", "struct" ) 
  @test pulley2String(p) == "pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
end
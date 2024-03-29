
@testset "Test constructors" begin
  ctr = Geometry2D.Point(3u"mm",5u"mm")
  rad = 4u"mm"
  aa = 1u"rad"
  ad = 2u"rad"

  @test typeof( PlainPulley(Geometry2D.Circle(ctr, rad), Geometry2D.uk, aa, ad, "struct" ) ) <: AbstractPulley
  @test typeof( PlainPulley(Geometry2D.Circle(ctr, rad), Geometry2D.uk, aa, ad, "struct" ) ) <: PlainPulley
  @test typeof( PlainPulley(pitch=Geometry2D.Circle(ctr, rad), axis=Geometry2D.uk, name="circle key" ) ) <: PlainPulley

  tp = PlainPulley(Geometry2D.Circle(1mm, 2mm, 3mm), Geometry2D.uk, 1u"rad", 2u"rad", "struct" ) 
  tc = PlainPulley(tp, 1.1u"rad", 2.2u"rad")
  @test typeof(tc) <: AbstractPulley

end

@testset "pulley2String" begin
  p = PlainPulley(Geometry2D.Circle(1mm, 2mm, 3mm), Geometry2D.uk, 1u"rad", 2u"rad", "struct" ) 
  @test pulley2String(p) == "PlainPulley[struct] @ [1.000mm,2.000mm] r[3.000mm] arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000mm]"
end



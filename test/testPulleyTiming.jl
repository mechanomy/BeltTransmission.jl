


@testset "TimingPulley constructors" begin
  ctr = Geometry2D.Point(3mm,5mm)
  cir = Geometry2D.Circle( ctr, 5mm )

  tp = TimingPulley(cir, Geometry2D.uk, 2mm, 0u"rad", 1u"rad", "A")
  @test typeof(tp) <: AbstractPulley

  tp = TimingPulley(ctr, 10, Geometry2D.uk, 2mm, "B")
  @test typeof(tp) <: AbstractPulley

  tp = TimingPulley(pitch=cir, axis=Geometry2D.uk, beltPitch=2mm, arrive=0u"rad", depart=1u"rad", name="C")
  @test typeof(tp) <: AbstractPulley
  tp = TimingPulley(pitch=cir, axis=Geometry2D.uk, beltPitch=2mm, arrive=0u"rad", depart=1u"rad" )
  @test typeof(tp) <: AbstractPulley

  tp = TimingPulley(pitch=cir, axis=Geometry2D.uk, beltPitch=2mm, name="E")
  @test typeof(tp) <: AbstractPulley
  tp = TimingPulley(pitch=cir, axis=Geometry2D.uk, beltPitch=2mm)
  @test typeof(tp) <: AbstractPulley

  tp = TimingPulley(center=ctr, radius=cir.radius, axis=Geometry2D.uk, beltPitch=2mm, name="G")
  @test typeof(tp) <: AbstractPulley

  tp = TimingPulley(center=ctr, axis=Geometry2D.uk, nGrooves=10, beltPitch=2mm, name="H")
  @test typeof(tp) <: AbstractPulley

  @test pitchLength( tp ) ≈ 20mm
end

@testset "nGrooves2Radius" begin
  @test nGrooves2Radius(2mm, 10) == 20mm/2/pi
end

@testset "radius2NGrooves" begin
  @test radius2NGrooves(2mm, 10mm) == round(2*pi*10mm / 2mm)
end

@testset "nGrooves2Length" begin
  @test nGrooves2Length(2mm, 10) == 20mm
end

@testset "pulley2String" begin
  p = TimingPulley(pitch=Geometry2D.Circle(1mm, 2mm, 3mm), axis=Geometry2D.uk, beltPitch=2mm, arrive=1u"rad", depart=2u"rad", name="struct" ) 
  @test pulley2String(p) == "timing pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
end


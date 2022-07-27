

ctr = Geometry2D.Point(3u"mm",5u"mm")
uk = Geometry2D.uk
sp = SyncPulley( pitch=2mm, nGrooves=10, center=ctr, axis=uk )

@testset "SyncPulley constructor" begin
  @test sp.pitchLength == 20mm
end
@testset "nGrooves2Length" begin
  @test nGrooves2Length(2mm, 10) == 20mm
end
@testset "nGrooves2Radius" begin
  @test nGrooves2Radius(2mm, 10) == 20mm/2/pi
end
@testset "radius2NGrooves" begin
  @test radius2NGrooves(2mm, 10mm) == round(2*pi*10mm / 2mm)
end


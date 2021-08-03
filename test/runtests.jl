
using Test
using Unitful
using Geometry2D
include("../src/Pulley2D.jl")

# test rationale:
# - 
function testPulley()
  ctr = Geometry2D.Point(3u"mm",5u"mm")
  ref = Pulley2D.Pulley( Geometry2D.Point(3u"mm",5u"mm"), 3u"mm", Geometry2D.UnitVector([0,0,1]) )
  pul = Pulley2D.Pulley(center=ctr, radius=3u"mm", axis=Geometry2D.UnitVector([0,0,1]))
  # pulley = Pulley2D.Pulley( point, radius, axis, angle0, angle0 )
  # pulley = Pulley2D.Pulley( center=point, radius=radius, axis=axis )
  # pulley = Pulley2D.Pulley( )
  # pulley = Pulley2D.Pulley( xmm=3.3, ymm=4.4, radiusmm=5.5 )
  # pulley = Pulley2D.Pulley( x=3u"mm", y=4u"mm", radius=5u"mm" )
  # println(pulley) #does work
  return ref.radius == pul.radius

end

@testset "test Pulley2D" begin
  @test testPulley()
  # @test_throws MethodError Utility.iWrap(6.3,5)
end

include("../src/BeltSegment.jl")
# test rationale:
# - 

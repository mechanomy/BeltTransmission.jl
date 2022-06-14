# should use a Circle2D for the pitch circle, able to use circleArcLength/etc, but then references are pa.circle.center. otoh, shouldn't need to go that deep into structs.
export Pulley, calculateWrappedAngle, calculateWrappedLength

"""Geometric modeling of 2D pulleys"""
struct Pulley
    # center::Geometry2D.Point #[x,y] of the pulley center
    # radius::Unitful.Length
    pitch::Geometry2D.Circle #the pitch circle
    axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
    aArrive::Geometry2D.Radian #angle of the point of tangency 
    aDepart::Geometry2D.Radian
    name::String
end
Pulley(circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String)                            = Pulley(circle,axis,0u"rad",0u"rad",name) 
Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String)     = Pulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad",name) 
Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector)                   = Pulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad","") 
Pulley(center::Geometry2D.Point, radius::Unitful.Length, name::String)                                  = Pulley(Geometry2D.Circle(center,radius),Geometry2D.uk,0u"rad",0u"rad",name) 
Pulley(center::Geometry2D.Point, radius::Unitful.Length)                                                = Pulley(Geometry2D.Circle(center,radius),Geometry2D.uk,0u"rad",0u"rad","") 

@kwdispatch Pulley()
@kwmethod Pulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) = Pulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad",name)
@kwmethod Pulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = Pulley(circle,axis,0u"rad",0u"rad",name)

"""
`calculateWrappedAngle(p::Pulley) :: Geometry2D.Angle`
Given `p::Pulley`, calculate the wrapped angle from aArrive to aDepart.
Note that the wrapped angle is not restricted to <= 1 revolution, the pulley may be wrapped multiple times.
"""
function calculateWrappedAngle(p::Pulley) :: Geometry2D.Angle
  if Geometry2D.isapprox(p.axis, Geometry2D.uk, rtol=1e-3) #+z == cw
    if p.aDepart < p.aArrive #negative to positive zero crossing
      angle = (2u"rad"*pi - p.aArrive) + p.aDepart 
      # @printf("W] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
      return angle
    else
      angle = p.aDepart - p.aArrive
      # @printf("X] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
      return angle
    end
  elseif Geometry2D.isapprox(p.axis, -Geometry2D.uk, rtol=1e-3) #-z == cw
    if p.aDepart < p.aArrive
      angle = p.aArrive-p.aDepart
      # @printf("Y] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
      return angle
    else
      angle = 2u"rad"*pi - p.aDepart + p.aArrive
      # @printf("Z] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
      return angle 
    end       
  else
    error("calculateWrappedAngle: pulley axis is neither +- uk, is $(p.axis)")
  end
end

"""
`calculateWrappedLength(p::Pulley) :: Unitful.Length`
Given `p::Pulley`, calculate the length of the wrapped segment from aArrive to aDepart
Note that the wrapped length is not restricted to <= 1 revolution, the pulley may be wrapped multiple times.
"""
function calculateWrappedLength(p::Pulley) :: Unitful.Length
  return p.pitch.radius * calculateWrappedAngle(p)
end

"""
`pulley2Circle(p::Pulley)::Geometry2D.Circle`
"""
function pulley2Circle(p::Pulley) :: Geometry2D.Circle
    # return Geometry2D.Circle(p.center, p.radius)
    return p.pitch
end

"""
`pulley2String(p::Pulley)::String`
Returns a descriptive string of the given Pulley `p`
"""
function pulley2String(p::Pulley)::String 
  # return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] arrive[%3.3f] depart[%3.3f]", p.name, p.center.x, p.center.y, p.radius, p.aArrive, p.aDepart)
  # return @sprintf("pulley[%s] @ [%s,%s] r[%s] arrive[%s] depart[%s] aWrap[%s] lWrap[%s]", p.name, p.center.x, p.center.y, p.radius, p.aArrive, p.aDepart, calculateWrappedAngle(p), calculateWrappedLength(p))
  return @sprintf("pulley[%s] @ [%s,%s] r[%s] arrive[%s] depart[%s] aWrap[%s] lWrap[%s]", p.name, p.pitch.center.x, p.pitch.center.y, p.pitch.radius, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",calculateWrappedAngle(p)), calculateWrappedLength(p))
end

"""
`printPulley(p::Pulley)`
Prints the result of `pulley2String(p)` to the standard output
"""
function printPulley(p::Pulley)
  println(pulley2String(p))
end

"""
`plotPulley(p::Pulley; colorPulley="black", colorBelt="magenta", linewidthBelt=4, plotUnit=u"m")

"""
function plotPulley(p::Pulley; colorPulley="black", colorBelt="magenta", linewidthBelt=4, plotUnit=u"m")
  th = range(0,2*pi,length=100)

  px = ustrip(plotUnit, p.pitch.center.x) 
  py = ustrip(plotUnit, p.pitch.center.y) 
  pr = ustrip(plotUnit, p.pitch.radius)
  x = px .+ pr.*cos.(th)
  y = py .+ pr.*sin.(th)
  al= 0.5
  plot(x,y, color=colorPulley, alpha=al )
  text(px+pr*0.1,py+pr*0.1, p.name)
  if Geometry2D.isapprox(p.axis, Geometry2D.uk, rtol=1e-3) #+z == cw
    plot(px, py, "o", color=colorPulley, alpha=al ) #arrow tip coming out of the page = ccw normal rotation
    plot(px+pr, py, "^", color=colorPulley, alpha=al)
    
    if p.aDepart < p.aArrive
      an = range(p.aArrive-2u"rad"*pi, p.aDepart, length=100)
    else
      an = range(p.aArrive,p.aDepart,length=100)
    end
    ax = px .+ pr.*cos.(an)
    ay = py .+ pr.*sin.(an)
    plot(ax,ay, color=colorBelt, alpha=al, linewidth=linewidthBelt, label=p.name )
  elseif Geometry2D.isapprox(p.axis, -Geometry2D.uk, rtol=1e-3) #-z == cw
    plot(px, py, "x", color=colorPulley, alpha=al ) #arrow tip coming out of the page = ccw normal rotation
    plot(px+pr, py, "v", color=colorPulley, alpha=al)

    if p.aDepart < p.aArrive
      an = range(p.aArrive,p.aDepart,length=100)
    else
      an = range(p.aArrive, p.aDepart-2u"rad"*pi, length=100)
    end       
    ax = px .+ pr.*cos.(an)
    ay = py .+ pr.*sin.(an)
    plot(ax,ay, color=colorBelt, alpha=al, linewidth=linewidthBelt, label=p.name )
  else
    error("plotPulley given a non-z axis for pulley $(pulley2String(p))" )
  end

end

function testPulley()
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

  # @testset "plotPulley" begin
  #   defer until plot testing works well
  # end

end

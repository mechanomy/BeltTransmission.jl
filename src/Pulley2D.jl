export Pulley, calculateWrappedAngle, calculateWrappedLength

"""Geometric modeling of 2D pulleys"""
struct Pulley
    pitch::Geometry2D.Circle #the pitch circle
    axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
    aArrive::Geometry2D.Radian #angle of the point of tangency, aArrive comes first in the struct from the view of positive rotation..
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
@kwmethod Pulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, aArrive::Geometry2D.Radian, aDepart::Geometry2D.Radian, name::String) = Pulley(circle,axis,aArrive,aDepart,name)


"""
A plot recipe for plotting Pulleys under Plots.jl.
Keyword `n` can be used to increase the number of points constituting the pulley edge.
`lengthUnit` is a Unitful unit for scaling the linear axes. [atm UnitfulRecipes doesn't apply to nested @series]
`arrowFactor` controls the size of the arrow head at aDepart
```
p = Pulley( Geometry2D.Circle(1mm,2mm,3mm), Geometry2D.uk, "recipe" )
plot(p)
```
#this help will not display unless attached to a plotpulley function
"""
# @userplot PlotPulley #expands to plotpulley() ...this doesn't seem to work right now, postpone
@recipe function plotRecipe(p::Pulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
  col = get(plotattributes, :seriescolor, :auto)
  # @show lwd = get(plotattributes, :linewidth, :auto) #this returns ':auto', not the numeric

  @series begin # put a dot/x on the pulley center, indicating the direction of the axis
    seriestype := :path 
    primary := false
    linecolor := nothing
    markershape := (p.axis==Geometry2D.uk ? :circle : :x ) #if axis is positive uk, the axis rotation vector is 'coming out of the page' whereas negative is into the page and we see the vector arrow's fletching
    [ustrip(lengthUnit, p.pitch.center.x)], [ustrip(lengthUnit, p.pitch.center.y)] #the location data, [make into a 1-element vector]
  end

  @series begin #draw the arc segment between aArrive and aDepart
    seriestype := :path
    primary := false
    linecolor := segmentColor
    linewidth --> 3 #would like this to be 3x default...above lwd is ":auto" not a number when this runs...

    #fix zero crossings
    pad = p.aDepart
    if p.axis≈Geometry2D.uk && p.aDepart < p.aArrive #positive rotation, need to increase aDepart by 2pi
      pad += 2*π*u"rad"
    end
    paa = p.aArrive
    if p.axis ≈ -Geometry2D.uk && p.aArrive < p.aDepart
      paa += 2*π*u"rad"
    end
    
    th = LinRange( ustrip(u"rad", paa), ustrip(u"rad", pad), n )
    x = p.pitch.center.x .+ p.pitch.radius .* cos.(th) #with UnitfulRecipes, applies a unit label to the axes
    y = p.pitch.center.y .+ p.pitch.radius .* sin.(th)
    
    ax = p.pitch.center.x + p.pitch.radius*(1-arrowFactor) * cos(ustrip(u"rad", p.aDepart - arrowFactor*(p.aDepart-p.aArrive))) 
    ay = p.pitch.center.y + p.pitch.radius*(1-arrowFactor) * sin(ustrip(u"rad", p.aDepart - arrowFactor*(p.aDepart-p.aArrive))) 
    append!(x, ax)
    append!(y, ay)
    ustrip.(lengthUnit,x), ustrip.(lengthUnit,y) #return the data
  end

  aspect_ratio := :equal 
  seriestype := :shape 
  fillalpha := 0.5
  fillcolor := col #the pulley wheel color
  # fillstyle --> :/ #overrides the center dot
  label --> p.name

  th = LinRange(0,2*π, 100)
  x = p.pitch.center.x .+ p.pitch.radius .* cos.(th) #with UnitfulRecipes, applies a unit label to the axes
  y = p.pitch.center.y .+ p.pitch.radius .* sin.(th)
  # x,y #return the data
  ustrip.(lengthUnit,x), ustrip.(lengthUnit,y) #return the data
end

"""
`getDeparturePoint(p::Pulley)::Geometry2D.Point`
Returns the point of departure.
"""
function getDeparturePoint(p::Pulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.aDepart )
end

"""
`getArrivalPoint(p::Pulley)::Geometry2D.Point`
Returns the point of arrival.
"""
function getArrivalPoint(p::Pulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.aArrive )
end


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
  return Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p))
end

"""
`pulley2Circle(p::Pulley)::Geometry2D.Circle`
"""
function pulley2Circle(p::Pulley) :: Geometry2D.Circle
    return p.pitch
end

"""
`pulley2String(p::Pulley)::String`
Returns a descriptive string of the given Pulley `p`
"""
function pulley2String(p::Pulley)::String 
  return @sprintf("pulley[%s] @ [%s,%s] r[%s] arrive[%s] depart[%s] aWrap[%s] lWrap[%s]", p.name, p.pitch.center.x, p.pitch.center.y, p.pitch.radius, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",calculateWrappedAngle(p)), calculateWrappedLength(p))
end

"""
`printPulley(p::Pulley)`
Prints the result of `pulley2String(p)` to the standard output
"""
function printPulley(p::Pulley)
  println(pulley2String(p))
end

# """
# `plotPulley(p::Pulley; colorPulley="black", colorBelt="magenta", linewidthBelt=4, plotUnit=u"m")

# """
# function plotPulley(p::Pulley; colorPulley="black", colorBelt="magenta", linewidthBelt=4, plotUnit=u"m")
#   th = range(0,2*pi,length=100)

#   px = ustrip(plotUnit, p.pitch.center.x) 
#   py = ustrip(plotUnit, p.pitch.center.y) 
#   pr = ustrip(plotUnit, p.pitch.radius)
#   x = px .+ pr.*cos.(th)
#   y = py .+ pr.*sin.(th)
#   al= 0.5
#   plot(x,y, color=colorPulley, alpha=al )
#   text(px+pr*0.1,py+pr*0.1, p.name)
#   if Geometry2D.isapprox(p.axis, Geometry2D.uk, rtol=1e-3) #+z == cw
#     plot(px, py, "o", color=colorPulley, alpha=al ) #arrow tip coming out of the page = ccw normal rotation
#     plot(px+pr, py, "^", color=colorPulley, alpha=al)
    
#     if p.aDepart < p.aArrive
#       an = range(p.aArrive-2u"rad"*pi, p.aDepart, length=100)
#     else
#       an = range(p.aArrive,p.aDepart,length=100)
#     end
#     ax = px .+ pr.*cos.(an)
#     ay = py .+ pr.*sin.(an)
#     plot(ax,ay, color=colorBelt, alpha=al, linewidth=linewidthBelt, label=p.name )
#   elseif Geometry2D.isapprox(p.axis, -Geometry2D.uk, rtol=1e-3) #-z == cw
#     plot(px, py, "x", color=colorPulley, alpha=al ) #arrow tip coming out of the page = ccw normal rotation
#     plot(px+pr, py, "v", color=colorPulley, alpha=al)

#     if p.aDepart < p.aArrive
#       an = range(p.aArrive,p.aDepart,length=100)
#     else
#       an = range(p.aArrive, p.aDepart-2u"rad"*pi, length=100)
#     end       
#     ax = px .+ pr.*cos.(an)
#     ay = py .+ pr.*sin.(an)
#     plot(ax,ay, color=colorBelt, alpha=al, linewidth=linewidthBelt, label=p.name )
#   else
#     error("plotPulley given a non-z axis for pulley $(pulley2String(p))" )
#   end

# end

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

  @testset "plotPulley" begin
    pa = Pulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 4u"rad", "pulleyA") 
    pb = Pulley(Geometry2D.Circle(10mm,0mm, 4mm), -Geometry2D.uk, 1u"rad", 4u"rad", "pulleyB") 
    p = plot(pa, reuse=false)
    p = plot!(pb)
    display(p);

    @test true
  end


end;

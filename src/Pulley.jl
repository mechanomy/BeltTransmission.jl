export Pulley, getDeparturePoint, getArrivalPoint, calculateWrappedAngle, calculateWrappedLength, pulley2Circle, pulley2String, printPulley

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


function Base.show(io::IO, p::Pulley)
  print(io, pulley2String(p))
end


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

  @series begin # put a dot/x on the pulley center, indicating the direction of the axis
    seriestype := :path 
    primary := false
    linecolor := nothing
    markershape := (p.axis==Geometry2D.uk ? :circle : :x ) #if axis is positive uk, the axis rotation vector is 'coming out of the page' whereas negative is into the page and we see the vector arrow's fletching
    markercolor := :black
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
    
    #add an arrow at depart
    ax = p.pitch.center.x + p.pitch.radius*(1-arrowFactor) * cos(ustrip(u"rad", pad - arrowFactor*(pad-paa))) 
    ay = p.pitch.center.y + p.pitch.radius*(1-arrowFactor) * sin(ustrip(u"rad", pad - arrowFactor*(pad-paa))) 
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
  legend_background_color --> :transparent
  legend_position --> :outerright

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
      return uconvert(u"rad", angle) #lest Unitful drop the angle units
    else
      angle = p.aDepart - p.aArrive
      # @printf("X] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
      return uconvert(u"rad", angle)
    end
  elseif Geometry2D.isapprox(p.axis, -Geometry2D.uk, rtol=1e-3) #-z == cw
    if p.aDepart < p.aArrive
      angle = p.aArrive-p.aDepart
      # @printf("Y] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
      return uconvert(u"rad", angle)
    else
      angle = 2u"rad"*pi - p.aDepart + p.aArrive
      # @printf("Z] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.aArrive, p.aDepart, angle)
      return uconvert(u"rad", angle)
    end       
  else
    error("calculateWrappedAngle: pulley axis is neither +- uk, is $(p.axis)")
    return 0°
  end
end

"""
`calculateWrappedLength(p::Pulley) :: Unitful.Length`
Given `p::Pulley`, calculate the length of the wrapped segment from aArrive to aDepart
Note that the wrapped length is not restricted to <= 1 revolution, the pulley may be wrapped multiple times.
"""
function calculateWrappedLength(p::Pulley) :: Unitful.Length
  # cwa = calculateWrappedAngle(p)
  # cal = Geometry2D.circleArcLength(p.pitch, cwa)
  # return cal

  # return Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p)) 
  return uconvert(u"m", Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p)) ) #cancel m*rad
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
  un = unit(p.pitch.radius)
  return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°] aWrap[%3.3f°] lWrap[%3.3f]",
    p.name, 
    ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
    string(un),
    ustrip(u"°",p.aArrive), ustrip(u"°",p.aDepart),
    ustrip(u"°",calculateWrappedAngle(p)), ustrip(un,calculateWrappedLength(p)) )

  # #without computing wrapped angle or length:
  # return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°]", 
  #   p.name, 
  #   ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
  #   string(un),
  #   ustrip(u"°",p.aArrive), ustrip(u"°",p.aDepart) )
end

"""
`printPulley(p::Pulley)`
Prints the result of `pulley2String(p)` to the standard output
"""
function printPulley(p::Pulley)
  println(pulley2String(p))
end



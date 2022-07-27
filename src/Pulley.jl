export Pulley, getDeparturePoint, getArrivalPoint, calculateWrappedAngle, calculateWrappedLength, pulley2Circle, pulley2String, printPulley


"""
Models a pulley in a BeltTransmission with:
$FIELDS
"""
struct Pulley
  """the pitch Circle"""
  pitch::Geometry2D.Circle #the pitch circle
  """the rotation axis for the pulley with +/- defining the 'positive' rotation direction"""
  axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
  """angle of the radial vector of the belt's point of arrival"""
  aArrive::Geometry2D.Radian #angle of the point of tangency, aArrive comes first in the struct from the view of positive rotation..
  """angle of the radial vector of the belt's point of departure"""
  aDepart::Geometry2D.Radian
  """convenience name of the pulley"""
  name::String
end

"""
    Pulley(circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) :: Pulley
Models a Pulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
"""
Pulley(circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String)                            = Pulley(circle,axis,0u"rad",0u"rad",name) 

"""
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) :: Pulley
Models a Pulley in a BeltTransmission, having a `pitch` diameter, rotation `axis`, angles `aArrive` and `aDepart` when rotated postively according to the `axis`, and an optional `name`.
"""
Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String)     = Pulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad",name) 

"""
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector) :: Pulley
Models a Pulley in a BeltTransmission, having a `pitch` diameter, rotation `axis`, angles `aArrive` and `aDepart` when rotated postively according to the `axis`, and an optional `name`.
"""
Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector)                   = Pulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad","") 

"""
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, name::String) :: Pulley
Models a Pulley in a BeltTransmission, located at `center` with pitch `radius` and `name`.
"""
Pulley(center::Geometry2D.Point, radius::Unitful.Length, name::String)                                  = Pulley(Geometry2D.Circle(center,radius),Geometry2D.uk,0u"rad",0u"rad",name) 

"""
    Pulley(center::Geometry2D.Point, radius::Unitful.Length) :: Pulley
Models a Pulley in a BeltTransmission, located at `center` with pitch `radius`.
"""
Pulley(center::Geometry2D.Point, radius::Unitful.Length)                                                = Pulley(Geometry2D.Circle(center,radius),Geometry2D.uk,0u"rad",0u"rad","") 

@kwdispatch Pulley()

"""
    Pulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) :: Pulley
Models a Pulley in a BeltTransmission through keyword arguments.
"""
@kwmethod Pulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) = Pulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad",name)
"""
    Pulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) :: Pulley
Models a Pulley in a BeltTransmission through keyword arguments.
"""
@kwmethod Pulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = Pulley(circle,axis,0u"rad",0u"rad",name)
"""
    Pulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, aArrive::Geometry2D.Radian, aDepart::Geometry2D.Radian, name::String) :: Pulley
Models a Pulley in a BeltTransmission through keyword arguments.
"""
@kwmethod Pulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, aArrive::Geometry2D.Radian, aDepart::Geometry2D.Radian, name::String) = Pulley(circle,axis,aArrive,aDepart,name)

"""
    Base.show(io::IO, p::Pulley)
Function to `show()` a Pulley via [`pulley2String`](@ref).
"""
function Base.show(io::IO, p::Pulley)
  print(io, pulley2String(p))
end


"""
    plotRecipe(p::Pulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)

A plot recipe for plotting Pulleys under Plots.jl.
Keyword `n` can be used to increase the number of points constituting the pulley edge.
`lengthUnit` is a Unitful unit for scaling the linear axes.
`arrowFactor` controls the size of the arrow head at aDepart.
```
using Plots, Unitful, BeltTransmission, Geometry2D
p = Pulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
plot(p)
```
"""
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
    getDeparturePoint(p::Pulley)::Geometry2D.Point
Returns the point of departure.
"""
function getDeparturePoint(p::Pulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.aDepart )
end

"""
    getArrivalPoint(p::Pulley)::Geometry2D.Point
Returns the point of arrival.
"""
function getArrivalPoint(p::Pulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.aArrive )
end


"""
    calculateWrappedAngle(p::Pulley) :: Geometry2D.Angle
Given `p`, calculate the wrapped angle from `p.aArrive` to `p.aDepart`.
Note that the wrapped angle is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
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
    calculateWrappedLength(p::Pulley) :: Unitful.Length
Given `p`, calculate the arclength of the wrapped segment from `p.aArrive` to `p.aDepart`
Note that the wrapped length is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
"""
function calculateWrappedLength(p::Pulley) :: Unitful.Length
  # cwa = calculateWrappedAngle(p)
  # cal = Geometry2D.circleArcLength(p.pitch, cwa)
  # return cal

  # return Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p)) 
  return uconvert(u"m", Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p)) ) #cancel m*rad
end

"""
    pulley2Circle(p::Pulley) :: Geometry2D.Circle
Returns the pitch Circle of `p`.
"""
function pulley2Circle(p::Pulley) :: Geometry2D.Circle
    return p.pitch
end

"""
    pulley2String(p::Pulley) :: String
Returns a descriptive string of the given Pulley `p` of the form:
    pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
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
    printPulley(p::Pulley)
Prints the result of [`pulley2String`](@ref) to the standard output
"""
function printPulley(p::Pulley)
  println(pulley2String(p))
end



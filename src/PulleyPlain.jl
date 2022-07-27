export PlainPulley, pulley2String

"""
Models a cylindrical plain pulley in a BeltTransmission with:
$FIELDS
"""
struct PlainPulley <: AbstractPulley
  """the pitch Circle"""
  pitch::Geometry2D.Circle #the pitch circle
  """the rotation axis for the pulley with +/- defining the 'positive' rotation direction"""
  axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
  """angle of the radial vector of the belt's point of arrival"""
  arrive::Geometry2D.Radian #angle of the point of tangency, arrive comes first in the struct from the view of positive rotation..
  """angle of the radial vector of the belt's point of departure"""
  depart::Geometry2D.Radian
  """convenience name of the pulley"""
  name::String
end

"""
    PlainPulley(circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) :: PlainPulley
Models a PlainPulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
"""
PlainPulley(circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = PlainPulley(circle,axis,0u"rad",0u"rad",name) 

"""
    PlainPulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) :: PlainPulley
Models a PlainPulley in a BeltTransmission, having a `pitch` diameter, rotation `axis`, angles `arrive` and `depart` when rotated postively according to the `axis`, and an optional `name`.
"""
PlainPulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) = PlainPulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad",name) 

"""
    PlainPulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector) :: PlainPulley
Models a PlainPulley in a BeltTransmission, having a `pitch` diameter, rotation `axis`, angles `arrive` and `depart` when rotated postively according to the `axis`, and an optional `name`.
"""
PlainPulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector) = PlainPulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad","") 

"""
    PlainPulley(center::Geometry2D.Point, radius::Unitful.Length, name::String) :: PlainPulley
Models a PlainPulley in a BeltTransmission, located at `center` with pitch `radius` and `name`.
"""
PlainPulley(center::Geometry2D.Point, radius::Unitful.Length, name::String) = PlainPulley(Geometry2D.Circle(center,radius),Geometry2D.uk,0u"rad",0u"rad",name) 

"""
    PlainPulley(center::Geometry2D.Point, radius::Unitful.Length) :: PlainPulley
Models a PlainPulley in a BeltTransmission, located at `center` with pitch `radius`.
"""
PlainPulley(center::Geometry2D.Point, radius::Unitful.Length) = PlainPulley(Geometry2D.Circle(center,radius),Geometry2D.uk,0u"rad",0u"rad","") 

@kwdispatch PlainPulley()

"""
    PlainPulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) :: PlainPulley
Models a PlainPulley in a BeltTransmission through keyword arguments.
"""
@kwmethod PlainPulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) = PlainPulley(Geometry2D.Circle(center,radius),axis,0u"rad",0u"rad",name)

"""
    PlainPulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) :: PlainPulley
Models a PlainPulley in a BeltTransmission through keyword arguments.
"""
@kwmethod PlainPulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = PlainPulley(circle,axis,0u"rad",0u"rad",name)

"""
    PlainPulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) :: PlainPulley
Models a PlainPulley in a BeltTransmission through keyword arguments.
"""
@kwmethod PlainPulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) = PlainPulley(circle,axis,arrive,depart,name)

"""
    pulley2String(p::PlainPulley) :: String
Returns a descriptive string of the given PlainPulley `p` of the form:
    pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
"""
function pulley2String(p::PlainPulley)::String 
  un = unit(p.pitch.radius)
  return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°] aWrap[%3.3f°] lWrap[%3.3f]",
    p.name, 
    ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
    string(un),
    ustrip(u"°",p.arrive), ustrip(u"°",p.depart),
    ustrip(u"°",calculateWrappedAngle(p)), ustrip(un,calculateWrappedLength(p)) )

  # #without computing wrapped angle or length:
  # return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°]", 
  #   p.name, 
  #   ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
  #   string(un),
  #   ustrip(u"°",p.arrive), ustrip(u"°",p.depart) )
end



"""
    plotRecipe(p::PlainPulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)

A plot recipe for plotting Pulleys under Plots.jl.
Keyword `n` can be used to increase the number of points constituting the pulley edge.
`lengthUnit` is a Unitful unit for scaling the linear axes.
`arrowFactor` controls the size of the arrow head at depart.
```
using Plots, Unitful, BeltTransmission, Geometry2D
p = PlainPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
plot(p)
```
"""
@recipe function plotRecipe(p::PlainPulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
  col = get(plotattributes, :seriescolor, :auto)

  @series begin # put a dot/x on the pulley center, indicating the direction of the axis
    seriestype := :path 
    primary := false
    linecolor := nothing
    markershape := (p.axis==Geometry2D.uk ? :circle : :x ) #if axis is positive uk, the axis rotation vector is 'coming out of the page' whereas negative is into the page and we see the vector arrow's fletching
    markercolor := :black
    [ustrip(lengthUnit, p.pitch.center.x)], [ustrip(lengthUnit, p.pitch.center.y)] #the location data, [make into a 1-element vector]
  end

  @series begin #draw the arc segment between arrive and depart
    seriestype := :path
    primary := false
    linecolor := segmentColor
    linewidth --> 3 #would like this to be 3x default...above lwd is ":auto" not a number when this runs...

    #fix zero crossings
    pad = p.depart
    if p.axis≈Geometry2D.uk && p.depart < p.arrive #positive rotation, need to increase depart by 2pi
      pad += 2*π*u"rad"
    end
    paa = p.arrive
    if p.axis ≈ -Geometry2D.uk && p.arrive < p.depart
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


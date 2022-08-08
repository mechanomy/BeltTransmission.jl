



export SynchronousPulley, nGrooves2Radius, radius2NGrooves, nGrooves2Length


"""
Models a SynchronousPulley in a BeltTransmission, described by a `pitch` circle, rotation `axis`, and `toothPitch`.

$FIELDS
"""
struct SynchronousPulley <: AbstractPulley
  """Circle describing the pitch diameter."""
  pitch::Geometry2D.Circle
  """The rotation axis for the pulley with +/- defining the 'positive' rotation direction."""
  axis::Geometry2D.UnitVector 

  """Distance between belt teeth"""
  toothPitch::Unitful.Length #[mm/groove] -- would like a Synchrounous meta-class to provide these definitions, not sure if this is allowed

  """Angle of the radial vector of the belt's point of arrival."""
  arrive::Geometry2D.Radian

  """Angle of the radial vector of the belt's point of departure."""
  depart::Geometry2D.Radian

  """Convenience name of the pulley."""
  name::String
end
SynchronousPulley(pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, arrive=0u"rad", depart=0u"rad", name="") = SynchronousPulley(pitch,axis,toothPitch,arrive,depart,name)
SynchronousPulley(center::Geometry2D.Point, nGrooves::Integer, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, name::String) = SynchronousPulley(Geometry2D.Circle(center, nGrooves2Radius(toothPitch, nGrooves)),axis,toothPitch, 0u"rad", 0u"rad", name) 

"""
A copy constructor for setting the `arrive` and `depart` angles.
"""
SynchronousPulley(sp::SynchronousPulley; arrive=0u"rad", depart=0u"rad") = SynchronousPulley(sp.pitch,sp.axis,sp.toothPitch,arrive,depart,sp.name) #copy constructor


@kwdispatch SynchronousPulley() #kwdispatch can't have default arguments, so define first with everything, then narrow:

"""
    SynchronousPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) :: SynchronousPulley
Models a SynchronousPulley in a BeltTransmission, described by a `pitch` circle, rotation `axis` and `toothPitch`.
Optional angles `arrive` and `depart` specify belt's arrival and departure tangent points.
`name` identifies the pulley when plotting and printing.
"""
@kwmethod SynchronousPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) = SynchronousPulley(pitch,axis,toothPitch,arrive,depart,name) 
@kwmethod SynchronousPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian ) = SynchronousPulley(pitch,axis,toothPitch,arrive,depart,"") 
@kwmethod SynchronousPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, name::String) = SynchronousPulley(pitch,axis,toothPitch,0u"rad",0u"rad",name) 
@kwmethod SynchronousPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length) = SynchronousPulley(pitch,axis,toothPitch,0u"rad",0u"rad","") 

"""
    SynchronousPulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) 
Models a SynchronousPulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
"""
@kwmethod SynchronousPulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, name::String) = SynchronousPulley(Geometry2D.Circle(center, radius),axis,toothPitch, 0u"rad", 0u"rad", name) 

"""
    SynchronousPulley(; center::Geometry2D.Point, nGrooves::Integer, axis::Geometry2D.UnitVector, toothPitch::Unitful.Length, name::String)
Models a SynchronousPulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
`nGrooves` and `toothPitch` are used to find the pulley pitch diameter.
"""
@kwmethod SynchronousPulley(; center::Geometry2D.Point, axis::Geometry2D.UnitVector, nGrooves::Integer, toothPitch::Unitful.Length, name::String) = SynchronousPulley(Geometry2D.Circle(center, nGrooves2Radius(toothPitch, nGrooves)),axis,toothPitch, 0u"rad", 0u"rad", name) 


"""
    nGrooves2Radius(pitch::Unitful.Length, nGrooves::Integer)::Unitful.Length
Convert the `pitch` and `nGrooves` to the pitch radius.
"""
function nGrooves2Radius(pitch::Unitful.Length, nGrooves::Integer)::Unitful.Length
    return (nGrooves*pitch)/(2*pi)
end

"""
    radius2NGrooves(pitch::Unitful.Length, radius::Unitful.Length)::Integer
Convert the `pitch` and `radius` to the number of grooves.
"""
function radius2NGrooves(pitch::Unitful.Length, radius::Unitful.Length)::Integer
    return convert(Int32,round(2*pi*radius/pitch))
end

"""
    nGrooves2Length(pitch::Unitful.Length, nGrooves::Integer)::Unitful.Length
Convert the `pitch` and `nGrooves` to the circumferential length.
"""
function nGrooves2Length(pitch::Unitful.Length, nGrooves::Integer)::Unitful.Length
  return pitch * nGrooves
end


# """ coerce the given radius to the nearest radius having an integer number of grooves """
#function coerceRadius(pitch::Unitful.Length, radius::Unitful.Length) :: Unitful.Length
#  return nGrooves2Radius( pitch, radius2NGrooves(pitch, radius))
#end

"""
    pulley2String(p::SynchronousPulley) :: String
Returns a descriptive string of the given SynchronousPulley `p` of the form:
    timing pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
"""
function pulley2String(p::SynchronousPulley)::String 
  un = unit(p.pitch.radius)
  return @sprintf("timing pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°] aWrap[%3.3f°] lWrap[%3.3f]",
    p.name, 
    ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
    string(un),
    ustrip(u"°",p.arrive), ustrip(u"°",p.depart),
    ustrip(u"°",calculateWrappedAngle(p)), ustrip(un,calculateWrappedLength(p)) )
end

"""
    plotRecipe(p::SynchronousPulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)

A plot recipe for plotting Pulleys under Plots.jl.
Keyword `n` can be used to increase the number of points constituting the pulley edge.
`lengthUnit` is a Unitful unit for scaling the linear axes.
`arrowFactor` controls the size of the arrow head at depart.
```
using Plots, Unitful, BeltTransmission, Geometry2D
p = SynchronousPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
plot(p)
```
"""
@recipe function plotRecipe(p::SynchronousPulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
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








export TimingPulley, nGrooves2Radius, radius2NGrooves, nGrooves2Length

# mutable struct TimingPulley <: AbstractPulley
#     pitch::Unitful.Length #[mm/groove] -- would like a Synchrounous meta-class to provide these definitions, not sure if julia classes allow this..
#     nGrooves::Integer #[#grooves]
#     center::Geometry2D.Point #[x,y] of the pulley center
#     pitchRadius::Unitful.Length # radius to belt centerline
#     pitchLength::Unitful.Length # circumferential length
#     axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
#     arrive::Radian #angle of the point of tangency 
#     depart::Radian
# end

"""
Models a TimingPulley in a BeltTransmission, described by a `pitch` circle, rotation `axis` and `beltPitch`.
"""
struct TimingPulley <: AbstractPulley
  """Circle describing the pitch diameter."""
  pitch::Geometry2D.Circle
  """The rotation axis for the pulley with +/- defining the 'positive' rotation direction."""
  axis::Geometry2D.UnitVector 

  """Distance between belt teeth"""
  beltPitch::Unitful.Length #[mm/groove] -- would like a Synchrounous meta-class to provide these definitions, not sure if this is allowed

  """Angle of the radial vector of the belt's point of arrival."""
  arrive::Geometry2D.Radian

  """Angle of the radial vector of the belt's point of departure."""
  depart::Geometry2D.Radian

  """Convenience name of the pulley."""
  name::String
end
TimingPulley(pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, arrive=0u"rad", depart=0u"rad", name="") = TimingPulley(pitch,axis,beltPitch,arrive,depart,name)
TimingPulley(center::Geometry2D.Point, nGrooves::Integer, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, name::String) = TimingPulley(Geometry2D.Circle(center, nGrooves2Radius(beltPitch, nGrooves)),axis,beltPitch, 0u"rad", 0u"rad", name) 

@kwdispatch TimingPulley() #kwdispatch can't have default arguments, so define first with everything, then narrow:

"""
    TimingPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) :: TimingPulley
Models a TimingPulley in a BeltTransmission, described by a `pitch` circle, rotation `axis` and `beltPitch`.
Optional angles `arrive` and `depart` specify belt's arrival and departure tangent points.
`name` identifies the pulley when plotting and printing.
"""
@kwmethod TimingPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) = TimingPulley(pitch,axis,beltPitch,arrive,depart,name) 
@kwmethod TimingPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian ) = TimingPulley(pitch,axis,beltPitch,arrive,depart,"") 
@kwmethod TimingPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, name::String) = TimingPulley(pitch,axis,beltPitch,0u"rad",0u"rad",name) 
@kwmethod TimingPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length) = TimingPulley(pitch,axis,beltPitch,0u"rad",0u"rad","") 

"""
    TimingPulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) 
Models a TimingPulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
"""
@kwmethod TimingPulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, name::String) = TimingPulley(Geometry2D.Circle(center, radius),axis,beltPitch, 0u"rad", 0u"rad", name) 

"""
    TimingPulley(; center::Geometry2D.Point, nGrooves::Integer, axis::Geometry2D.UnitVector, beltPitch::Unitful.Length, name::String)
Models a TimingPulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
`nGrooves` and `beltPitch` are used to find the pulley pitch diameter.
"""
@kwmethod TimingPulley(; center::Geometry2D.Point, axis::Geometry2D.UnitVector, nGrooves::Integer, beltPitch::Unitful.Length, name::String) = TimingPulley(Geometry2D.Circle(center, nGrooves2Radius(beltPitch, nGrooves)),axis,beltPitch, 0u"rad", 0u"rad", name) 


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
    pulley2String(p::TimingPulley) :: String
Returns a descriptive string of the given TimingPulley `p` of the form:
    timing pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
"""
function pulley2String(p::TimingPulley)::String 
  un = unit(p.pitch.radius)
  return @sprintf("timing pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°] aWrap[%3.3f°] lWrap[%3.3f]",
    p.name, 
    ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
    string(un),
    ustrip(u"°",p.arrive), ustrip(u"°",p.depart),
    ustrip(u"°",calculateWrappedAngle(p)), ustrip(un,calculateWrappedLength(p)) )
end

"""
    plotRecipe(p::TimingPulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)

A plot recipe for plotting Pulleys under Plots.jl.
Keyword `n` can be used to increase the number of points constituting the pulley edge.
`lengthUnit` is a Unitful unit for scaling the linear axes.
`arrowFactor` controls the size of the arrow head at depart.
```
using Plots, Unitful, BeltTransmission, Geometry2D
p = TimingPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
plot(p)
```
"""
@recipe function plotRecipe(p::TimingPulley; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
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




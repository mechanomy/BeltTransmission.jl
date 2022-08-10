# All type recipes are placed here for better consistiency between them

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
    linecolor := :black
    markershape := (p.axis==Geometry2D.uk ? :circle : :x ) #if axis is positive uk, the axis rotation vector is 'coming out of the page' whereas negative is into the page and we see the vector arrow's fletching
    # markercolor := :black
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
    linecolor := :black
    markershape := (p.axis==Geometry2D.uk ? :circle : :x ) #if axis is positive uk, the axis rotation vector is 'coming out of the page' whereas negative is into the page and we see the vector arrow's fletching
    # markercolor := :black
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

"""
    plotRecipe(route::Vector{PlainPulley})
  Plots the Pulleys in a `route`.
  ```
  using Plots, Unitful, BeltTransmission, Geometry2D
  a = PlainPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  b = PlainPulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  route = calculateRouteAngles([a,b])
  plot(route)
  ```
"""
@recipe function plotRecipe(route::Vector{T}) where T<:AbstractPulley
  nr = length(route)

  #plot segments first, behind pulleys
  for ir in 1:nr
    @series begin
      FreeSegment( depart=route[ir], arrive=route[Utility.iNext(ir,nr)] )
    end
  end

  #plot pulleys
  for ir in 1:nr
    @series begin
      route[ir] #route[ir] is returned to _ to be plotted
    end
  end
end

"""
    plotRecipe(seg::FreeSegment; n=100, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
  Plot recipe to plot the free sections of a segment, does not plot the pulleys.
  ```
  using Plots, Unitful, BeltTransmission, Geometry2D
  a = PlainPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  b = PlainPulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  seg = FreeSegment(depart=a, arrive=b)
  plot(seg)
  ```
"""
@recipe function plotRecipe(seg::FreeSegment; n=2, lengthUnit=u"mm", segmentColor=:magenta, arrowFactor=0.03)
  pd = getDeparturePoint( seg )
  pa = getArrivalPoint( seg )
  x = LinRange( pd.x, pa.x, n )
  y = LinRange( pd.y, pa.y, n )

  seriestype := :path 
  linecolor --> segmentColor
  linewidth --> 3 #would like this to be 3x default...above lwd is ":auto" not a number when this runs...
  aspect_ratio := :equal 
  label --> toString(seg)
  legend_background_color --> :transparent
  legend_position --> :outerright

  ustrip.(lengthUnit,x), ustrip.(lengthUnit,y) #return the data
end

"""
    plotRecipe(segments::Vector{T}) where T<:AbstractSegment
  Plots the Pulleys and Segments in a `route`.
  ```
  using Plots, Unitful, BeltTransmission, Geometry2D
  a = PlainPulley( Geometry2D.Circle(1u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  b = PlainPulley( Geometry2D.Circle(10u"mm",2u"mm",3u"mm"), Geometry2D.uk, "recipe" )
  route = calculateRouteAngles([a,b])
  segments = route2Segments(route)
  plot(segments)
  ```
"""
@recipe function plotRecipe(segments::Vector{T}) where T<:AbstractSegment
  #plot segments first, behind pulleys
  for seg in segments
    @series begin
      seg
    end
  end

  nr = length(segments)
  #plot pulleys
  for ir in 1:nr
    @series begin
      segments[ir].depart #route[ir] is returned to _ to be plotted
    end
  end
  #for open belts, add the missed pulley
  if segments[1].arrive != last(segments).depart
    segments[1].arrive 
  end
end



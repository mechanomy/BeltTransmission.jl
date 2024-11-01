
module DEV
  using UnitTypes
  using Geometry2D
  using BeltTransmission
  # using CairoMakie # uses PhotoViewer!
  using GLMakie
  using Makie
  using Utility
  using Makie.Colors


  __precompile__(false)

function dev241022_gradientBelts() 
  # ideally want the belt to have one gradient across the entire belt
  # less good is to gradient each segment individually
  # alternately can draw an arrow somewhere..
  # create systems to permute
  ppa = PlainPulley(Geometry2D.Circle(MilliMeter(0),MilliMeter(0), MilliMeter(4)), Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyA") 
  ppb = PlainPulley(Geometry2D.Circle(MilliMeter(10),MilliMeter(10), MilliMeter(6)), -Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyB") 
  spa = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(20),MilliMeter(40)), axis=Geometry2D.uk, nGrooves=22, beltPitch=MilliMeter(2), arrive=Radian(1), depart=Radian(4), name="SyncPulleyA" )
  spb = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(0),MilliMeter(40)), axis=Geometry2D.uk, nGrooves=12, beltPitch=MilliMeter(2), arrive=Radian(1), depart=Radian(4), name="SyncPulleyB" )

  route = [ppa, ppb, spa, spb]
  solved = calculateRouteAngles(route)
  lOverall = calculateBeltLength(solved)

  seg12 = FreeSegment(depart=solved[1],arrive=solved[2])
  seg23 = FreeSegment(depart=solved[2],arrive=solved[3])
  seg34 = FreeSegment(depart=solved[3],arrive=solved[4])
  seg41 = FreeSegment(depart=solved[4],arrive=solved[1])
  
  fig = Figure(backgroundcolor="#bbb", size=(1000,1000))
  axs = Axis(fig[1,1], xlabel="X", ylabel="Y", aspect=DataAspect())

  # with 4 pulleys I have 4 segments, divide a colorbar into 8 and apply to each..
  # https://docs.makie.org/stable/explanations/colors#colors
  # When passing an array of numbers or a single number, the values are converted to colors using the colormap and colorrange attributes. By default, the colorrange spans the range of the color values, but it can be fixed manually as well. For example, this can be useful for picking categorical colors. The number 1 will pick the first and the number 2 the second color from the 10-color categorical map :tab10, for example, if the colorrange is set to (1, 10).
  
  # plotpulley!(axs, solved[1], colormap=:jet, linewidth=5, colorPulley="#335577ff", label="A")
  # plotpulley!(axs, solved[2], colormap=:jet, linewidth=5)
  # plotpulley!(axs, solved[3], colormap=:flag, linewidth=3)
  # plotpulley!(axs, solved[4], color=:yellow, linewidth=5)
  # plotfreesegment!(axs, seg12, colormap=:Dark2_3, linewidth=5, label="A-B")
  # plotfreesegment!(axs, seg23, color=:magenta, linewidth=5)
  # plotfreesegment!(axs, seg34, colormap=:Paired_10, linewidth=5)
  # plotfreesegment!(axs, seg41, color=:black, linewidth=5)
  # axislegend(axs, merge=true, unique=true, position=:rb, orientation=:vertical) # inside the figure

  # plotpulleysystem!(axs,solved, colorBeltFree=:red, colorBeltPulley=:green, colorPulley=:orange, widthBelt=4)
  plotpulleysystem!(axs,solved, colormapBelt=:jet, colorPulley=:orange, widthBelt=8)
  # axislegend(axs, merge=true, unique=true, position=:rb, orientation=:vertical) # inside the figure

  display(fig)
  # save("dev241022_gradientBelts.png", fig)
end
dev241022_gradientBelts()

end; # DEV


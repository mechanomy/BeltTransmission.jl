
module DEV
  using UnitTypes
  using Geometry2D
  using BeltTransmission
  # using CairoMakie # uses PhotoViewer!
  using GLMakie
  using Makie
  using Utility



function devPlot()
  # create systems to permute
  ppa = PlainPulley(Geometry2D.Circle(MilliMeter(0),MilliMeter(0), MilliMeter(4)), Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyA") 
  ppb = PlainPulley(Geometry2D.Circle(MilliMeter(10),MilliMeter(10), MilliMeter(6)), -Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyB") 
  spa = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(20),MilliMeter(40)), axis=Geometry2D.uk, nGrooves=22, beltPitch=MilliMeter(2), arrive=Radian(1), depart=Radian(4), name="SyncPulleyA" )
  spb = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(0),MilliMeter(40)), axis=Geometry2D.uk, nGrooves=12, beltPitch=MilliMeter(2), arrive=Radian(1), depart=Radian(4), name="SyncPulleyB" )

  route = [ppa, ppb, spa, spb]
  solved = calculateRouteAngles(route)
  
  fig = Figure(backgroundcolor="#bbb", size=(1000,1000))
  axs = Axis(fig[1,1], xlabel="X", ylabel="Y", aspect=DataAspect())
  plotpulleysystem!(axs,solved, colorBeltFree=:red, colorBeltPulley=:green, colorPulley=:orange, widthBelt=4)
  display(fig)
end

devPlot()

end # DEV


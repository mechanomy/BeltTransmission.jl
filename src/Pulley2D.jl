
"""Geometric modeling of 2D pulleys"""
module Pulley2D
    using Unitful, Unitful.DefaultSymbols
    using KeywordDispatch

    using PyPlot #can use matplotlib arguments directly
    using BPlot
    using Printf
    using StaticArrays #for defined-length arrays: SVector{3,T}
    using Utility
    using Geometry2D

    export Pulley, calculateWrappedAngle, calculateWrappedLength

    struct Pulley
        center::Geometry2D.Point #[x,y] of the pulley center
        radius::Unitful.Length
        axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
        aArrive::Geometry2D.Radian #angle of the point of tangency 
        aDepart::Geometry2D.Radian
        name::String
    end
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String)     = Pulley(center,radius,axis,0u"rad",0u"rad",name) 
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector)                   = Pulley(center,radius,axis,0u"rad",0u"rad","") 
    Pulley(center::Geometry2D.Point, radius::Unitful.Length, name::String)                                  = Pulley(center,radius,Geometry2D.uk,0u"rad",0u"rad",name) 
    Pulley(center::Geometry2D.Point, radius::Unitful.Length)                                                = Pulley(center,radius,Geometry2D.uk,0u"rad",0u"rad","") 
    @kwdispatch Pulley()
    @kwmethod Pulley(; center::Geometry2D.Point, radius::Unitful.Length, axis::Geometry2D.UnitVector, name::String) = Pulley(center,radius,axis,0u"rad",0u"rad",name)

    """
    Given `p::Pulley`, calculate the wrapped angle from aArrive to aDepart
    """
    function calculateWrappedAngle(p::Pulley) 
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
    function calculateWrappedLength(p::Pulley) #calculate the wrapped length from aArrive to aDepart at radius
      return p.radius * calculateWrappedAngle(p)
    end

    function pulley2Circle(p::Pulley)
        return Geometry2D.Circle(p.center, p.radius)
    end

    function pulley2String(p::Pulley)
      # return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] arrive[%3.3f] depart[%3.3f]", p.name, p.center.x, p.center.y, p.radius, p.aArrive, p.aDepart)
      # return @sprintf("pulley[%s] @ [%s,%s] r[%s] arrive[%s] depart[%s] aWrap[%s] lWrap[%s]", p.name, p.center.x, p.center.y, p.radius, p.aArrive, p.aDepart, calculateWrappedAngle(p), calculateWrappedLength(p))
      return @sprintf("pulley[%s] @ [%s,%s] r[%s] arrive[%s] depart[%s] aWrap[%s] lWrap[%s]", p.name, p.center.x, p.center.y, p.radius, uconvert(u"°",p.aArrive), uconvert(u"°",p.aDepart), uconvert(u"°",calculateWrappedAngle(p)), calculateWrappedLength(p))
    end
    function printPulley(p::Pulley)
      println(pulley2String(p))
    end

    function plotPulley(p::Pulley; colorPulley="black", colorBelt="magenta", linewidthBelt=4, plotUnit=u"m")
      th = range(0,2*pi,length=100)

      px = ustrip(plotUnit, p.center.x) 
      py = ustrip(plotUnit, p.center.y) 
      pr = ustrip(plotUnit, p.radius)
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
        error("BeltTransmission.Pulley2D given a non-z axis for pulley $(pulley2String(p))" )
      end

    end
end


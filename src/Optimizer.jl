
export Optimizer

"""
Provides functions for optimizing belt transmissions according to various metrics.
"""
module Optimizer
import Geometry2D
import ..BeltTransmission
using Unitful
using Optim

mutable struct PositionOptions # options for optimizing pulley positions
  belt::BeltTransmission.AbstractBelt
  routing::Vector{BeltTransmission.AbstractPulley}
  optimizeX::Vector{Bool}
  lowerX::Vector{Unitful.Length}
  upperX::Vector{Unitful.Length}
  optimizeY::Vector{Bool}
  lowerY::Vector{Unitful.Length}
  upperY::Vector{Unitful.Length}
end
PositionOptions(belt, routing) = PositionOptions(belt, routing, repeat([false],length(routing)),zeros(length(routing))*1.0u"mm",zeros(length(routing))*1.0u"mm",
                                                    repeat([false],length(routing)),zeros(length(routing))*1.0u"mm",zeros(length(routing))*1.0u"mm" )

function lookupPulley(routing::Vector{BeltTransmission.AbstractPulley}, p::BeltTransmission.AbstractPulley)
  for (ip,rp) in enumerate(routing)
    if rp == p
      return ip
    end
  end
  @warn "Given pulley [$p] is not in the given routing."
  return nothing
end


function setXRange!(opts::PositionOptions, p::BeltTransmission.AbstractPulley, low::Unitful.Length, high::Unitful.Length)
  ip = lookupPulley(opts.routing, p)
  opts.optimizeX[ip] = true
  opts.lowerX[ip] = low
  opts.upperX[ip] = high
end
function varyX!(opts::PositionOptions, p::BeltTransmission.AbstractPulley; low::Unitful.Length, start::Unitful.Length, high::Unitful.Length)
  ip = lookupPulley(opts.routing, p)
  opts.optimizeX[ip] = true
  opts.startX[ip] = start
  opts.lowerX[ip] = low
  opts.upperX[ip] = high
  # opts.start[iv] = start
  # opts.lower[iv] = low
  # opts.higher[ib] = high
end
function setYRange!(opts::PositionOptions, p::BeltTransmission.AbstractPulley, low::Unitful.Length, high::Unitful.Length)
  ip = lookupPulley(opts.routing, p)
  opts.optimizeY[ip] = true
  opts.lowerY[ip] = low
  opts.upperY[ip] = high
end

function xv2solved(opts::PositionOptions, xv::Vector)
  route = BeltTransmission.AbstractPulley[]
  iv = 1
  for (ip,rp) in enumerate(opts.routing) #create a new pulley with position from x
    ty = typeof(rp)
    if ty<:BeltTransmission.PlainPulley
      x  = opts.optimizeX[ip] ? xv[iv]*1.0u"mm" : rp.pitch.center.x 
      iv = opts.optimizeX[ip] ? iv+1   : iv #advance iv
      y  = opts.optimizeY[ip] ? xv[iv]*1.0u"mm" : rp.pitch.center.y
      iv = opts.optimizeY[ip] ? iv+1   : iv
      newp = BeltTransmission.PlainPulley(pitch=Geometry2D.Circle(x, y, rp.pitch.radius), axis=rp.axis, name=rp.name)
      push!(route, newp)
    elseif ty<:BeltTransmission.SynchronousPulley
      x  = opts.optimizeX[ip] ? xv[iv]*1.0u"mm" : rp.pitch.center.x 
      iv = opts.optimizeX[ip] ? iv+1   : iv #advance iv
      y  = opts.optimizeY[ip] ? xv[iv]*1.0u"mm" : rp.pitch.center.y
      iv = opts.optimizeY[ip] ? iv+1   : iv
      ng = BeltTransmission.radius2NGrooves(rp)
      newp = BeltTransmission.SynchronousPulley(center=Geometry2D.Point(x, y), nGrooves=ng, beltPitch=rp.beltPitch, axis=rp.axis, name=rp.name)
      push!(route, newp)
     end
  end
  return BeltTransmission.calculateRouteAngles(route)
end

function optimizeit(po::PositionOptions, x0::Vector)
  function objfun(x::Vector)
    # limits are manually enfoced because of https://github.com/JuliaNLSolvers/Optim.jl/issues/912#issuecomment-1218484194
    limitFactor=100 #if too large and the search will fail

    try 
      solved = xv2solved(po, x)
      l = BeltTransmission.calculateBeltLength(solved)
      ret = ustrip(u"mm", po.belt.length-l)^2

      #manually enforce limits by inflating feval
      iv = 1
      for ip in 1:length(po.routing) 
        if po.optimizeX[ip] 
          if x[iv] < ustrip(u"mm",po.lowerX[ip]) || ustrip(u"mm",po.upperX[ip]) < x[iv]
            ret *= limitFactor
          end
          iv += 1
        end
        if po.optimizeY[ip] 
          if x[iv] < ustrip(u"mm",po.lowerY[ip]) || ustrip(u"mm",po.upperY[ip]) < x[iv]
            ret *= limitFactor
          end
          iv += 1
        end
      end
      return ret
    catch err
      if isa(err, DomainError) && err.msg == "acos(x) not defined for |x| > 1"
        return Inf
      else
        rethrow(err)
      end
    end
  end


  opts = Optim.Options(x_tol=1e-3, f_tol=1e-3, iterations=1000, time_limit=60, allow_f_increases=false, store_trace=false, show_trace=false) 
  # opts = Optim.Options(x_tol=1e-3, f_tol=1e-3, iterations=1000, time_limit=60, allow_f_increases=false, store_trace=true, show_trace=true) 

  res = optimize(objfun, x0, NelderMead(), opts ) 
  # res = optimize(objfun, x0, LBFGS(), opts )  # 4 its, no limits
  #bounds are broken since https://github.com/JuliaNLSolvers/Optim.jl/issues/912
  # lower = ustrip.(u"mm", vcat(po.lowerX[1:2], po.lowerY[3:4]) )
  # upper = ustrip.(u"mm", vcat(po.upperX[1:2], po.upperY[3:4]) )
  # res = optimize(objfun, lower, upper, x0, NelderMead(), opts ) 
  # res = optimize(objfun, lower,upper, x0, LBFGS(), opts )  # fails w/o gradient, does not accept lower/upper
  # res = optimize(objfun, lower, upper, x0, SimulatedAnnealing(), opts ) # breaks limits
  # @show res

  x = Optim.minimizer(res)
  return x
end

end #Optimizer
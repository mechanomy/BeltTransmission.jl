



export SyncPulley, nGrooves2Radius, radius2NGrooves, nGrooves2Length

mutable struct SyncPulley <: AbstractPulley
    pitch::Unitful.Length #[mm/groove] -- would like a Synchrounous meta-class to provide these definitions, not sure if julia classes allow this..
    nGrooves::Integer #[#grooves]
    center::Geometry2D.Point #[x,y] of the pulley center
    pitchRadius::Unitful.Length # radius to belt centerline
    pitchLength::Unitful.Length # circumferential length
    axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
    arrive::Radian #angle of the point of tangency 
    aDepart::Radian
end
# 220526: KeywordDispatch can't have default arguments: https://github.com/simonbyrne/KeywordDispatch.jl/issues/1
@kwdispatch SyncPulley()

"""computes the `pitchRadius` from `pitch` and `nGrooves`"""
@kwmethod SyncPulley(; pitch::Unitful.Length, nGrooves::Integer, center::Geometry2D.Point, axis::Geometry2D.UnitVector) = SyncPulley(pitch, nGrooves, center, nGrooves2Radius(pitch,nGrooves), nGrooves2Length(pitch,nGrooves), axis, 0u"rad", 0u"rad") 

function nGrooves2Radius(pitch::Unitful.Length, nGrooves::Integer)::Unitful.Length
    return (nGrooves*pitch)/(2*pi)
end
function radius2NGrooves(pitch::Unitful.Length, radius::Unitful.Length)::Integer
    return convert(Int32,round(2*pi*radius/pitch))
end

# """ coerce the given radius to the nearest radius having an integer number of grooves """
#function coerceRadius(pitch::Unitful.Length, radius::Unitful.Length) :: Unitful.Length
#  return nGrooves2Radius( pitch, radius2NGrooves(pitch, radius))
#end

function nGrooves2Length(pitch::Unitful.Length, nGrooves::Integer)::Unitful.Length
  return pitch * nGrooves
end




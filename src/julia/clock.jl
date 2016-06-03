import Base: +,-

typealias clockid_t Int32
@enum(CLOCK_ID,
  CLOCK_REALTIME = 0,
  CLOCK_MONOTONIC = 1
)

const BILLION = 1000000000

if Base.Sys.WORD_SIZE==32
  typealias time_t Clong
elseif Base.Sys.WORD_SIZE==64
  typealias time_t Clonglong
else
  error("Unsupported architecture")
end

immutable timespec
  sec::time_t
  nsec::Clong
end

@inline function normalize(t::timespec)
  nsec=t.nsec; sec=t.sec
  if nsec >= BILLION
    (ss,nsec)=divrem(nsec,BILLION)
    sec += ss
  end
  return timespec(sec,nsec)
end

function +(t1::timespec,t2::timespec)
  if t1.sec < 0 || t1.nsec < 0 || t2.sec < 0 || t2.nsec < 0
    error("Adding timespec is only defined for positive time values")
  end
  tm=timespec(t1.sec+t2.sec,t1.nsec+t2.nsec)
  return normalize(tm)
end

function -(t1::timespec,t2::timespec)
  if t1.sec < 0 || t1.nsec < 0 || t2.sec < 0 || t2.nsec < 0
    error("Subtracting timespec is only defined for positive time values")
  end
  # find the larger time value
  if t1.sec-t2.sec > 0
    tend = t1; tbegin = t2; dsign=+1
  elseif t1.sec-t2.sec < 0
    tend = t2; tbegin = t1; dsign=-1
  else # t1.sec == t2.sec
    if t1.nsec > t2.nsec
      tend = t1; tbegin = t2; dsign=+1
    elseif t1.nsec < t2.nsec
      tend = t2; tbegin = t1; dsign=-1
    else # a tie!
      tend = t1; tbegin = t2; dsign=+1
    end
  end
  dnsec = tend.nsec - tbegin.nsec; dsec = tend.sec - tbegin.sec
  dnsec < 0 && (dnsec+=BILLION; dsec-=1)
  d::Int64 = dsign*(dnsec+BILLION*dsec)
end

type __timespec
  sec::time_t
  nsec::Clong
end

module TIMER_FLAG
  const RELTIME = Val{0}
  const ABSTIME = Val{1}
end

const tx = __timespec(0,0) # hack, to avoid unnecessary memory allocation
function gettime(clockid::CLOCK_ID)
  s = ccall((:clock_gettime,librt),Int32,(clockid_t,Ptr{__timespec}),
    clockid,pointer_from_objref(tx))
  s!=0 && error("Error in gettime()")
  return timespec(tx.sec,tx.nsec)
end
function nanosleep(clockid::CLOCK_ID, t::timespec, ::Type{TIMER_FLAG.ABSTIME})
  tx.sec=t.sec;tx.nsec=t.nsec
  f = pointer_from_objref(tx) # hack, to avoid unnecessary memory allocation
  s = ccall((:clock_nanosleep,librt),Int32,(clockid_t,Int32,Ptr{__timespec},Ptr{__timespec}),
    clockid,1,f,f)
  s!=0 && error("Error in nanosleep()")
  return nothing
end
nanosleep(clockid::CLOCK_ID, t::timespec) = nanosleep(clockid, t, TIMER_FLAG.ABSTIME)

function nanosleep(clockid::CLOCK_ID, t::timespec, ::Type{TIMER_FLAG.RELTIME})
  error("Relative time nanosleep not supported yet!")
  return nothing
end

@inline function nanosleep(t::timespec,nanosec::Clong)
  tm = normalize(timespec(t.sec,t.nsec+nanosec))
  nanosleep(CLOCK_MONOTONIC,tm)
  return tm
end

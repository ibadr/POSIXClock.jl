typealias clockid_t Int32
@enum(CLOCK_ID,
  CLOCK_REALTIME = 0,
  CLOCK_MONOTONIC = 1
)

type timespec
  sec::Clonglong
  nsec::Clong
end

function gettime(clockid::CLOCK_ID)
  res = timespec(0,0)
  s = ccall((:clock_gettime,librt),Int32,(clockid_t,Ref{timespec}),
    clockid,Ref(res))
  return res
end

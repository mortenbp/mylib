functor MonadP (MP : MonadPBase) : MonadP =
struct
structure M = Monad (MP)
structure A = Alt (open M MP)
open M A MP
end
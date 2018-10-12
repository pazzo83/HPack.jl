module HPack

using Compat

import HttpCommon: Headers

struct DecodeError <: Exception
    message::String
end

# package code goes here
include("table.jl")
include("huffman.jl")
include("encode.jl")
include("decode.jl")

export encode
export decode
export DecodeError

end # module

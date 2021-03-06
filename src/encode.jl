function encode_string_literal(buf::IOBuffer, data::Base.CodeUnits{UInt8}; huffman=true)
    mask::UInt8 = 0x0
    if huffman
        mask = 0x80
        data = huffman_encode_bytes(data)
    end

    h = mask | UInt8(length(data))
    write(buf, h)
    write(buf, data)
end

function encode_literal(buf::IOBuffer, header::HeaderBinary; options...)
    mask::UInt8 = 0x0
    write(buf, mask)

    encode_string_literal(buf, header[1]; options...)
    encode_string_literal(buf, header[2]; options...)
end

function encode_indexed(buf::IOBuffer, index::UInt8, header::HeaderBinary; options...)
    mask::UInt8 = 0x40
    write(buf, mask | index)

    encode_string_literal(buf, header[2]; options...)
end

function encode_totally_indexed(buf::IOBuffer, index::UInt8; options...)
    mask::UInt8 = 0x80
    write(buf, mask | index)
end

function find_totally_indexed(name::Base.CodeUnits{UInt8}, value::Base.CodeUnits{UInt8})::Union{UInt8, Nothing}
    for i = 1:length(STATIC_TABLE)
        if STATIC_TABLE[i][1] == name && STATIC_TABLE[i][2] == value
            return UInt8(i)
        end
    end
    return nothing
end

function encode(table::DynamicTable, headers::Headers; options...)
    buf = IOBuffer()
    for header in sort(collect(headers))
        index = find_totally_indexed(codeunits(header[1]),
                                     codeunits(header[2]))
        if index == nothing
            encode_literal(buf, (codeunits(header[1]),
                                 codeunits(header[2])); options...)
        else
            encode_totally_indexed(buf, index; options...)
        end
    end

    return take!(buf)
end

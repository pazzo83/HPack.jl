const HeaderBinary = Tuple{Base.CodeUnits{UInt8, String}, Union{Base.CodeUnits{UInt8, String}}}
const Header = Tuple{String, String}

mutable struct DynamicTable
    table::Array{HeaderBinary, 1}
    size::Int
    max_size::Int
end

function new_dynamic_table()
    DynamicTable(Array{HeaderBinary, 1}(), 0, 4096)
end

function consolidate_table!(table::DynamicTable)
    while table.size > table.max_size
        last_header = pop!(table.table)
        table.size -= length(last_header[1]) + length(last_header[2]) + 32
    end
end

function add_header!(table::DynamicTable, header::HeaderBinary)
    name = header[1]
    value = header[2]
    table.size += length(name) + length(value) + 32
    pushfirst!(table.table, (name, value))
    consolidate_table!(table)
end

function add_header!(table::DynamicTable, header::Header)
    add_header!(table, (codeunits(header[1]),
                        codeunits(header[2])))
end

function set_max_table_size!(table::DynamicTable, size::Int)
    table.max_size = size
    consolidate_table!(table)
end

function get_header(table::DynamicTable, index)
    # IETF's table indexing is 1-based.
    if index <= length(STATIC_TABLE)
        return STATIC_TABLE[index]
    else
        if index > length(STATIC_TABLE) + table.max_size
            throw(DecodeError("Index greater than sum of both static and dynamic tables."))
        else
            if index > length(STATIC_TABLE) + length(table.table)
                throw(DecodeError("Index out of bound."))
            else
                return table.table[index - length(STATIC_TABLE)]
            end
        end
    end
end

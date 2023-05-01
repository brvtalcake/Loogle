PARSERS_JL_INCLUDED = true

using PDFIO
using Base.Threads

@static if !@isdefined(INDEX_JL_INCLUDED)
    include("index.jl")
end

function getEntireFile(file_path::String)
    ret_buff::String = ""
    try
        ret_buff = read(file_path, String)
    catch e
        err_str = string(e, " was caught while reading ", file_path)
        @warn err_str
        return ""
    end
    return ret_buff
end

function getPDFObjs(raw_content::String)::Vector{String}
    # Parse manually
    
end

function parsePDF(file_path::String)
    raw_content = getEntireFile(file_path)
    # Parse manually
    
end

function parsePDF_slow(file_path::String)
    io_buff = IOBuffer()
    ret_buff::String = ""
    local doc::PDDoc
    doc_defined = false
    try
        doc = PDFIO.pdDocOpen(file_path)
        npage = PDFIO.pdDocGetPageCount(doc)
        @polly for i=1:npage
            page = PDFIO.pdDocGetPage(doc, i)
            PDFIO.pdPageExtractText(io_buff, page)
            ret_buff *= String(take!(io_buff))
        end
    catch e
        err_str = string(e, " was caught while parsing ", file_path)
        @warn err_str
        return "", false
    finally
        if doc_defined
            PDFIO.pdDocClose(doc)
        end
    end
    return ret_buff, true
end

function parseFile(file::Dict{FileFields, Any})::Tuple{Dict{FileFields, Any}, String, Bool}
    if file[f_path] == "" || file[f_type] == FILE_TYPE_NOT_SUPPORTED
        return file, "", false
    elseif file[f_type] == PDF
        res = parsePDF(file[f_path])
        return file, res[1], res[2]
    elseif file[f_type] == RTF
        res = parseRTF(file[f_path])
        return file, res[1], res[2]
    elseif file[f_type] == HTML
        res = parseHTML(file[f_path])
        return file, res[1], res[2]
    elseif file[f_type] == XML
        res = parseXML(file[f_path])
        return file, res[1], res[2]
    elseif file[f_type] == TXT
        res = parseTXT(file[f_path])
        return file, res[1], res[2]
    elseif file[f_type] == EXCEL
        res = parseEXCEL(file[f_path])
        return file, res[1], res[2]
    elseif file[f_type] == DOC
        res = parseDOC(file[f_path])
        return file, res[1], res[2]
    else
        return file, "", false
    end
    return file, "", false
end

function parseFilesInIndex(index::Index)::Vector{Tuple{Dict{FileFields, Any}, String}}
    parsed_files::Vector{Tuple{Dict{FileFields, Any}, String}} = []
    channels = Channel{Tuple{Dict{FileFields, Any}, String}, Bool}(length(index.files))
    files_per_task = (length(index.files) - (length(index.files) % Threads.nthreads())) / Threads.nthreads()
    for i=1:Threads.nthreads()
        if i == Threads.nthreads()
            files = index.files[(i-1)*files_per_task+1:end]
        else
            files = index.files[(i-1)*files_per_task+1:i*files_per_task]
        end
        @spawn begin
            for file in files
                put!(channels, parseFile(file))
            end
        end
    end
    for _=1:length(index.files)
        res = take!(chnl)
        if res[3]
            push!(parsed_files, (res[1], res[2]))
        else
            @warn "Error while parsing file ", res[1][f_path]
        end
    end
    return parsed_files
end

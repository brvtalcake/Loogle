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

function processFile(file::Dict{FileFields, Any}, chnl)::Tuple{Dict{FileFields, Any}, String, Bool}
    if file[f_path] == "" || file[f_type] == FILE_TYPE_NOT_SUPPORTED
        put!(chnl, (file, "", false))
        return file, "", false
    elseif file[f_type] == PDF
        res = parsePDF(file[f_path])
        put!(chnl, (file, res[1], res[2]))
        return file, res[1], res[2]
    elseif file[f_type] == RTF
        res = parseRTF(file[f_path])
        put!(chnl, (file, res[1], res[2]))
        return file, res[1], res[2]
    elseif file[f_type] == HTML
        res = parseHTML(file[f_path])
        put!(chnl, (file, res[1], res[2]))
        return file, res[1], res[2]
    elseif file[f_type] == XML
        res = parseXML(file[f_path])
        put!(chnl, (file, res[1], res[2]))
        return file, res[1], res[2]
    elseif file[f_type] == TXT
        res = parseTXT(file[f_path])
        put!(chnl, (file, res[1], res[2]))
        return file, res[1], res[2]
    elseif file[f_type] == EXCEL
        res = parseEXCEL(file[f_path])
        put!(chnl, (file, res[1], res[2]))
        return file, res[1], res[2]
    elseif file[f_type] == DOC
        res = parseDOC(file[f_path])
        put!(chnl, (file, res[1], res[2]))
        return file, res[1], res[2]
    else
        put!(chnl, (file, "", false))
        return file, "", false
    end
    put!(chnl, (file, "", false))
    return file, "", false
end

# All ParsingUnit in a ParserPool has the same number of files to parse than the others
#= mutable struct ParsingUnit
    to_parse::Vector{Tuple{Dict{FileFields, Any}, String, Bool}} # file, text, parsed
    task_func::Vector{Tuple{Function, Task, Any, Bool}} # func, task, args, done
    errors::Vector{String}
    done::Bool
    ParsingUnit() = error("You must specify at least one file to parse")
    ParsingUnit(files::Vector{Dict{FileFields, Any}}) = new(zip(files, ["" for i=1:length(files)], [false for i=1:length(files)]),
                                                            zip([processFile for i=1:length(files)],
                                                                [Task(() -> func(arg)) for (func, arg) in zip([processFile for i=1:length(files)], files)],
                                                                files,
                                                                [false for i=1:length(files)]),
                                                            Vector{String}(),
                                                            false)
    
    ParsingUnit(file::Dict{FileFields, Any}) = new([(file, "", false)], [(processFile, Task(() -> processFile(file)), file, false)], Vector{String}(), false)

    ParsingUnit(file::Dict{FileFields, Any}, func::Function) = new([(file, "", false)], [(func, Task(() -> func(file)), file, false)], Vector{String}(), false)

    ParsingUnit(files::Vector{Dict{FileFields, Any}}, func::Function) = new(zip(files, ["" for i=1:length(files)], [false for i=1:length(files)]),
                                                                            zip([func for i=1:length(files)],
                                                                                [Task(() -> func_(arg)) for (func_, arg) in zip([func for i=1:length(files)], files)],
                                                                                files,
                                                                                [false for i=1:length(files)]),
                                                                            Vector{String}(),
                                                                            false)

    function addFile(file::Dict{FileFields, Any})
        push!(to_parse, (file, "", false))
        push!(task_func, (processFile, Task(() -> processFile(file)), file, false))
    end

    function addFile(file::Dict{FileFields, Any}, func::Function)
        push!(to_parse, (file, "", false))
        push!(task_func, (func, Task(() -> func(file)), file, false))
    end

    function addFiles(files::Vector{Dict{FileFields, Any}})
        for file in files
            push!(to_parse, (file, "", false))
            push!(task_func, (processFile, Task(() -> processFile(file)), file, false))
        end
    end

    function addFiles(files::Vector{Dict{FileFields, Any}}, func::Function)
        for file in files
            push!(to_parse, (file, "", false))
            push!(task_func, (func, Task(() -> func(file)), file, false))
        end
    end

    function parse()
        for (func, task, args, done) in task_func
            if !done
                schedule(task)
            end
        end
        for (file, text, parsed) in to_parse
            file[f_parsed] = true
        end
        for (func, task, args, done) in task_func
            if !done
                task_func[task_func .== (func, task, args, done)][4] = true
            end
        end
        done = true
    end

end

mutable struct ParserPool
    
end =#

function processFilesInIndex(index::Index)::Vector{Typle{Dict{FileFields, Any}, String}}
    parsed_files::Vector{Tuple{Dict{FileFields, Any}, String}} = []
    chnl = Channel{Tuple{Dict{FileFields, Any}, String}, Bool}(Inf)
    files_per_task = (length(index.files) - (length(index.files) % Threads.nthreads())) / Threads.nthreads()
    for i=1:Threads.nthreads()
        if i == Threads.nthreads()
            files = index.files[(i-1)*files_per_task+1:end]
        else
            files = index.files[(i-1)*files_per_task+1:i*files_per_task]
        end
        #= Threads.@spawn for file in files
            res = processFile(file, chnl)
            push!(parsed_files, (res[1], res[2]))
        end =#
        Threads.@spawn (function (files_to_be_parsed, parsed_files, chnl)
            for file in files_to_be_parsed
                processFile(file, chnl)
            end
        end)(files, parsed_files, chnl)
    end
    for _=1:length(index.files)
        res = take!(chnl)
        if res[3]
            push!(parsed_files, (res[1], res[2]))
        else
            @warn "Error while parsing file ", res[1][f_path]
        end
    end

end
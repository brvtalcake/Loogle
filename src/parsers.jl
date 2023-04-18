import PDFIO
include("index.jl")

function parsePDF(file_path::String)
    doc = PDFIO.pdDocOpen(file_path)
    try
        open(file_path, "r") do f
            text = ""
            npage = PDFIO.pdDocGetPageCount(doc)
            for i=1:npage
                page = PDFIO.pdDocGetPage(doc, i)
                text *= PDFIO.pdPageExtractText(f, page)
            end
            return text
        end
        #= doc = PDFIO.pdDocOpen(file_path)
        npage = PDFIO.pdDocGetPageCount(doc)
        text = ""
        for i=1:npage
            page = PDFIO.pdDocGetPage(doc, i)
            text *= PDFIO.pdPageExtractText(page)
        end
        PDFIO.pdDocClose(doc)
        return text
    catch e
        println("Error parsing file: $file_path")
        println(e)
        return ""
    end =#
end

function parseFile(file::Dict{FileFields, Any})
    if file[f_path] == "" || file[f_type] == FILE_TYPE_NOT_SUPPORTED
        return ""
    elseif file[f_type] == PDF
        return parsePDF(file[f_path])
    elseif file[f_type] == RTF
        return parseRTF(file[f_path])
    elseif file[f_type] == HTML
        return parseHTML(file[f_path])
    elseif file[f_type] == XML
        return parseXML(file[f_path])
    elseif file[f_type] == TXT
        return parseTXT(file[f_path])
    elseif file[f_type] == EXCEL
        return parseEXCEL(file[f_path])
    elseif file[f_type] == DOC
        return parseDOC(file[f_path])
    else
        return ""
    end
    return ""
end

mutable struct ParsingTask
    to_parse::Array{Tuple{Dict{FileFields, Any}, String, Bool}} # file, text, parsed
    const task_func::Task
    errors::Vector{String}
    done::Bool
    ParsingTask() = error("ParsingTask constructor must have at least one file to parse")
    ParsingTask(file_arr::Array{Dict{FileFields, Any}}) = new{Tuple{Dict{FileFields, Any}, String, Bool}}(Tuple{Dict{FileFields, Any}, String, Bool}[], Task(() -> parseFile(file_arr)), String[], false) # TODO: modify this and modify parseFile
end
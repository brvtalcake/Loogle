import Base: show, print, println
import JSON
import MIMEs

@enum FileKind FILE_TYPE_NOT_SUPPORTED=1 PDF=2 RTF=4 HTML=8 XML=16 TXT=32 EXCEL=64 DOC=128
@enum FileFields f_path=1 f_size=2 f_type=4 f_timestamp=8

mutable struct Index
    root::String
    files::Array{Dict{FileFields, Any}, 1}
    dirs::Array{String, 1}
    links::Array{String, 1}
    path_size::Int64
end

macro fPath(file)
    return :(file[f_path])
end

macro fSize(file)
    return :(file[f_size])
end

macro fType(file)
    return :(file[f_type])
end

macro fTimeStamp(file)
    return :(file[f_timestamp])
end

show(index::Index) = begin println("Index :\n\tRoot: $(index.root)\n")
                        println("\tDirs:")
                        for dir in index.dirs
                            println("\t$(dir)")
                        end
                        println("\tLinks:")
                        for link in index.links
                            println("\t$(link)")
                        end
                        if index.path_size < 1000
                            println("\tPath size: $(index.path_size) B")
                        elseif index.path_size < 1000000
                            println("\tPath size: $(Float64(index.path_size) / 1000) KB")
                        elseif index.path_size < 1000000000
                            println("\tPath size: $(Float64(index.path_size) / 1000000) MB")
                        else
                            println("\tPath size: $(Float64(index.path_size) / 1000000000) GB")
                        end
                        println("\tFiles:")
                        for file in index.files
                            println("\t$(file[f_path])")
                            println("\t\tSize: $(file[f_size])")
                            println("\t\tType: $(file[f_type])")
                            println("\t\tLast modified: $(file[f_timestamp])")
                        end
                        nothing
                    end

print(index::Index) = show(index)
println(index::Index) = show(index)

function isFileInIndex(file, index)
    for f in index.files
        if f[f_path] == file
            return true
        end
    end
    return false
end

function addFile(index, file, file_kind)
    if !isFileInIndex(file, index)
        push!(index.files, File(file, file_kind, filesize(file), (mtime(file) > ctime(file) ? mtime(file) : ctime(file))))
    end
end

function addDir(index, dir)
    if !in(dir, index.dirs)
        push!(index.dirs, dir)
    end
end

function addLink(index, link)
    if !in(link, index.links)
        push!(index.links, link)
    end
end

function walkAndIndex(index, root_dir)
    for (root, dirs, files) in walkdir(root_dir)
        for file in files
            if isdir(joinpath(root, file))
                addDir(index, joinpath(root, file))
            elseif islink(joinpath(root, file))
                addLink(index, joinpath(root, file))
            elseif isfile(joinpath(root, file))
                addFile(index, joinpath(root, file), FILE_TYPE_NOT_SUPPORTED)
            end
        end
        for dir in dirs
            addDir(index, joinpath(root, dir))
            walkAndIndex(index, joinpath(root, dir))
        end
    end
    return index
end

function checkSymlinks(index)
    for link in index.links
        if !isFileInIndex(readlink(link), index) && !in(readlink(link), index.dirs) && !in(readlink(link), index.links)
            if isdir(link)
                addDir(index, link)
                walkAndIndex(index, link)
            elseif isfile(link)
                addFile(index, link, FILE_TYPE_NOT_SUPPORTED)
            elseif islink(link)
                addLink(index, link)
                checkSymlinks(index)
            end
        end
    end
    return index
end

function calcPathSize(index)
    index.path_size = 0
    for file in index.files
        index.path_size += file[f_size]
    end
    return index.path_size
end

function isPdf(file)
    splited_path = splitext(file)
    return splited_path[2] == ".pdf"
end

function isRtf(file)
    splited_path = splitext(file)
    return splited_path[2] == ".rtf"
end

function isHTML(file)
    splited_path = splitext(file)
    return splited_path[2] == ".html"
end

function isXML(file)
    splited_path = splitext(file)
    return splited_path[2] == ".xml"
end

function isPlainTxt(file)
    splited_path = splitext(file)
    return splited_path[2] == ".txt"
end

function isExcel(file)
    splited_path = splitext(file)
    return splited_path[2] == ".xls" || splited_path[2] == ".xlsx" || splited_path[2] == ".xlsm" || splited_path[2] == ".xlsb" || splited_path[2] == ".xl"
end

function isDoc(file)
    splited_path = splitext(file)
    return splited_path[2] == ".doc" || splited_path[2] == ".docx" || splited_path[2] == ".docm"
end

function matchFileType(file)
    if isPdf(file)
        if isRtf(file) || isHTML(file) || isXML(file) || isPlainTxt(file) || isExcel(file) || isDoc(file)
            return FILE_TYPE_NOT_SUPPORTED
        else
            return PDF
        end
    elseif isRtf(file)
        if isHTML(file) || isXML(file) || isPlainTxt(file) || isExcel(file) || isDoc(file) || isPdf(file)
            return FILE_TYPE_NOT_SUPPORTED
        else
            return RTF
        end
    elseif isHTML(file)
        if isXML(file) || isPlainTxt(file) || isExcel(file) || isDoc(file) || isPdf(file) || isRtf(file)
            return FILE_TYPE_NOT_SUPPORTED
        else
            return HTML
        end
    elseif isXML(file)
        if isPlainTxt(file) || isExcel(file) || isDoc(file) || isPdf(file) || isRtf(file) || isHTML(file)
            return FILE_TYPE_NOT_SUPPORTED
        else
            return XML
        end
    elseif isPlainTxt(file)
        if isExcel(file) || isDoc(file) || isPdf(file) || isRtf(file) || isHTML(file) || isXML(file)
            return FILE_TYPE_NOT_SUPPORTED
        else
            return TXT
        end
    elseif isExcel(file)
        if isDoc(file) || isPdf(file) || isRtf(file) || isHTML(file) || isXML(file) || isPlainTxt(file)
            return FILE_TYPE_NOT_SUPPORTED
        else
            return EXCEL
        end
    elseif isDoc(file)
        if isPdf(file) || isRtf(file) || isHTML(file) || isXML(file) || isPlainTxt(file) || isExcel(file)
            return FILE_TYPE_NOT_SUPPORTED
        else
            return DOC
        end
    else
        return FILE_TYPE_NOT_SUPPORTED
    end
end

function isFileSupported(file)::Tuple{Bool, FileKind}
    bool_ret = isPdf(file) || isRtf(file) || isHTML(file) || isXML(file) || isPlainTxt(file) || isExcel(file) || isDoc(file)
    return (bool_ret ? (true, matchFileType(file)) : (false, FILE_TYPE_NOT_SUPPORTED))
end

function filterIndex(index)
    i = 1
    while i <= length(index.files)
        supported, _ = isFileSupported(index.files[i][f_path])
        if !supported
            deleteat!(index.files, i)
        else
            i += 1
        end
    end
    calcPathSize(index)
    return index
end

function indexDir(index)
    if !isdir(index.root)
        error("Not a directory")
    end
    index.root = abspath(index.root)
    walkAndIndex(index, index.root)
    checkSymlinks(index)
    calcPathSize(index)
    filterIndex(index)
    return index
end

function Index(r)
    return Index(r, Array{Dict{FileFields, Any}, 1}(), Array{String, 1}(), Array{String, 1}(), 0)
end

function Index()
    return error("No root directory specified")
end

function File()
    return error("No path specified")
end

function File(path::String, type::FileKind, size::Int64, timestamp::Float64)
    return Dict{FileFields, Any}(f_path => path, f_type => type, f_size => size, f_timestamp => timestamp)
end

function File(path::String, type::FileKind, size::Int64)
    return Dict{FileFields, Any}(f_path => path, f_type => type, f_size => size, f_timestamp => (stat(path).mtime > stat(path).ctime ? stat(path).mtime : stat(path).ctime))
end

function File(path::String, type::FileKind)
    return Dict{FileFields, Any}(f_path => path, f_type => type, f_size => filesize(path), f_timestamp => (stat(path).mtime > stat(path).ctime ? stat(path).mtime : stat(path).ctime))
end

function File(path::String)
    return :(Dict{FileFields, Any}(f_path => $(path), f_type => matchFileType($(path)), f_size => filesize($(path)), f_timestamp => (stat($(path)).mtime > stat($(path)).ctime ? stat($(path)).mtime : stat($(path)).ctime)))
end

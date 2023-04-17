import Base: show, print, println
import JSON
import MIMEs

mutable struct Index
    root::String
    files::Array{String, 1}
    dirs::Array{String, 1}
    links::Array{String, 1}
    path_size::Int64
end

show(index::Index) = begin println("Index :\n\tRoot: $(index.root)\n")
                        println("\tFiles:")
                        for file in index.files
                            println("\t  $(file)")
                        end
                        println("\tDirs:")
                        for dir in index.dirs
                            println("\t  $(dir)")
                        end
                        println("\tLinks:")
                        for link in index.links
                            println("\t  $(link)")
                        end
                        println("\tPath size: $(index.path_size)")
                        nothing
                    end

print(index::Index) = show(index)
println(index::Index) = show(index)

function addFile(index, file)
    if !in(file, index.files)
        push!(index.files, file)
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
                addFile(index, joinpath(root, file))
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
        if !in(readlink(link), index.files) && !in(readlink(link), index.dirs) && !in(readlink(link), index.links)
            if isdir(link)
                addDir(index, link)
                walkAndIndex(index, link)
            elseif isfile(link)
                addFile(index, link)
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
        index.path_size += filesize(file)
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

function isFileSupported(file)
    return isPdf(file) || isRtf(file) || isHTML(file) || isXML(file) || isPlainTxt(file)
end

function filterIndex(index)
    i = 1
    while i <= length(index.files)
        if !isFileSupported(index.files[i])
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
    return indexDir(Index(r, [], [], [], 0))
end

function Index()
    return error("No root directory specified")
end
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

function indexDir(index)
    if !isdir(index.root)
        error("Not a directory")
    end
    index.root = abspath(index.root)
    walkAndIndex(index, index.root)
    checkSymlinks(index)
    calcPathSize(index)
    return index
end

function Index(r)
    return indexDir(Index(r, [], [], [], 0))
end

function Index()
    return error("No root directory specified")
end

function isPdf(file)
    splited_path = splitext(file)
    if length(splited_path) == 2
    return isfile(file) && splited_path[2] == ".pdf"
    else
        return false
    end
end

function isRtf(file)
    splited_path = splitext(file)
    if length(splited_path) == 2
    return isfile(file) && splited_path[2] == ".rtf"
    else
        return false
    end
end

function isHTML(file)
    splited_path = splitext(file)
    if length(splited_path) == 2
    return isfile(file) && splited_path[2] == ".html"
    else
        return false
    end
end

function isXML(file)
    splited_path = splitext(file)
    if length(splited_path) == 2
    return isfile(file) && splited_path[2] == ".xml"
    else
        return false
    end
end

function isPlainTxt(file)
    splited_path = splitext(file)
    if length(splited_path) == 2
    return isfile(file) && splited_path[2] == ".txt"
    else
        return false
    end
end

function isFileSupported(file)
    return isPdf(file) || isRtf(file) || isHTML(file) || isXML(file) || isPlainTxt(file)
end

function filterIndex(index)
    for file in index.files
        if !isFileSupported(file)
            deleteat!(index.files, findfirst(x->x==file, index.files))
        end
    end
    calcPathSize(index)
end

index = Index(ARGS[1])

print(index)

filterIndex(index)

print(index)


#= people = [Dict("name"=>"CoolGuy", "company"=>"tech") for i=1:1000]
companies = [Dict("name"=>"CoolTech", "address"=>"Bay Area") for i=1:100]

data = Dict("people"=>people, "companies"=>companies)
json_string = JSON.json(data)

open("foo.json","w") do f
  JSON.print(f, json_string)
end =#
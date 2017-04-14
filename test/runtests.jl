using SPIRV
using Base.Test

# we use CUDAnative to handle all the GPU codegen modification to Julias codegen
using CUDAnative, LLVM

function kernel_vadd(a, b, c)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
    c[i] = a[i] + b[i]
    return nothing
end

const CUArray = CUDAnative.CuDeviceArray{Float32, 1}

ir = sprint() do io
    CUDAnative.code_llvm(io, kernel_vadd, Tuple{CUArray, CUArray, CUArray}; dump_module = true, cap = v"2.0")
end
mod = parse(LLVM.Module, ir)

spirv_dir = joinpath(homedir(), "gpustuff", "SPIRV-LLVM", "build", "bin")
llvm_spirv = joinpath(spirv_dir, "llvm-spirv")
llvm_dis = joinpath(spirv_dir, "llvm-dis")
@assert isfile(llvm_spirv)

open(`$llvm_dis -`, "w") do f
    buff = convert(Vector{UInt8}, mod)
    write(f, buff)
end
